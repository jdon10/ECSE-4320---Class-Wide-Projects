import argparse
import json
from pathlib import Path
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from experiments import check_json

PERCENTILES = [50, 95, 99, 99.9]
METRICS = ['iops', 'mib_s', 'lat_us', 'clat_us', 'slat_us',
           'p50_us', 'p95_us', 'p99_us', 'p99_9_us', 'little_clat', 'little_lat']
KEYS = ['session', 'experiment', 'rw', 'bs_kib', 'qd', 'read_pct', 'size_bytes',
        'direct', 'label', 'runtime', 'warmup', 'engine', 'numjobs', 'smoke', 'direction']


def latency(section, name):
    for suffix, multiplier in [('ns', 0.001), ('us', 1.0), ('ms', 1000.0)]:
        key = f'{name}_{suffix}'
        if key in section:
            data = section[key]
            return data, multiplier
    return section.get(name, {}), 1.0


def mean_latency(section, name):
    data, scale = latency(section, name)
    return float(data['mean']) * scale if 'mean' in data else float('nan')


def percentile(section, value):
    data, scale = latency(section, 'lat')
    for key, result in data.get('percentile', {}).items():
        if abs(float(key) - value) < 0.00001:
            return float(result) * scale
    return float('nan')


def parse_job(job, settings, session):
    rows = []
    for direction in ['read', 'write']:
        data = job.get(direction, {})
        expected = settings['read_pct'] > 0 if direction == 'read' else settings['read_pct'] < 100
        if not expected:
            continue
        if data.get('total_ios', 0) <= 0 or data.get('iops', 0) <= 0:
            raise ValueError(f'No completed {direction} I/O for an active direction')
        row = dict(settings, session=session, direction=direction,
                   total_ios=data['total_ios'], io_bytes=data.get('io_bytes', float('nan')),
                   iops=float(data['iops']),
                   mib_s=float(data['bw_bytes']) / 1024**2 if 'bw_bytes' in data else float(data['bw']) / 1024,
                   lat_us=mean_latency(data, 'lat'), clat_us=mean_latency(data, 'clat'),
                   slat_us=mean_latency(data, 'slat'))
        for p in PERCENTILES:
            row[f'p{str(p).replace(".", "_")}_us'] = percentile(data, p)
        row['little_clat'] = row['iops'] * row['clat_us'] / 1e6
        row['little_lat'] = row['iops'] * row['lat_us'] / 1e6
        for bucket, value in job.get('iodepth_level', {}).items():
            row['depth_pct_' + bucket.replace('>=', 'ge')] = value
        rows.append(row)
    if not rows:
        raise ValueError('No active directions')
    total = dict(settings, session=session, direction='total',
                 total_ios=sum(r['total_ios'] for r in rows), io_bytes=sum(r['io_bytes'] for r in rows))
    for metric in ['iops', 'mib_s', 'little_clat', 'little_lat']:
        total[metric] = sum(r[metric] for r in rows)
    for metric in ['lat_us', 'clat_us', 'slat_us']:
        total[metric] = sum(r[metric] * r['total_ios'] for r in rows) / total['total_ios']
    for p in PERCENTILES:
        key = f'p{str(p).replace(".", "_")}_us'
        total[key] = rows[0][key] if len(rows) == 1 else float('nan')
    rows.append(total)
    return rows


def summarize(frame):
    grouped = frame.groupby(KEYS, dropna=False)[METRICS].agg(['mean', 'std', 'count']).reset_index()
    grouped.columns = ['_'.join(str(c) for c in col if c) if isinstance(col, tuple) else col for col in grouped.columns]
    return grouped


