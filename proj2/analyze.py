import argparse
import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

KEYS = ["experiment", "pattern", "size_bytes", "stride_bytes", "granularity_bytes",
        "read_percent", "intensity", "page_mode", "seed", "cpu", "page_evidence"]
METRICS = ["runtime_ns", "operations", "logical_bytes", "dependent_latency_ns", "service_ns",
           "chain_turnaround_ns", "throughput_mops", "bandwidth_gbs", "cycles_per_op", "cycles",
           "instructions", "cache_references", "cache_misses", "dtlb_loads", "dtlb_load_misses",
           "cache_misses_per_kop", "dtlb_misses_per_kop", "huge_fraction"]


def summarize(raw):
    required = set(KEYS[:-1] + METRICS[:-3] + ["status", "page_status", "counter_status",
                   "huge_bytes_before", "huge_bytes_after", "rep", "read_operations", "write_operations"])
    absent = required - set(raw.columns)
    if absent:
        raise ValueError(f"Missing CSV columns: {sorted(absent)}")
    for column in set(METRICS + KEYS[2:7] + ["cpu", "seed", "rep", "read_operations",
                                            "write_operations", "huge_bytes_before", "huge_bytes_after"]) & set(raw.columns):
        raw[column] = pd.to_numeric(raw[column], errors="coerce")
    valid = raw.status.isin(["ok", "ok_unpinned"])
    valid &= (raw.runtime_ns > 0) & (raw.operations > 0)
    valid &= raw.read_operations + raw.write_operations == raw.operations
    valid &= raw.logical_bytes == raw.operations * raw.granularity_bytes
    valid &= np.isclose(raw.bandwidth_gbs, raw.logical_bytes / raw.runtime_ns, rtol=1e-8)
    valid &= np.isclose(raw.throughput_mops, raw.operations * 1000 / raw.runtime_ns, rtol=1e-8)
    valid &= np.isclose(raw.service_ns, raw.runtime_ns / raw.operations, rtol=1e-8)
    valid &= np.isclose(raw.read_operations * 100 / raw.operations, raw.read_percent, rtol=1e-8)
    chain = raw.experiment.isin(["latency", "working", "knee", "tlb"])
    valid &= ~chain | np.isclose(raw.chain_turnaround_ns, raw.service_ns * raw.intensity, rtol=1e-8)
    valid &= ~(chain & (raw.intensity == 1)) | np.isclose(raw.dependent_latency_ns, raw.service_ns, rtol=1e-8)
    print(f"Accepted {int(valid.sum())}/{len(raw)} rows; excluded invalid status or arithmetic.")
    data = raw.loc[valid].copy()
    for event in ["cycles", "instructions", "cache_references", "cache_misses", "dtlb_loads", "dtlb_load_misses"]:
        trusted = data.counter_status.str.contains(rf"(?:^|\|){event}=ok(?:\||$)", regex=True, na=False)
        data.loc[~trusted, event] = np.nan
        if event == "cycles":
            data.loc[~trusted | (data.cpu < 0), "cycles_per_op"] = np.nan
    data["cache_misses_per_kop"] = data.cache_misses * 1000 / data.operations
    data["dtlb_misses_per_kop"] = data.dtlb_load_misses * 1000 / data.operations
    advice = data.page_status == "advice_ok"
    known = (data.huge_bytes_before >= 0) & (data.huge_bytes_after >= 0)
    stable = data.huge_bytes_before == data.huge_bytes_after
    normal = advice & known & stable & (data.huge_bytes_after == 0) & (data.page_mode == "normal")
    huge = advice & known & stable & (data.huge_bytes_after > 0) & (data.page_mode == "huge")
    data["page_evidence"] = "unverified_or_changing"
    data.loc[normal, "page_evidence"] = "normal_verified"
    data.loc[huge, "page_evidence"] = "huge_backing_verified"
    data.loc[advice & known & stable & (data.huge_bytes_after == 0) & (data.page_mode == "huge"),
             "page_evidence"] = "huge_request_unfulfilled"
    data["huge_fraction"] = np.where(known, data.huge_bytes_after / data.size_bytes, np.nan)
    if data.duplicated(KEYS + ["rep"]).any():
        raise ValueError("Duplicate configuration/repetition rows: analyze separate runs separately.")
    for key, group in data.groupby(KEYS, dropna=False):
        if len(group) < 3:
            print(f"NOTE: fewer than 3 repetitions for {key}")
    if data.empty:
        return data, pd.DataFrame(columns=KEYS + ["repetitions"])
    grouped = data.groupby(KEYS, dropna=False, sort=True)
    summary = grouped.size().rename("repetitions").to_frame()
    for metric in METRICS:
        stats = grouped[metric].agg(["median", "std", "count"])
        stats["q25"] = grouped[metric].quantile(0.25)
        stats["q75"] = grouped[metric].quantile(0.75)
        summary = summary.join(stats.add_prefix(metric + "_"))
    return data, summary.reset_index()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=Path)
    parser.add_argument("--out", type=Path, default=Path("results"))
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    if any(args.out.glob("*.png")) or any(args.out.glob("*.csv")):
        parser.error("Output contains plots/CSVs; use a new --out directory.")
    raw = pd.read_csv(args.csv)
    data, summary = summarize(raw)
    data.to_csv(args.out / "validated.csv", index=False)
    summary.to_csv(args.out / "summary.csv", index=False)
    if summary.empty:
        print("No valid measurements. Skipping all plots.")
        return
    cache_info = []
    env = args.csv.parent / "environment.txt"
    if env.exists():
        for level, kind, size in re.findall(r"CACHE level=(\d+) type=(\w+) bytes=(\d+)", env.read_text(errors="replace")):
            if kind in ["Data", "Unified"]:
                cache_info.append((int(level), int(size)))
    else:
        print("No adjacent environment.txt; cache capacity annotations unavailable.")

    def save(fig, name):
        fig.tight_layout()
        fig.savefig(args.out / name, dpi=160)
        plt.close(fig)
        print(f"Wrote {name}")

    def skip(name, reason):
        print(f"SKIP {name}: {reason}")

    def errors(frame, metric):
        mid = frame[metric + "_median"].to_numpy(dtype=float)
        return np.array([mid - frame[metric + "_q25"].to_numpy(dtype=float),
                         frame[metric + "_q75"].to_numpy(dtype=float) - mid])

    def curve(ax, frame, metric, label, x="size_bytes", scale=1024):
        frame = frame.sort_values(x)
        ax.errorbar(frame[x] / scale, frame[metric + "_median"], yerr=errors(frame, metric),
                    marker="o", capsize=3, label=label)
        ax.grid(alpha=0.25)

    def cache_lines(ax):
        for level, size in cache_info:
            ax.axvline(size / 1024, color="gray", linestyle=":", linewidth=1)
            ax.text(size / 1024, 0.98, f" L{level}", transform=ax.get_xaxis_transform(), va="top", fontsize=8)
        ax.set_xscale("log", base=2)
        ax.set_xlabel("Allocated data working set (KiB); dotted lines = guest cache capacities")

    base = summary[summary.experiment.isin(["latency", "working"]) & (summary.intensity == 1)]
    if len(base):
        fig, ax = plt.subplots(figsize=(8, 4))
        for name, g in base.groupby(["experiment", "page_mode"]):
            curve(ax, g, "dependent_latency_ns", "/".join(name))
        cache_lines(ax)
        ax.set_ylabel("Dependent-load time (ns/load)")
        ax.set_title("Low-concurrency latency regions (median and IQR)")
        ax.legend()
        save(fig, "latency_workingset.png")
        base.to_csv(args.out / "latency_table.csv", index=False)
        fig, axes = plt.subplots(1, 2, figsize=(11, 4))
        for name, g in base.groupby(["experiment", "page_mode"]):
            curve(axes[0], g, "throughput_mops", "/".join(name))
            curve(axes[1], g, "bandwidth_gbs", "/".join(name))
        for ax in axes:
            cache_lines(ax); ax.legend()
        axes[0].set_ylabel("Dependent loads (million/s)")
        axes[1].set_ylabel("Logical bandwidth (GB/s; 8 B/load)")
        fig.suptitle("Working-set transitions; memory-bus traffic is unmeasured")
        save(fig, "cache_workingset.png")
    else:
        skip("latency_workingset/cache_workingset", "no latency/working trials")

    pattern = summary[summary.experiment == "pattern"].copy()
    if len(pattern):
        pattern["label"] = (pattern.pattern + "/s" + pattern.stride_bytes.astype(str)
                            + "/g" + pattern.granularity_bytes.astype(str))
        read = pattern[pattern.read_percent == 100].sort_values("label")
        if len(read):
            fig, axes = plt.subplots(2, 1, figsize=(11, 7), sharex=True)
            for ax, metric, label in zip(axes, ["bandwidth_gbs", "service_ns"],
                                        ["Logical bandwidth (GB/s)", "Loop service time (ns/access)"]):
                ax.bar(read.label, read[metric + "_median"], yerr=errors(read, metric), capsize=3)
                ax.set_ylabel(label); ax.grid(axis="y", alpha=0.25)
            axes[-1].tick_params(axis="x", rotation=50)
            fig.suptitle("100% read: pattern/stride/granularity; service time is not load latency")
            save(fig, "pattern_bandwidth.png")
        fig, axes = plt.subplots(2, 2, figsize=(13, 8))
        for col, gran in enumerate(sorted(pattern.granularity_bytes.unique())[:2]):
            for ax, metric in zip(axes[:, col], ["bandwidth_gbs", "service_ns"]):
                g = pattern[pattern.granularity_bytes == gran]
                labels = sorted(g.label.unique())
                positions = np.arange(len(labels))
                for i, mix in enumerate([100, 0, 70, 50]):
                    if not (g.read_percent == mix).any():
                        continue
                    rows = g[g.read_percent == mix].set_index("label").reindex(labels)
                    ax.bar(positions + (i-1.5)*0.2, rows[metric+"_median"], width=0.2,
                           yerr=errors(rows, metric), capsize=2, label=f"R/W {mix}/{100-mix}")
                ax.set_xticks(positions, labels, rotation=45, ha="right")
                ax.set_title(f"{gran} B per access"); ax.grid(axis="y", alpha=0.25)
                ax.set_ylabel("Logical GB/s" if metric == "bandwidth_gbs" else "Loop service ns/access")
                ax.legend(fontsize=8)
        fig.suptitle("Read/write sweep: scalar operations, logical bytes, median and IQR")
        save(fig, "rw_mix.png")
    else:
        skip("pattern_bandwidth/rw_mix", "no pattern trials")

    knee = summary[summary.experiment == "knee"].sort_values("intensity").copy()
    if len(knee):
        fig, axes = plt.subplots(1, 2, figsize=(11, 4))
        for name, g in knee.groupby(["size_bytes", "page_mode"]):
            label = f"{name[0]/1024**2:g} MiB/{name[1]}"
            axes[0].errorbar(g.chain_turnaround_ns_median, g.throughput_mops_median,
                            xerr=errors(g, "chain_turnaround_ns"), yerr=errors(g, "throughput_mops"),
                            marker="o", capsize=3, label=label)
            for _, row in g.iterrows():
                axes[0].annotate(f"K={int(row.intensity)}", (row.chain_turnaround_ns_median, row.throughput_mops_median), fontsize=8)
            curve(axes[1], g, "throughput_mops", label, "intensity", 1)
            knee.loc[g.index, "throughput_gain_percent"] = g.throughput_mops_median.pct_change() * 100
        axes[0].set_xlabel("Chain-turnaround proxy K * time/operation (ns)")
        axes[1].set_xlabel("Independent chains K (software access intensity)")
        for ax in axes:
            ax.set_ylabel("Effective throughput (million loads/s)"); ax.legend(); ax.grid(alpha=0.25)
        fig.suptitle("Concurrency sweep; turnaround proxy is not measured DRAM request latency")
        save(fig, "throughput_latency.png")
        knee.to_csv(args.out / "knee_table.csv", index=False)
    else:
        skip("throughput_latency", "no concurrency trials")

    corr = summary[summary.experiment.isin(["latency", "working", "pattern"]) & summary.cache_misses_per_kop_median.notna()]
    if len(corr):
        fig, ax = plt.subplots(figsize=(8, 4))
        for name, g in corr.groupby(["experiment", "pattern"]):
            ax.errorbar(g.cache_misses_per_kop_median, g.service_ns_median,
                        xerr=errors(g, "cache_misses_per_kop"), yerr=errors(g, "service_ns"),
                        fmt="o", capsize=3, label="/".join(name))
        ax.set_xlabel("Generic perf cache misses / 1000 logical accesses")
        ax.set_ylabel("Loop service time (ns/access)"); ax.legend(); ax.grid(alpha=0.25)
        ax.set_title("Counter/performance correlation; event semantics are CPU dependent")
        save(fig, "cache_miss_correlation.png")
    else:
        skip("cache_miss_correlation", "no accepted cache-miss counters")

    tlb = summary[summary.experiment == "tlb"]
    if len(tlb):
        fig, ax = plt.subplots(figsize=(8, 4))
        for name, g in tlb.groupby(["page_mode", "page_evidence"]):
            curve(ax, g, "dependent_latency_ns", "/".join(name))
        ax.set_xscale("log", base=2); ax.set_xlabel("Allocated span (KiB); one 8 B node per base-page stride")
        ax.set_ylabel("Dependent-load time (ns/load)"); ax.legend(fontsize=8); ax.grid(alpha=0.25)
        ax.set_title("Page locality sweep; cache/set conflicts also affect latency")
        save(fig, "tlb_locality.png")
        verified = tlb[tlb.page_evidence.isin(["normal_verified", "huge_backing_verified"])]
        normal_sizes = set(verified.loc[verified.page_evidence == "normal_verified", "size_bytes"])
        huge_sizes = set(verified.loc[verified.page_evidence == "huge_backing_verified", "size_bytes"])
        paired = verified[verified.size_bytes.isin(normal_sizes & huge_sizes)]
        if len(paired):
            fig, axes = plt.subplots(1, 2, figsize=(11, 4))
            for name, g in paired.groupby("page_evidence"):
                curve(axes[0], g, "dependent_latency_ns", name)
                curve(axes[1], g, "huge_fraction", name)
            for ax in axes:
                ax.set_xscale("log", base=2); ax.set_xlabel("Allocated span (KiB)"); ax.legend(fontsize=8)
            axes[0].set_ylabel("Dependent-load time (ns/load)")
            axes[1].set_ylabel("Observed huge backing / data span")
            fig.suptitle("Verified page backing comparison; coverage may be partial")
            save(fig, "tlb_pages.png")
        else:
            skip("tlb_pages", "no matched verified normal/huge backing; advice is not allocation")
        measured = tlb[tlb.dtlb_misses_per_kop_median.notna()]
        if len(measured):
            fig, axes = plt.subplots(1, 2, figsize=(11, 4))
            for name, g in measured.groupby(["page_mode", "page_evidence"]):
                curve(axes[0], g, "dtlb_misses_per_kop", "/".join(name))
                axes[1].errorbar(g.dtlb_misses_per_kop_median, g.dependent_latency_ns_median,
                                 xerr=errors(g, "dtlb_misses_per_kop"), yerr=errors(g, "dependent_latency_ns"),
                                 fmt="o", capsize=3, label="/".join(name))
            axes[0].set_xscale("log", base=2); axes[0].set_xlabel("Allocated span (KiB)")
            axes[0].set_ylabel("dTLB load misses / 1000 loads")
            axes[1].set_xlabel("dTLB load misses / 1000 loads"); axes[1].set_ylabel("Dependent-load time (ns/load)")
            for ax in axes:
                ax.legend(fontsize=7); ax.grid(alpha=0.25)
            save(fig, "tlb_counters.png")
        else:
            skip("tlb_counters", "dTLB counters unavailable; timing alone does not prove TLB misses")
    else:
        skip("tlb graphs", "no page-locality trials")

    pitfall = summary[summary.experiment == "pitfall"].sort_values("size_bytes")
    if len(pitfall):
        fig, axes = plt.subplots(1, 2, figsize=(9, 4))
        for ax, metric, label in zip(axes, ["bandwidth_gbs", "service_ns"], ["Logical bandwidth (GB/s)", "Loop service time (ns/access)"]):
            ax.bar((pitfall.size_bytes/1024).map(lambda x: f"{x:g} KiB"), pitfall[metric+"_median"],
                   yerr=errors(pitfall, metric), capsize=4)
            ax.set_ylabel(label); ax.set_xlabel("Repeated sequential-read data span"); ax.grid(axis="y", alpha=0.25)
        fig.suptitle("Pitfall test: does a small reused array overstate DRAM performance?")
        save(fig, "pitfall.png")
    else:
        skip("pitfall", "no pitfall trials")
    print("Error bars are interquartile ranges across repetitions, not confidence intervals.")


if __name__ == "__main__":
    main()
