import argparse
import datetime as dt
import json
from importlib import metadata
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parent
GIB = 1024 ** 3
WORKLOADS = [('randread', 4), ('randwrite', 4), ('read', 128), ('write', 128)]
EXPERIMENTS = ['baseline', 'blocksize', 'mix', 'queue', 'tail', 'working_set', 'pitfall']


def save(path, data):
    path.write_text(json.dumps(data, indent=2) + '\n')


def capture(command):
    try:
        result = subprocess.run(command, text=True, capture_output=True, timeout=10)
        return (result.stdout + result.stderr).strip()
    except (OSError, subprocess.TimeoutExpired) as exc:
        return f'Unavailable: {exc}'


def matrix(args):
    rows = []
    size = 64 * 1024 ** 2 if args.smoke else args.size_gib * GIB
    runtime, ramp, repeats = (2, 0, 1) if args.smoke else (args.runtime, args.warmup, args.repeats)

    def add(exp, rw, bs, qd, read_pct=None, extent=None, direct=1, label=''):
        rows.append(dict(experiment=exp, rw=rw, bs_kib=bs, qd=qd,
                         read_pct=read_pct if read_pct is not None else (100 if 'read' in rw else 0),
                         size_bytes=extent or size, direct=direct, label=label,
                         runtime=runtime, warmup=ramp, engine=args.engine, numjobs=1))
    selected = EXPERIMENTS if args.experiment == 'all' else [args.experiment]
    for exp in selected:
        if exp == 'baseline':
            for rw, bs in WORKLOADS:
                add(exp, rw, bs, 1)
        elif exp == 'blocksize':
            for rw, _ in WORKLOADS:
                for bs in [4, 16, 32, 64, 128, 256]:
                    add(exp, rw, bs, 8)
        elif exp == 'mix':
            for pct in [100, 0, 70, 50]:
                add(exp, 'randread' if pct == 100 else 'randwrite' if pct == 0 else 'randrw', 4, 8, pct)
        elif exp == 'queue':
            for rw, bs in WORKLOADS:
                for qd in [1, 2, 4, 8, 16, 32, 64]:
                    add(exp, rw, bs, qd)
        elif exp == 'tail':
            if not args.tail_qds:
                raise ValueError('tail/all requires --tail-qds MID NEAR_KNEE, chosen after examining queue results.')
            for qd in args.tail_qds:
                add(exp, 'randread', 4, qd)
        elif exp == 'working_set':
            for gib in [1, 4, 8]:
                extent = min(gib * GIB, size) if args.smoke else gib * GIB
                for rw in ['randread', 'randwrite']:
                    add(exp, rw, 4, 8, extent=extent, label=f'{gib}GiB' if not args.smoke else f'smoke-range-{gib}')
        elif exp == 'pitfall':
            for direct in [1, 0]:
                add(exp, 'randread', 4, 1, extent=min(size, 256 * 1024 ** 2), direct=direct,
                    label='direct' if direct else 'buffered-warm')
    jobs = []
    for rep in range(1, repeats + 1):
        for row in rows:
            row = dict(row, repetition=rep, seed=202600 + rep, smoke=args.smoke, kind='measurement')
            row['id'] = f'{len(jobs)+1:04d}_{row["experiment"]}_{row["rw"]}_{row["bs_kib"]}k_q{row["qd"]}_r{rep}'
            jobs.append(row)
    return jobs


def safe_directory(value):
    path = Path(value).expanduser().absolute()
    if any(p.is_symlink() for p in [path, *path.parents]):
        raise ValueError('Symlink test directories or parents are not allowed.')
    path = path.resolve()
    forbidden = [Path('/dev'), Path('/mnt'), Path('/proc'), Path('/sys'), Path('/run')]
    if path in [Path('/'), Path.home(), ROOT] or any(path == p or p in path.parents for p in forbidden):
        raise ValueError('Choose a dedicated directory inside Linux ext4, not a device, system directory, or /mnt path.')
    ancestor = path
    while not ancestor.exists():
        ancestor = ancestor.parent
    fs = capture(['findmnt', '-n', '-o', 'FSTYPE', '-T', str(ancestor)])
    if fs != 'ext4':
        raise ValueError(f'Test directory must be on ext4; findmnt reported {fs!r}.')
    return path