def plot_lines(data, x, metric, ylabel, title, destination, categories=False, series=('rw', 'direction')):
    if data.empty:
        return
    fig, ax = plt.subplots(figsize=(8, 5))
    for name, group in data.groupby(list(series), dropna=False):
        group = group.sort_values(x)
        valid = group[metric + '_mean'].notna()
        group = group[valid]
        if group.empty:
            continue
        values = group[x].astype(str) if categories else group[x]
        errors = group[metric + '_std'].to_numpy(dtype=float)
        errors = np.where(np.isfinite(errors), errors, 0)
        ax.errorbar(values, group[metric + '_mean'], yerr=errors,
                    marker='o', capsize=3, label=' / '.join(map(str, name if isinstance(name, tuple) else (name,))))
    if x == 'qd':
        ax.set_xscale('log', base=2)
        ax.set_xticks(sorted(data[x].unique()), labels=[str(v) for v in sorted(data[x].unique())])
    labels = {'bs_kib': 'Block size (KiB)', 'qd': 'Configured queue depth',
              'read_pct': 'Configured read percentage (%)', 'size_gib': 'Working range (GiB)',
              'label': 'Configuration', 'workload': 'Workload (block size, direction)'}
    ax.set(xlabel=labels.get(x, x), ylabel=ylabel, title=title)
    ax.grid(alpha=0.25)
    ax.legend(fontsize=8)
    if categories:
        ax.tick_params(axis='x', labelrotation=15)
    fig.tight_layout()
    fig.savefig(destination, dpi=160)
    plt.close(fig)


