set -u
cd -- "$(dirname -- "$0")"
show() { printf '\n$'; printf ' %q' "$@"; printf '\n'; "$@" 2>&1 || true; }
printf 'Captured UTC: '; date -u --iso-8601=seconds
printf 'Requested CPU=%s REPS=%s MS=%s WARMUPS=%s SEED=%s PERF=%s\n' \
    "${CPU:-auto}" "${REPS:-5}" "${MS:-100}" "${WARMUPS:-2}" "${SEED:-42}" "${PERF:-0}"
printf 'Isolation: affinity only; no CPU isolation, governor, SMT, NUMA, or host settings changed.\n'
show uname -a
show cat /etc/os-release
show lscpu
show lscpu -C
show cat /proc/cpuinfo
show cat /proc/meminfo
show free -h
show getconf PAGESIZE
show taskset -pc $$
show numactl --hardware
show cat /proc/self/status
show cat /proc/self/numa_maps
show cat /proc/sys/kernel/perf_event_paranoid
show ls /sys/bus/event_source/devices
show cat /sys/devices/system/cpu/smt/active /sys/devices/system/cpu/smt/control
for f in /sys/devices/system/cpu/cpu*/cache/index*/{level,type,size,coherency_line_size,shared_cpu_list} \
         /sys/devices/system/cpu/cpu*/cpufreq/{scaling_governor,scaling_cur_freq,scaling_min_freq,scaling_max_freq} \
         /sys/kernel/mm/transparent_hugepage/{enabled,defrag,hpage_pmd_size} \
         /sys/kernel/mm/transparent_hugepage/hugepages-*kB/enabled; do
    [ ! -r "$f" ] || show cat "$f"
done
"${PYTHON:-python3}" - <<'PY_CACHE'
import os
from pathlib import Path
cpu = int(os.environ.get("CPU", min(os.sched_getaffinity(0))))
for entry in sorted(Path(f"/sys/devices/system/cpu/cpu{cpu}/cache").glob("index*")):
    try:
        level = (entry / "level").read_text().strip()
        kind = (entry / "type").read_text().strip()
        text = (entry / "size").read_text().strip()
        size = int(text[:-1]) * {"K": 1024, "M": 1024**2, "G": 1024**3}[text[-1]]
        print(f"CACHE level={level} type={kind} bytes={size}")
    except (OSError, ValueError, KeyError) as exc:
        print(f"Cache size unavailable: {exc}")
PY_CACHE
show g++ --version
show make --version
show make -n -B benchmark
show bash --version
show "${PYTHON:-python3}" --version
show "${PYTHON:-python3}" -c 'import pandas, matplotlib; print("pandas", pandas.__version__, "matplotlib", matplotlib.__version__)'
show perf --version
show ./benchmark --probe-counters
if command -v perf >/dev/null; then
    for event in cycles instructions cache-references cache-misses dTLB-loads dTLB-load-misses; do
        show perf stat -e "$event" -- true
    done
fi
show which mlc
if command -v wsl.exe >/dev/null; then show wsl.exe --version; show wsl.exe --status; fi
show cat /proc/version /proc/sys/kernel/osrelease
show sha256sum benchmark.cpp benchmark Makefile run.sh environment.sh analyze.py
printf '\nHost RAM, host power policy, hypervisor PMU fidelity and host activity are not established by guest probes.\n'
