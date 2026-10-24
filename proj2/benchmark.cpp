#include <algorithm>
#include <array>
#include <cerrno>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <numeric>
#include <random>
#include <stdexcept>
#include <string>
#include <vector>
#include <linux/perf_event.h>
#include <sched.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <time.h>
#include <unistd.h>

using U64 = uint64_t;
volatile U64 sink = 0;
constexpr double missing = std::numeric_limits<double>::quiet_NaN();
const char* header = "experiment,pattern,size_bytes,stride_bytes,granularity_bytes,read_percent,intensity,\
page_mode,rep,seed,cpu,runtime_ns,operations,read_operations,write_operations,logical_bytes,dependent_latency_ns,\
service_ns,chain_turnaround_ns,throughput_mops,bandwidth_gbs,cycles_per_op,cycles,instructions,\
cache_references,cache_misses,dtlb_loads,dtlb_load_misses,counter_status,huge_bytes_before,\
huge_bytes_after,page_status,status,checksum";

U64 now_ns() {
    timespec t{};
    if (clock_gettime(CLOCK_MONOTONIC_RAW, &t)) throw std::runtime_error("clock_gettime failed");
    return U64(t.tv_sec) * 1000000000ULL + t.tv_nsec;
}
void require(bool ok, const std::string& msg) { if (!ok) throw std::runtime_error(msg); }

struct Counter {
    int fd = -1;
    double value = missing;
    std::string status = "disabled";
};

const std::array<std::string, 6> event_names = {
    "cycles", "instructions", "cache_references", "cache_misses", "dtlb_loads", "dtlb_load_misses"};

    std::array<Counter, 6> counters;
void open_counters(bool enabled) {
    if (!enabled) return;
    for (size_t i = 0; i < counters.size(); ++i) {
        perf_event_attr a{};
        a.size = sizeof(a); a.disabled = 1; a.exclude_kernel = 1; a.exclude_hv = 1;
        a.read_format = PERF_FORMAT_TOTAL_TIME_ENABLED | PERF_FORMAT_TOTAL_TIME_RUNNING;
        a.type = i < 4 ? PERF_TYPE_HARDWARE : PERF_TYPE_HW_CACHE;
        const U64 configs[] = {PERF_COUNT_HW_CPU_CYCLES, PERF_COUNT_HW_INSTRUCTIONS,
                            PERF_COUNT_HW_CACHE_REFERENCES, PERF_COUNT_HW_CACHE_MISSES};
        a.config = i < 4 ? configs[i] : U64(PERF_COUNT_HW_CACHE_DTLB) |
            (U64(PERF_COUNT_HW_CACHE_OP_READ) << 8) |
            (U64(i == 4 ? PERF_COUNT_HW_CACHE_RESULT_ACCESS : PERF_COUNT_HW_CACHE_RESULT_MISS) << 16);
        auto& c = counters[i];
        c.fd = syscall(SYS_perf_event_open, &a, 0, -1, -1, 0);
        c.status = c.fd >= 0 ? "ready" : "open_errno_" + std::to_string(errno);
    }
}

void start_counters() {
    for (auto& c : counters) {
        c.value = missing;
        if (c.fd >= 0) {
            if (ioctl(c.fd, PERF_EVENT_IOC_RESET, 0) || ioctl(c.fd, PERF_EVENT_IOC_ENABLE, 0))
                c.status = "enable_failed";
            else c.status = "enabled";
        }
    }
}

void stop_counters() {
    for (auto& c : counters) if (c.fd >= 0) {
        bool stopped = ioctl(c.fd, PERF_EVENT_IOC_DISABLE, 0) == 0;
        struct { U64 count, enabled, running; } v{};
        if (!stopped || c.status != "enabled" || read(c.fd, &v, sizeof(v)) != sizeof(v))
            c.status = "read_failed";
        else if (!v.enabled || v.running < 0.99 * v.enabled) c.status = "multiplexed_rejected";
        else if ((&c == &counters[0] || &c == &counters[1]) && !v.count) c.status = "zero_rejected";
        else { c.value = double(v.count); c.status = "ok"; }
    }
}

std::string counter_status() {
    std::string s;
    for (size_t i = 0; i < counters.size(); ++i) s += (i ? "|" : "") + event_names[i] + "=" + counters[i].status;
    return s;
}

