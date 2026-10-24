import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess


def read(path):
    try:
        return Path(path).read_text().strip()
    except OSError:
        return None


def command(args):
    try:
        p = subprocess.run(args, text=True, capture_output=True, timeout=15)
        return (p.stdout + p.stderr).strip()
    except (OSError, subprocess.TimeoutExpired) as e:
        return f"unavailable: {e}"


def positive(name, default):
    value = int(os.environ.get(name, default))
    if value <= 0:
        raise ValueError(f"{name} must be positive")
    return value


def collect():
    allowed = sorted(os.sched_getaffinity(0)) if hasattr(os, "sched_getaffinity") else []
    cpu = int(os.environ.get("CPU", allowed[0] if allowed else 0))
    if allowed and cpu not in allowed:
        raise ValueError(f"CPU={cpu} is outside allowed affinity {allowed}")
    pin = os.environ.get("PIN", "1") == "1"
    if pin:
        if shutil.which("taskset"):
            check = subprocess.run(["taskset", "-c", str(cpu), "true"], capture_output=True)
            pin = check.returncode == 0
        else:
            pin = False
    caches = []
    for entry in sorted(Path(f"/sys/devices/system/cpu/cpu{cpu}/cache").glob("index*")):
        item = {key: read(entry / key) for key in ["level", "type", "size", "coherency_line_size", "shared_cpu_list"]}
        size = item["size"]
        if size:
            unit = size[-1].upper()
            item["bytes"] = int(size[:-1]) * {"K": 1024, "M": 1024**2, "G": 1024**3}[unit] if unit in "KMG" else int(size)
        caches.append(item)
    def capacity(level):
        return max((c.get("bytes", 0) for c in caches if c["level"] == str(level)
                    and c["type"] in ("Data", "Unified")), default=0)
    l1 = int(os.environ.get("L1_BYTES", capacity(1)))
    l2 = int(os.environ.get("L2_BYTES", capacity(2)))
    llc = int(os.environ.get("LLC_BYTES", capacity(3)))
    dram = positive("DRAM_BYTES", max(256*1024**2, 4*llc))
    proc = read("/proc/cpuinfo") or ""
    fields = dict(line.split(":", 1) for line in proc.split("\n\n")[0].splitlines() if ":" in line)
    fields = {k.strip(): v.strip() for k, v in fields.items()}
    cfg = {
        "reps": positive("REPS", 7), "warmup": positive("WARMUP", 3),
        "batch_elements": positive("BATCH_ELEMENTS", 4194304),
        "l1_bytes": l1, "l2_bytes": l2, "llc_bytes": llc, "dram_bytes": dram,
        "n_list": [int(n) for n in os.environ.get("N_LIST", "128 1024 8192 65536 524288 4194304").split()],
        "align_n": [int(n) for n in os.environ.get("ALIGN_N", "128 16384").split()],
        "stride_n": [int(n) for n in os.environ.get("STRIDE_N", "4096 1048576").split()],
        "cycles_requested": os.environ.get("CYCLES", "0") == "1",
    }
    if any(n <= 0 for key in ("n_list", "align_n", "stride_n") for n in cfg[key]):
        raise ValueError("all N values must be positive")
    for name, value in (("L1_BYTES", l1), ("L2_BYTES", l2), ("LLC_BYTES", llc)):
        if value < 0:
            raise ValueError(f"{name} cannot be negative")
    freq = Path(f"/sys/devices/system/cpu/cpu{cpu}/cpufreq")
    files = ["scaling_governor", "scaling_driver", "scaling_cur_freq", "scaling_min_freq", "scaling_max_freq",
             "cpuinfo_min_freq", "cpuinfo_max_freq", "energy_performance_preference"]
    source_files = ["bench.cpp", "Makefile", "run.sh", "environment.py", "analyze.py", "verify_simd.sh", "check.py"]
    return {
        "recorded_utc": command(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]),
        "cpu_model": fields.get("model name", fields.get("Processor")),
        "isa_flags": fields.get("flags", fields.get("Features")),
        "lscpu": command(["lscpu"]), "cache_topology": caches,
        "os": platform.platform(), "kernel": platform.release(), "uname": command(["uname", "-a"]),
        "gcc_version": command([os.environ.get("CXX", "g++"), "--version"]),
        "compiler_flags": command(["make", "--no-print-directory", "flags"]),
        "compiler_target_options": command([os.environ.get("CXX", "g++"), "-march=native", "-Q", "--help=target"]),
        "python": platform.python_version(),
        "python_packages": command(["python3", "-c", "import pandas,matplotlib; print('pandas',pandas.__version__,'matplotlib',matplotlib.__version__)"]),
        "frequency_khz": {key: read(freq / key) for key in files},
        "cpu_mhz_snapshot": fields.get("cpu MHz"),
        "smt_active": read("/sys/devices/system/cpu/smt/active"),
        "thread_siblings": read(f"/sys/devices/system/cpu/cpu{cpu}/topology/thread_siblings_list"),
        "allowed_cpus": allowed, "selected_cpu": cpu, "pinning_active": pin,
        "pin_command": ["taskset", "-c", str(cpu)] if pin else [],
        "isolation": read("/sys/devices/system/cpu/isolated"),
        "perf_event_paranoid": read("/proc/sys/kernel/perf_event_paranoid"),
        "timing": "steady_clock (monotonic), kernel calls only; fixed repeated hot-array batch; no allocation/init/reference in timed region",
        "cycles": "optional per-thread perf_event_open HW_CPU_CYCLES, user mode, pinned event, non-multiplexed only; includes timer/loop overhead",
        "configuration": cfg,
        "sha256": {p: hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in source_files if Path(p).exists()},
    }


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("output", help="new JSON file; refuses to overwrite")
    args = p.parse_args()
    try:
        info = collect()
        with open(args.output, "x") as f:
            json.dump(info, f, indent=2)
            f.write("\n")
        if not info["pinning_active"]:
            print("warning: CPU pinning inactive; record scheduling noise and rerun pinned if possible", file=__import__("sys").stderr)
    except (ValueError, OSError) as e:
        p.exit(1, f"error: {e}\n")