def validate_file(state):
    directory = safe_directory(state['directory'])
    marker = directory / '.ssd-project.json'
    if marker.is_symlink() or not marker.is_file():
        raise ValueError('Ownership marker missing or unsafe.')
    current = json.loads(marker.read_text())
    if current['owner'] != str(ROOT) or current['token'] != state['token']:
        raise ValueError('Ownership marker does not match this project/session.')
    target = directory / 'ssd-test.bin'
    info = target.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1 or info.st_ino != current['inode'] or info.st_dev != current['device']:
        raise ValueError('Test file was replaced, linked, or is not a regular file. Refusing I/O.')
    return current, target


def config(row, target):
    options = dict(filename=target, ioengine=row['engine'], direct=row['direct'],
                   rw=row['rw'], bs=f"{row['bs_kib']}k", iodepth=row['qd'], numjobs=1,
                   size=row['size_bytes'], offset=0,allow_file_create=1 if row['kind'] == 'prepare' else 0,fallocate='none',
                   refill_buffers=1, scramble_buffers=1)
    options.update(randrepeat=1, randseed=row['seed'], invalidate=1,
                   lat_percentiles=1, clat_percentiles=1, percentile_list='50:95:99:99.9',
                   exitall_on_error=1, end_fsync=1 if 'write' in row['rw'] or row['rw'] == 'randrw' else 0)
    if row['rw'] == 'randrw':
        options['rwmixread'] = row['read_pct']
    if row['kind'] == 'measurement' or row['kind'] == 'engine_check':
        options.update(time_based=1, runtime=row['runtime'], ramp_time=row['warmup'])
    if row['kind'] == 'cache_warm':
        options['invalidate'] = 0
    if row['label'] == 'buffered-warm':
        options['invalidate'] = 0
    return '[global]\n' + ''.join(f'{k}={v}\n' for k, v in options.items()) + f'\n[{row["id"]}]\n'


def check_json(path, row):
    data = json.loads(path.read_text())
    jobs = data.get('jobs', [])
    if len(jobs) != 1 or jobs[0].get('error', -1) != 0:
        raise ValueError(f'{path}: expected one successful fio job.')
    job = jobs[0]
    if sum(job.get(d, {}).get('io_bytes', 0) for d in ['read', 'write']) <= 0:
        raise ValueError(f'{path}: no completed I/O.')
    if row['kind'] in ['prepare', 'cache_warm']:
        direction = 'write' if row['kind'] == 'prepare' else 'read'
        if job.get(direction, {}).get('io_bytes', 0) < row['size_bytes']:
            raise ValueError('Preparation/warm-read did not cover the complete requested range.')
    if row['qd'] > 1 and row['direct']:
        depth1 = job.get('iodepth_level', {}).get('1')
        if depth1 is None or depth1 > 90:
            raise ValueError(f'{path}: missing depth evidence or >90% depth-1 I/O; asynchronous concurrency not established.')
    return job


def internal(action, session_name, job_id=None):
    session = Path(session_name)
    manifest = json.loads((session / 'manifest.json').read_text())
    if action == '_finish':
        (session / 'COMPLETE').write_text(dt.datetime.now(dt.timezone.utc).isoformat() + '\n')
        return
    row = next(r for r in manifest['jobs'] if r['id'] == job_id)
    state, target = validate_file(manifest['file'])
    if action == '_before':
        if row['kind'] != 'prepare' and (not state['initialized'] or target.stat().st_size < row['size_bytes']):
            raise ValueError('File has not been fully initialized for this range; run prepare first.')
        if shutil.disk_usage(target.parent).free < 2 * GIB:
            raise ValueError('Linux free space fell below 2 GiB; stopping.')
        if (session / 'raw' / f'{job_id}.json').exists():
            raise ValueError('Refusing to overwrite a raw result.')
        with (session / 'events.jsonl').open('a') as stream:
            stream.write(json.dumps({'id': job_id, 'event': 'start', 'utc': dt.datetime.now(dt.timezone.utc).isoformat()}) + '\n')
    elif action == '_after':
        check_json(session / 'raw' / f'{job_id}.json', row)
        if row['kind'] == 'prepare':
            state['initialized'] = True
            state['size_bytes'] = target.stat().st_size
            save(target.parent / '.ssd-project.json', state)
        with (session / 'events.jsonl').open('a') as stream:
            stream.write(json.dumps({'id': job_id, 'event': 'validated', 'utc': dt.datetime.now(dt.timezone.utc).isoformat()}) + '\n')