long long huge_bytes(void* mem, size_t mapped) {
    std::ifstream f("/proc/self/smaps");
    if (!f) return -1;
    std::string line;
    bool inside = false;
    while (std::getline(f, line)) {
        unsigned long lo, hi;
        if (sscanf(line.c_str(), "%lx-%lx", &lo, &hi) == 2) {
            auto address = reinterpret_cast<uintptr_t>(mem);
            // Reject merged/split VMAs: their totals cannot identify this allocation's backing.
            inside = lo == address && hi == address + mapped;
        }
        if (inside && line.rfind("AnonHugePages:", 0) == 0) {
            return std::stoll(line.substr(14)) * 1024;
        }
    }
    return -1;
}

std::vector<size_t> make_chains(U64* data, size_t n, size_t step, size_t k, U64 seed) {
    std::vector<size_t> order(n), heads(k);
    std::iota(order.begin(), order.end(), 0);
    std::mt19937_64 rng(seed);
    // Explicit Fisher-Yates gives the same permutation across standard libraries.
    for (size_t i = n; i > 1; --i) std::swap(order[i-1], order[rng() % i]);
    for (size_t c = 0; c < k; ++c) {
        size_t begin = n*c/k, end = n*(c+1)/k;
        heads[c] = order[begin]*step;
        for (size_t j = begin; j < end; ++j)
            data[order[j]*step] = order[j+1 == end ? begin : j+1]*step;
    }
    return heads;
}

void validate_chains(const U64* data, size_t n, size_t step, const std::vector<size_t>& heads) {
    std::vector<bool> seen(n, false);
    size_t total = 0;
    for (size_t c = 0; c < heads.size(); ++c) {
        size_t p = heads[c], length = n*(c+1)/heads.size() - n*c/heads.size();
        for (size_t j = 0; j < length; ++j) {
            require(p % step == 0 && p/step < n, "invalid pointer index");
            require(!seen[p/step], "chain repeats early or overlaps");
            seen[p/step] = true; ++total; p = data[p];
        }
        require(p == heads[c], "chain does not close");
    }
    require(total == n, "chains do not cover working set");
}

U64 chase(volatile U64* data, std::vector<size_t>& heads, size_t rounds) {
    for (size_t r = 0; r < rounds; ++r)
        for (auto& p : heads) p = data[p];
    U64 sum = 0;
    for (auto p : heads) sum += p;
    return sum;
}

U64 stream(volatile U64* data, const std::vector<size_t>& order, size_t step,
         size_t words, int read_percent, size_t passes, U64& reads, U64& writes) {
    U64 sum = 0, op = 0;
    for (size_t pass = 0; pass < passes; ++pass) {
        for (size_t i = 0; i < order.size(); ++i, ++op) {
            size_t at = order[i]*step;
            bool rd = int(op % 10) < read_percent/10;
            if (rd) {
                for (size_t w = 0; w < words; ++w) sum += data[at+w];
                ++reads;
            } else {
                for (size_t w = 0; w < words; ++w) data[at+w] = op+w+1;
                ++writes;
            }
        }
    }
    return sum;
}

void self_test() {
    for (size_t n : {size_t(1),size_t(10),size_t(127),size_t(1024)}) {
        for (size_t k : {size_t(1),size_t(2),size_t(8)}) {
            if (k > n) continue;
            std::vector<U64> a(n*8), b(n*8);
            auto h = make_chains(a.data(), n, 8, k, 42);
            auto h2 = make_chains(b.data(), n, 8, k, 42);
            require(a == b && h == h2, "nondeterministic initialization");
            validate_chains(a.data(), n, 8, h);
            auto ref = h;
            for (size_t r = 0; r < 37; ++r) for (auto& p : ref) p = a.at(p);
            chase(a.data(), h, 37);
            require(h == ref, "chase differs from reference");
        }
    }
    for (int ratio : {0,50,70,100}) for (size_t words : {size_t(1),size_t(8)}) {
        std::vector<U64> a(10*128+8, 3), ref = a;
        std::vector<size_t> order = {9,2,5,1,6,3,8,0,4,7};
        U64 rd = 0, wr = 0, expected = 0;
        for (size_t op = 0; op < 20; ++op) for (size_t w = 0; w < words; ++w) {
            size_t at = order[op%10]*128+w;
            if (int(op%10) < ratio/10) expected += ref.at(at);
            else ref.at(at) = op+w+1;
        }
        U64 got = stream(a.data(), order, 128, words, ratio, 2, rd, wr);
        require(a == ref && got == expected, "stream differs from reference");
        require(rd == U64(ratio/5) && rd+wr == 20, "incorrect read/write counts");
        require(a.back() == 3, "guard overwritten");
    }
    std::cout << "PASS: deterministic chains, full coverage, bounds, reference loops, exact RW counts\n";
}