def plots(summary, output):
    for session, data in summary.groupby('session'):
        folder = output / session
        folder.mkdir(parents=True, exist_ok=True)
        smoke = bool(data.iloc[0]['smoke'])
        prefix = 'SMOKE ONLY — ' if smoke else ''
        note = '\nTrial means ± sample SD; latency = fio total latency'
        def draw(exp, x, metric, ylabel, name, title, total=False, categories=False, series=('rw', 'direction')):
            subset = data[(data.experiment == exp) & ((data.direction == 'total') if total else (data.direction != 'total'))].copy()
            if x == 'workload':
                subset[x] = subset.rw + ' ' + subset.bs_kib.astype(str) + ' KiB'
            if x == 'size_gib':
                subset[x] = subset.size_bytes / 1024**3
            plot_lines(subset, x, metric, ylabel, prefix + title + note, folder / name, categories, series)
        draw('baseline', 'workload', 'lat_us', 'Mean total latency (µs)', '01_baseline.png', 'QD=1 baseline', categories=True)
        draw('blocksize', 'bs_kib', 'mib_s', 'Throughput (MiB/s)', '02_block_throughput.png', 'Block size sweep (QD=8)', total=True)
        draw('blocksize', 'bs_kib', 'lat_us', 'Mean total latency (µs)', '03_block_latency.png', 'Block size sweep (QD=8)')
        draw('mix', 'read_pct', 'mib_s', 'Total throughput (MiB/s)', '04_mix.png', '4 KiB random read/write mix (QD=8)', total=True, series=('direction',))
        draw('mix', 'read_pct', 'lat_us', 'Mean total latency (µs)', '04_mix_latency.png', '4 KiB random read/write mix (QD=8)', series=('direction',))
        draw('queue', 'qd', 'iops', 'IOPS', '05_queue_iops.png', 'Queue sweep: 4 KiB random / 128 KiB sequential', total=True)
        draw('queue', 'qd', 'lat_us', 'Mean total latency (µs)', '06_queue_latency.png', 'Queue sweep: 4 KiB random / 128 KiB sequential')
        q = data[(data.experiment == 'queue') & (data.direction == 'total')]
        if not q.empty:
            fig, ax = plt.subplots(figsize=(8, 5))
            for rw, group in q.groupby('rw'):
                group = group.sort_values('qd')
                ax.errorbar(group.mib_s_mean, group.lat_us_mean,
                            xerr=group.mib_s_std.fillna(0), yerr=group.lat_us_std.fillna(0), marker='o', capsize=2, label=rw)
                for _, row in group.iterrows():
                    ax.annotate(f"QD {row.qd}", (row.mib_s_mean, row.lat_us_mean), fontsize=7)
            ax.set(xlabel='Throughput (MiB/s)', ylabel='Mean total latency (µs)',
                   title=prefix + 'Throughput–latency relationship' + note)
            ax.legend(); ax.grid(alpha=0.25); fig.tight_layout()
            fig.savefig(folder / '07_throughput_latency.png', dpi=160); plt.close(fig)
        tail = data[(data.experiment == 'tail') & (data.direction != 'total')]
        if not tail.empty:
            fig, ax = plt.subplots(figsize=(8, 5))
            for _, row in tail.iterrows():
                keys = [f'p{str(p).replace(".", "_")}_us' for p in PERCENTILES]
                ax.errorbar([str(p) for p in PERCENTILES], [row[k + '_mean'] for k in keys],
                            yerr=[row[k + '_std'] if pd.notna(row[k + '_std']) else 0 for k in keys],
                            marker='o', capsize=3, label=f'QD {row.qd} {row.direction}')
            ax.set(xlabel='Percentile', ylabel='Total latency (µs)',
                   title=prefix + 'Tail latency: 4 KiB random read\nMean of trial percentiles ± SD (not pooled percentiles)')
            ax.legend(); ax.grid(alpha=0.25); fig.tight_layout()
            fig.savefig(folder / '08_tail.png', dpi=160); plt.close(fig)
        draw('working_set', 'size_gib', 'mib_s', 'Throughput (MiB/s)', '09_working_set.png', 'Working range: 4 KiB random, QD=8', total=True)
        draw('working_set', 'size_gib', 'lat_us', 'Mean total latency (µs)', '09_working_set_latency.png', 'Working range: 4 KiB random, QD=8')
        draw('pitfall', 'label', 'mib_s', 'Throughput (MiB/s)', '10_pitfall.png', '256 MiB maximum range: 4 KiB random read, QD=1', total=True, categories=True, series=('direction',))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, default=Path('results/raw'))
    parser.add_argument('--output', type=Path, default=Path('results'))
    parser.add_argument('--include-smoke', action='store_true')
    args = parser.parse_args()
    manifests = [args.input / 'manifest.json'] if (args.input / 'manifest.json').exists() else sorted(args.input.glob('*/manifest.json'))
    records, status, warnings = [], [], []
    for path in manifests:
        manifest = json.loads(path.read_text())
        session = path.parent.name
        if manifest['arguments']['smoke'] and not args.include_smoke:
            continue
        if not (path.parent / 'COMPLETE').exists():
            warnings.append(f'{session}: session did not finish; available valid trials will be shown.')
        for row in manifest['jobs']:
            raw = path.parent / 'raw' / (row['id'] + '.json')
            entry = dict(session=session, id=row['id'], kind=row['kind'], status='ok', detail='')
            try:
                job = check_json(raw, row)
                if row['kind'] == 'measurement':
                    parsed = parse_job(job, row, session)
                    records.extend(parsed)
                    for record in parsed:
                        if record['direction'] != 'total' and any(pd.isna(record[k]) for k in ['lat_us', 'p50_us', 'p95_us', 'p99_us', 'p99_9_us']):
                            warnings.append(f'{session}/{row["id"]}: missing latency statistics; left blank.')
            except (OSError, ValueError, KeyError, TypeError) as exc:
                entry.update(status='missing_or_invalid', detail=str(exc))
                warnings.append(f'{session}/{row["id"]}: {exc}')
            status.append(entry)
    processed = args.output / 'processed'
    processed.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(status, columns=['session', 'id', 'kind', 'status', 'detail']).to_csv(processed / 'run_status.csv', index=False)
    (processed / 'warnings.txt').write_text('\n'.join(warnings) + ('\n' if warnings else ''))
    for warning in warnings:
        print('WARNING:', warning, file=sys.stderr)
    if not records:
        print('No valid measurements found. No performance CSV or plots generated.', file=sys.stderr)
        return 2
    frame = pd.DataFrame(records)
    summary = summarize(frame)
    frame.to_csv(processed / 'trials.csv', index=False)
    summary.to_csv(processed / 'summary.csv', index=False)
    summary[summary.experiment == 'baseline'].to_csv(processed / 'baseline_table.csv', index=False)
    plots(summary, args.output / 'plots')
    print(f'Saved trial/summary CSVs and plots under {args.output}. Review run_status.csv and warnings.txt.')
    return 2 if warnings else 0


if __name__ == '__main__':
    sys.exit(main())