def main():
    if len(sys.argv) > 1 and sys.argv[1].startswith('_'):
        internal(*sys.argv[1:])
        return
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('experiment', choices=EXPERIMENTS + ['all', 'prepare', 'cleanup'])
    parser.add_argument('--test-dir', default='~/ssd_project/benchmark_data')
    parser.add_argument('--host-free-gib', type=float, help='Recent Windows free GiB on the volume holding the WSL VHDX')
    parser.add_argument('--size-gib', type=int, default=8, choices=range(1, 33))
    parser.add_argument('--runtime', type=int, default=20)
    parser.add_argument('--warmup', type=int, default=3)
    parser.add_argument('--repeats', type=int, default=3)
    parser.add_argument('--engine', choices=['libaio', 'io_uring'], default='libaio')
    parser.add_argument('--tail-qds', type=int, nargs=2, metavar=('MID', 'NEAR_KNEE'))
    parser.add_argument('--smoke', action='store_true', help='64 MiB, 2 seconds, one repetition; not report data')
    parser.add_argument('--plan', action='store_true', help='Print estimates only; no fio or test-file access')
    args = parser.parse_args()
    if args.runtime < 1 or args.warmup < 0 or args.repeats < 1:
        parser.error('runtime/repeats must be positive; warmup must be nonnegative.')
    if args.tail_qds and (len(set(args.tail_qds)) != 2 or any(q < 1 or q > 256 for q in args.tail_qds)):
        parser.error('Choose two distinct tail depths between 1 and 256.')
    jobs = matrix(args)
    size = max([r['size_bytes'] for r in jobs] + [64 * 1024 ** 2 if args.smoke else args.size_gib * GIB])
    measured_seconds = sum(r['runtime'] + r['warmup'] for r in jobs)
    write_seconds = sum(r['runtime'] + r['warmup'] for r in jobs if r['read_pct'] < 100)
    cache_warms = sum(r['label'] == 'buffered-warm' for r in jobs)
    print(f'{len(jobs)} measured runs; {measured_seconds/60:.1f} min timed workload; '
          f'{size/GIB:g} GiB disposable file. Up to 1 full-file preparation, 1 three-second engine check, '
          f'and {cache_warms} cache warm-read runs, plus setup/flush overhead.\n'
          f'Write-active workload time: {write_seconds}s, plus preparation. '
          f'At 1 GiB/s this would issue about {write_seconds + size/GIB:.0f} GiB of logical writes '
          '(illustrative rate, NOT a prediction or write cap). SSD physical writes are unknown.', file=sys.stderr)
    if args.plan:
        for r in jobs:
            print(f"{r['id']} size={r['size_bytes']} read%={r['read_pct']} direct={r['direct']}", file=sys.stderr)
        return
    directory = safe_directory(args.test_dir)
    if any(c in str(directory) for c in '\n\r\t:$;\\'):
        raise ValueError('Test path contains unsupported fio filename punctuation.')
    marker = directory / '.ssd-project.json'
    target = directory / 'ssd-test.bin'
    state = None
    if marker.exists() or marker.is_symlink():
        state = json.loads(marker.read_text())
        state, target = validate_file(state)
        if Path(state['directory']) != directory:
            raise ValueError('Marker belongs to a different directory.')
    elif target.exists() or target.is_symlink():
        raise ValueError('Existing unowned test file: refusing to overwrite it.')
    if args.experiment == 'cleanup':
        if state is None:
            raise ValueError('No owned file to clean up.')
        print(f'Only {target} will be removed. Type DELETE to confirm:', file=sys.stderr)
        if input() != 'DELETE':
            raise ValueError('Cleanup cancelled.')
        validate_file(state)
        target.unlink()
        marker.unlink()
        print('Removed only the owned test file and its marker.', file=sys.stderr)
        return
    if args.host_free_gib is None or not (args.host_free_gib >= size/GIB + 20):
        raise ValueError(f'Provide a recent --host-free-gib value of at least {size/GIB+20:g}; '
                         'check the Windows volume containing this distro VHDX, not WSL df capacity.')
    directory.mkdir(parents=True, exist_ok=True)
    if shutil.disk_usage(directory).free < size + 2 * GIB:
        raise ValueError('Insufficient Linux filesystem free space.')
    version = capture(['/usr/bin/fio', '--version'])
    if not version.startswith('fio-'):
        raise ValueError('Install Flexible I/O Tester: sudo apt install fio (not the Python Fiona CLI).')
    print(f'WARNING: writes may be substantial. Target: {target}\n'
          'This measures the WSL storage path. Close other workloads and monitor host free space.\n'
          'Type the full test directory to authorize this session:', file=sys.stderr)
    if input() != str(directory):
        raise ValueError('Confirmation did not match; no benchmark started.')
    if state is None:
        if any(p.name != '.gitkeep' for p in directory.iterdir()):
            raise ValueError('A new benchmark directory must be empty.')
        fd = os.open(target, os.O_CREAT | os.O_EXCL | os.O_WRONLY | os.O_NOFOLLOW, 0o600)
        os.close(fd)
        info = target.stat()
        state = dict(owner=str(ROOT), directory=str(directory), token=uuid.uuid4().hex,
                     inode=info.st_ino, device=info.st_dev, initialized=False, size_bytes=0)
        save(marker, state)
    need_prepare = not state['initialized'] or target.stat().st_size < size or args.experiment == 'prepare'
    if need_prepare:
        state['initialized'] = False
        save(marker, state)
    base = dict(experiment='setup', rw='write', bs_kib=1024, qd=8, read_pct=0,
                size_bytes=size, direct=1, label='', runtime=3, warmup=0, engine=args.engine,
                numjobs=1, repetition=0, seed=202600, smoke=args.smoke)
    scheduled = []
    if need_prepare:
        scheduled.append(dict(base, id='0000_prepare', kind='prepare'))
    scheduled.append(dict(base, id='0000_engine_check', kind='engine_check', rw='randread',
                          bs_kib=4, qd=8, read_pct=100))
    for row in jobs:
        if row['label'] == 'buffered-warm':
            scheduled.append(dict(row, id=row['id'] + '_warm', kind='cache_warm',
                                  rw='read', bs_kib=128, label='', direct=0))
        scheduled.append(row)
    session = ROOT / 'results' / 'raw' / (dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '_' + args.experiment + '_' + uuid.uuid4().hex[:8])
    (session / 'configs').mkdir(parents=True)
    (session / 'raw').mkdir()
    manifest = dict(format_version=1, arguments=vars(args), file=state, jobs=scheduled)
    save(session / 'manifest.json', manifest)
    commands = {'uname': ['uname', '-a'], 'cpu': ['lscpu'], 'memory': ['free', '-b'],
                'filesystem': ['findmnt', '-T', str(directory)], 'space': ['df', '-B1', str(directory)],
                'python': ['python3', '--version'], 'affinity': ['taskset', '-pc', str(os.getpid())]}
    env = {name: capture(command) for name, command in commands.items()}
    env.update(fio=version, engine=args.engine, host_free_gib_user_reported=args.host_free_gib,
               pinning='No explicit pinning or isolation; record Windows activity manually.',
               temperature='Physical SSD telemetry not collected; WSL virtual disk is not physical SMART.',
               utc=dt.datetime.now(dt.timezone.utc).isoformat())
    for name, path in [('governor', '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'),
                       ('smt', '/sys/devices/system/cpu/smt/active'), ('os', '/etc/os-release')]:
        env[name] = Path(path).read_text().strip() if Path(path).exists() else 'Unavailable'
    for package in ['pandas', 'matplotlib']:
        try:
            env[package] = metadata.version(package)
        except metadata.PackageNotFoundError:
            env[package] = 'Not installed in runner Python environment'
    save(session / 'environment.json', env)
    for row in scheduled:
        jobfile = session / 'configs' / (row['id'] + '.fio')
        jobfile.write_text(config(row, target))
        result = subprocess.run(['/usr/bin/fio', '--parse-only', str(jobfile)], capture_output=True, text=True)
        if result.returncode:
            raise ValueError(f'FIO config rejected: {result.stdout}\n{result.stderr}')
    (session / 'order.txt').write_text(''.join(r['id'] + '\n' for r in scheduled))
    print(session)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, KeyError, StopIteration, EOFError) as exc:
        print(f'ERROR: {exc}', file=sys.stderr)
        sys.exit(1)