int main(int argc, char** argv) try {
    std::string experiment = "latency", pattern = "random", page = "normal";
    size_t bytes = 32768, stride = 64, gran = 8, intensity = 1;
    U64 seed = 42;
    int reps = 5, ratio = 100, cpu = -1, warmups = 2;
    double ms = 100;
    bool perf = false, check = false;
    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        if (a == "--header") { std::cout << header << '\n'; return 0; }
        if (a == "--self-test") { self_test(); return 0; }
        if (a == "--probe-counters") {
            open_counters(true);
            std::cout << counter_status() << '\n';
            for (auto& c : counters) if (c.fd >= 0) close(c.fd);
            return 0;
        }
        if (a == "--help") {
            std::cout << "--experiment latency|pattern|knee|working|tlb|pitfall --pattern sequential|random|stride\n"
                         "--size BYTES --stride BYTES --granularity BYTES --read 0|50|70|100\n"
                         "--intensity 1..32 --pages normal|huge --reps N --ms N --warmups N\n"
                         "--seed N --cpu N --perf --check-only --header --self-test --probe-counters\n";
            return 0;
        }
        if (a == "--perf") { perf = true; continue; }
        if (a == "--check-only") { check = true; continue; }
        require(i+1 < argc, "missing argument for " + a);
        std::string v = argv[++i];
        if (a == "--experiment") experiment = v;
        else if (a == "--pattern") pattern = v;
        else if (a == "--pages") page = v;
        else if (a == "--ms") {
            size_t used = 0; ms = std::stod(v, &used);
            require(used == v.size(), "invalid duration");
        }
        else {
            require(!v.empty() && v[0] != '-', "negative numeric option");
            size_t used = 0; U64 x = std::stoull(v, &used);
            require(used == v.size() && x <= (1ULL<<40), "invalid numeric option");
            if (a == "--size") bytes = x;
            else if (a == "--stride") stride = x;
            else if (a == "--granularity") gran = x;
            else if (a == "--intensity") intensity = x;
            else if (a == "--seed") seed = x;
            else if (a == "--reps") { require(x <= 1000, "too many reps"); reps = x; }
            else if (a == "--read") { require(x <= 100, "invalid ratio"); ratio = x; }
            else if (a == "--cpu") { require(x < CPU_SETSIZE, "cpu too large"); cpu = x; }
            else if (a == "--warmups") { require(x <= 100, "too many warmups"); warmups = x; }
            else throw std::runtime_error("unknown option " + a);
        }
    }
    require(experiment == "latency" || experiment == "pattern" || experiment == "knee" ||
            experiment == "working" || experiment == "tlb" || experiment == "pitfall", "invalid experiment");
    bool dependent = experiment == "latency" || experiment == "knee" || experiment == "working" || experiment == "tlb";
    require(page == "normal" || page == "huge", "invalid page mode");
    require(pattern == "random" || pattern == "sequential" || pattern == "stride", "invalid pattern");
    require(bytes >= 64 && bytes % 8 == 0, "size must be >=64 and divisible by 8");
    require(stride >= gran && stride % 8 == 0 && gran >= 8 && gran % 8 == 0 && gran <= 1024, "invalid stride/granularity");
    require(ratio == 0 || ratio == 50 || ratio == 70 || ratio == 100, "invalid RW ratio");
    require(intensity >= 1 && intensity <= 32 && reps >= 1 && warmups >= 1 &&
            std::isfinite(ms) && ms >= 1 && ms <= 60000, "invalid run parameters");
    require(!dependent || (ratio == 100 && gran == 8 && pattern == "random"), "chains require random 8-byte reads");
    require(experiment == "knee" || intensity == 1, "intensity is only used by knee");
    if (!dependent && pattern != "stride") require(stride == gran, "sequential/random require stride=granularity");
    if (cpu >= 0) {
        cpu_set_t set; CPU_ZERO(&set); CPU_SET(cpu, &set);
        require(sched_setaffinity(0, sizeof(set), &set) == 0, "CPU pinning failed");
    }
    cpu_set_t allowed; CPU_ZERO(&allowed);
    require(sched_getaffinity(0, sizeof(allowed), &allowed) == 0, "cannot read affinity");
    bool pinned = CPU_COUNT(&allowed) == 1;
    size_t step = stride/8, n = (bytes-gran)/stride+1;
    require(n >= intensity && n >= 1, "working set too small");
    long pagesize = sysconf(_SC_PAGESIZE);
    require(pagesize > 0, "invalid base page size");
    size_t mapped = (bytes+pagesize-1)/pagesize*pagesize;
    void* mem = mmap(nullptr, mapped, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
    require(mem != MAP_FAILED, "mmap failed: reduce working-set size");
    int advice = madvise(mem, mapped, page == "huge" ? MADV_HUGEPAGE : MADV_NOHUGEPAGE);
    std::string page_status = advice == 0 ? "advice_ok" : "advice_errno_" + std::to_string(errno);
    U64* data = static_cast<U64*>(mem);
    std::fill(data, data+bytes/8, U64(3)); // Fault and initialize all pages before timing.
    std::vector<size_t> heads, order;
    if (dependent) {
        heads = make_chains(data, n, step, intensity, seed);
        validate_chains(data, n, step, heads);
    } else {
        order.resize(n); std::iota(order.begin(), order.end(), 0);
        if (pattern == "random") {
            std::mt19937_64 rng(seed);
            for (size_t i = n; i > 1; --i) std::swap(order[i-1], order[rng()%i]);
        }
        for (auto i : order) require(i*step+gran/8 <= bytes/8, "stream bounds failure");
    }
    if (check) {
        std::cout << "PASS: configuration, full chain coverage/order bounds; no timing performed\n";
        munmap(mem, mapped); return 0;
    }
    size_t rounds = std::max(size_t(1024), (n+intensity-1)/intensity);
    size_t passes = 10/std::gcd(n,size_t(10));
    U64 checksum = 0, dummy_reads = 0, dummy_writes = 0;
    for (int w = 0; w < warmups; ++w) {
        if (dependent) checksum += chase(data, heads, rounds);
        else checksum += stream(data, order, step, gran/8, ratio, passes, dummy_reads, dummy_writes);
    }
    open_counters(perf);
    for (int rep = 1; rep <= reps; ++rep) {
        U64 ops = 0, reads = 0, writes = 0;
        long long huge_before = huge_bytes(mem, mapped);
        int cpu_before = sched_getcpu();
        start_counters();
        U64 begin = now_ns(), end;
        do {
            if (dependent) { checksum += chase(data, heads, rounds); ops += rounds*intensity; }
            else checksum += stream(data, order, step, gran/8, ratio, passes, reads, writes);
            end = now_ns();
        } while (double(end-begin) < ms*1e6);
        stop_counters();
        int cpu_after = sched_getcpu();
        long long huge_after = huge_bytes(mem, mapped);
        if (dependent) reads = ops; else ops = reads+writes;
        U64 logical = ops*gran;
        double ns = end-begin, service = ns/double(ops);
        double dep_ns = dependent && intensity == 1 ? service : missing;
        double turn_ns = dependent ? service*intensity : missing;
        bool valid = ns > 0 && ops > 0 && cpu_before == cpu_after;
        require(dependent || reads*100 == ops*U64(ratio), "measured mix is incorrect");
        double cycle_op = pinned && valid ? counters[0].value/double(ops) : missing;
        sink = checksum;
        std::cout << std::setprecision(12) << experiment << ',' << pattern << ',' << bytes << ',' << stride << ','
          << gran << ',' << ratio << ',' << intensity << ',' << page << ',' << rep << ',' << seed << ','
          << (pinned ? cpu_before : -1) << ',' << ns << ',' << ops << ',' << reads << ',' << writes << ',' << logical << ','
          << dep_ns << ',' << service << ',' << turn_ns << ',' << double(ops)*1000/ns << ',' << double(logical)/ns << ',' << cycle_op;
        for (auto& c : counters) std::cout << ',' << c.value;
        std::cout << ',' << counter_status() << ',' << huge_before << ',' << huge_after << ',' << page_status << ','
                  << (valid ? (pinned ? "ok" : "ok_unpinned") : "invalid_migration_or_timer") << ',' << checksum << '\n';
    }
    for (auto& c : counters) if (c.fd >= 0) close(c.fd);
    munmap(mem, mapped);
    return 0;
} catch (const std::exception& e) {
    std::cerr << "benchmark: " << e.what() << '\n'; return 1;
}
