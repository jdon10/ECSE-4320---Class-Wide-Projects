#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>
#include <linux/perf_event.h>

#ifndef BUILD_NAME
#define BUILD_NAME "unknown"
#endif

#define KERNEL __attribute__((noipa))
template<class T> KERNEL T saxpy(T* __restrict x, T* __restrict y,
                                    T*, size_t n, size_t stride) {
    const T a = T(0.25);
    if (stride == 1) {
        for (size_t i = 0; i < n; ++i) y[i] = a*x[i] + y[i];
    } else {
        for (size_t i = 0; i < n; ++i) y[i*stride] = a*x[i*stride] + y[i*stride];
    }
    return T(0);
}

template<class T> KERNEL T dot(T* __restrict x, T* __restrict y,
                               T*, size_t n, size_t stride) {
    T sum = 0;
    if (stride == 1) {
        for (size_t i = 0; i < n; ++i) sum += x[i]*y[i];
    } else {
        for (size_t i = 0; i < n; ++i) sum += x[i*stride]*y[i*stride];
    }
    return sum;
}

template<class T> KERNEL T mul(T* __restrict x, T* __restrict y,
                                  T* __restrict z, size_t n, size_t stride) {
    if (stride == 1) {
        for (size_t i = 0; i < n; ++i) z[i] = x[i]*y[i];
    } else {
        for (size_t i = 0; i < n; ++i) z[i*stride] = x[i*stride]*y[i*stride];
    }
    return T(0);
}

template<class T> __attribute__((noipa,optimize("no-tree-vectorize","no-associative-math","fp-contract=off")))
long double reference(const std::string& kernel, const T* x, T* y, T* z,
                      size_t n, size_t stride, long double& norm) {
    long double sum = 0; norm = 0;
    for (size_t i = 0; i < n; ++i) {
        size_t j = i*stride;
        if (kernel == "saxpy") y[j] = T(T(0.25)*x[j] + y[j]);
        else if (kernel == "mul") z[j] = T(x[j]*y[j]);
        else { long double p = static_cast<long double>(x[j])*y[j]; sum += p; norm += std::abs(p); }
    }
    return sum;
}

struct Options {
    std::string kernel = "saxpy", type = "f32", study = "manual";
    size_t n = 1024, offset = 0, stride = 1, reps = 7, warmup = 3, batch = 4194304;
    bool check = false, header = false, cycles = false;
};

size_t number(const std::string& s) {
    if (s.empty() || s[0] == '-') throw std::runtime_error("expected an unsigned integer");
    size_t used = 0; auto v = std::stoull(s, &used);
    if (used != s.size() || v > std::numeric_limits<size_t>::max()) throw std::runtime_error("invalid integer");
    return size_t(v);
}

struct Counter {
    int fd = -1;
    explicit Counter(bool requested) {
        if (requested) {
            perf_event_attr a{}; a.type = PERF_TYPE_HARDWARE; a.size = sizeof(a);
            a.config = PERF_COUNT_HW_CPU_CYCLES; a.disabled = 1; a.exclude_kernel = 1; a.exclude_hv = 1;
            a.pinned = 1;
            a.read_format = PERF_FORMAT_TOTAL_TIME_ENABLED | PERF_FORMAT_TOTAL_TIME_RUNNING;
            fd = int(syscall(SYS_perf_event_open, &a, 0, -1, -1, 0));
        }
        if (requested && fd < 0) std::cerr << "warning: hardware cycles unavailable; CSV cycles fields will be blank\n";
    }
    void start() {
        if (fd >= 0) { ioctl(fd, PERF_EVENT_IOC_RESET, 0); ioctl(fd, PERF_EVENT_IOC_ENABLE, 0); }
    }
    double stop() {
        if (fd >= 0) {
            ioctl(fd, PERF_EVENT_IOC_DISABLE, 0);
            struct { uint64_t value, enabled, running; } v{};
            if (read(fd, &v, sizeof(v)) == sizeof(v) && v.running > 0 && v.running == v.enabled)
                return double(v.value); // Reject multiplexed counts, rather than scaling them.
        }
        return -1;
    }
    ~Counter() {
        if (fd >= 0) close(fd);
    }
};

volatile long double sink = 0;
template<class T> int run(const Options& o) {
    const size_t arrays = o.kernel == "mul" ? 3 : 2;
    const size_t limit = std::numeric_limits<size_t>::max();
    if (o.n > (limit/(arrays*sizeof(T)) - 32)/o.stride) throw std::runtime_error("size overflow");
    const size_t span = (o.n - 1)*o.stride + 1, off = o.offset/sizeof(T);
    const size_t count = span + off + 16;
    std::vector<T*> base(arrays);
    struct Cleanup { std::vector<T*>& p; ~Cleanup() { for (auto a:p) free(a); } } cleanup{base};
    for (auto& p:base) {
        void* raw = nullptr;
        if (posix_memalign(&raw,64,count*sizeof(T))) throw std::runtime_error("allocation failed; reduce working set");
        p = static_cast<T*>(raw);
        std::fill(p,p+count,T(-7));
    }
    T* x=base[0]+off; T* y=base[1]+off; T* z=arrays==3 ? base[2]+off : nullptr;
    auto init = [&]() {
        for (size_t i=0;i<o.n;++i) {
            x[i*o.stride]=T(int(i%251)-125)/T(128);
            y[i*o.stride]=T(int(i%127)-63)/T(64);
            if (z) z[i*o.stride]=T(-7);
        }
    };
    T (*kernel)(T*,T*,T*,size_t,size_t) = o.kernel=="dot" ? dot<T> :
                                             (o.kernel=="saxpy" ? saxpy<T> : mul<T>);
    auto execute = [&]() { return kernel(x,y,z,o.n,o.stride); };
    init();
    {
        std::vector<T> ry(y,y+span), rz(z ? span : 0,T(-7));
        long double norm=0;
        long double expected=reference(o.kernel,x,ry.data(),rz.data(),o.n,o.stride,norm);
        T result=execute();
        const long double eps=std::numeric_limits<T>::epsilon();
        auto close = [&](long double a,long double b,long double scale) {
            return std::isfinite(a) && std::abs(a-b)<=128*eps*std::max(1.0L,scale);
        };
        if (o.kernel=="dot" && !close(result,expected,norm)) throw std::runtime_error("dot reference mismatch");
        for (size_t i=0;i<span;++i) {
            T expected_x = i%o.stride==0 ? T(int((i/o.stride)%251)-125)/T(128) : T(-7);
            if (x[i]!=expected_x || !close(y[i],ry[i],std::abs(ry[i])) ||
                (z && !close(z[i],rz[i],std::abs(rz[i])))) throw std::runtime_error("array reference/gap mismatch");
        }
        for (auto p:base) {
            for (size_t j=0;j<off;++j) if(p[j]!=T(-7)) throw std::runtime_error("prefix overwritten");
            for (size_t j=off+span;j<count;++j) if(p[j]!=T(-7)) throw std::runtime_error("suffix overwritten");
        }
    }
    if(o.check) return 0;
    const size_t iters=std::max(size_t(1),o.batch/o.n + (o.batch%o.n!=0));
    Counter counter(o.cycles);
    std::cout << std::setprecision(17);
    for(size_t rep=0;rep<o.reps;++rep) {
        init();
        for(size_t w=0;w<o.warmup;++w) sink=execute();
        T result=0;
        counter.start();
        auto start=std::chrono::steady_clock::now();
        for(size_t j=0;j<iters;++j) {
            asm volatile("" ::: "memory");
            result=execute();
        }
        auto end=std::chrono::steady_clock::now();
        double cycles=counter.stop();
        sink=o.kernel=="dot" ? result : (z ? z[(o.n-1)*o.stride] : y[(o.n-1)*o.stride]);
        double seconds=std::chrono::duration<double>(end-start).count();
        if(seconds<=0) throw std::runtime_error("timer resolution exceeded; increase --batch-elements");
        const size_t traffic=(o.kernel=="dot" ? 2 : 3)*sizeof(T);
        const size_t flops=o.kernel=="mul" ? 1 : 2;
        std::cout << o.study << ',' << BUILD_NAME << ',' << o.kernel << ',' << o.type << ','
                  << o.n << ',' << o.offset << ',' << o.stride << ',' << arrays*span*sizeof(T) << ','
                  << arrays*o.n*sizeof(T) << ',' << rep << ',' << o.warmup << ',' << iters << ','
                  << seconds << ',' << flops << ',' << traffic << ',';
        if(cycles>=0) std::cout << cycles;
        std::cout << ',' << static_cast<long double>(sink) << '\n';
    }
    return 0;
}

int main(int argc,char** argv) {
    try {
        Options o;
        for(int i=1;i<argc;++i) {
            std::string k=argv[i];
            if(k=="--check-only") {o.check=true;continue;}
            if(k=="--header") {o.header=true;continue;}
            if(k=="--cycles") {o.cycles=true;continue;}
            if(k=="--help") {
                std::cout << "--kernel saxpy|dot|mul --type f32|f64 --n N --offset BYTES --stride 1|2|4|8\n"
                             "--reps 7 --warmup 3 --batch-elements 4194304 --study LABEL --cycles --check-only --header\n"
                             "Build is selected by executable: build/scalar, build/auto, build/native.\n";
                return 0;
            }
            if(i+1==argc) throw std::runtime_error("missing value for "+k);
            std::string v=argv[++i];
            if(k=="--kernel") o.kernel=v;
            else if(k=="--type") o.type=v;
            else if(k=="--study") o.study=v;
            else if(k=="--n") o.n=number(v);
            else if(k=="--offset") o.offset=number(v);
            else if(k=="--stride") o.stride=number(v);
            else if(k=="--reps") o.reps=number(v);
            else if(k=="--warmup") o.warmup=number(v);
            else if(k=="--batch-elements") o.batch=number(v);
            else throw std::runtime_error("unknown option: "+k);
        }
        if(o.header) {
            std::cout << "study,build,kernel,dtype,n,offset_bytes,stride,footprint_bytes,active_bytes,\
            rep,warmup,iterations,seconds,flops_per_element,logical_bytes_per_element,cycles,checksum\n";
            return 0;
        }
        if(o.kernel!="saxpy" && o.kernel!="dot" && o.kernel!="mul") throw std::runtime_error("unknown kernel");
        if(o.type!="f32" && o.type!="f64") throw std::runtime_error("unknown type");
        if(!o.n || !o.reps || !o.batch || (o.stride!=1 && o.stride!=2 && o.stride!=4 && o.stride!=8))
            throw std::runtime_error("N, reps, batch must be positive; stride must be 1,2,4,8");
        if(o.offset>=64 || o.offset%(o.type=="f32" ? 4 : 8)) throw std::runtime_error("offset must be <64 and a multiple of element size");
        if(o.study.empty() || o.study.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")!=std::string::npos)
            throw std::runtime_error("study label must contain only letters, digits, _ or -");
        return o.type=="f32" ? run<float>(o) : run<double>(o);
    } catch(const std::exception& e) {std::cerr << "error: " << e.what() << '\n'; return 1;}
}
