#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
study=${1:-all}
out=${2:-results/$(date -u +%Y%m%dT%H%M%SZ)}
mode=${3:-run}
case "$study" in all|baseline|locality|alignment|stride|dtype|roofline|negative) ;; *) echo 'Unknown study' >&2; exit 1;; esac
case "$mode" in run|--plan) ;; *) echo 'Usage: bash run.sh [all|baseline|locality|alignment|stride|dtype|roofline|negative] [new-output-directory] [--plan]' >&2; exit 1;; esac
if [[ -e "$out" ]]; then echo "Refusing to overwrite $out" >&2; exit 1; fi
mkdir -p "$out"
make -B all > "$out/build.log" 2>&1
make check > "$out/correctness.log" 2>&1
bash verify_simd.sh > "$out/simd-check.log" 2>&1
cp build/*.vec build/*.kernels.asm build/*evidence.txt "$out/"
python3 environment.py "$out/environment.json"
python3 - "$out" "$study" <<'PY'
import csv,json,sys
from pathlib import Path
out=Path(sys.argv[1]); study=sys.argv[2]
c=json.loads((out/'environment.json').read_text())['configuration']
if study in ('all','locality'):
    if not 0 < c['l1_bytes'] <= c['l2_bytes'] <= c['llc_bytes']:
        raise SystemExit('Cache capacities missing/inconsistent: set L1_BYTES, L2_BYTES, LLC_BYTES from your machine documentation. No locality data collected.')
if study in ('all','roofline','negative') and c['llc_bytes'] <= 0:
    raise SystemExit('Set LLC_BYTES to the actual last-level cache capacity for the DRAM studies.')
if study in ('all','roofline','negative') and c['dram_bytes'] < 2*c['llc_bytes']:
    raise SystemExit('DRAM_BYTES must be at least twice LLC_BYTES; prefer >=4x and check available RAM.')
rows=[]; case=0
# Rotate build order by case to reduce systematic ordering bias.
def add(s,k,t,n,offset=0,stride=1):
    global case
    variants=['scalar','auto','native']; shift=case%3
    for build in variants[shift:]+variants[:shift]:
        rows.append([s,build,k,t,max(1,int(n)),offset,stride])
    case+=1
if study in ('all','baseline'):
    for k in ('saxpy','dot','mul'):
        for t in ('f32','f64'):
            b=4 if t=='f32' else 8; arrays=3 if k=='mul' else 2
            for n in sorted(set(c['n_list']+[c['dram_bytes']//(arrays*b)])): add('baseline',k,t,n)
if study in ('all','locality'):
    sizes=sorted({int(cache*factor) for cache in (c['l1_bytes'],c['l2_bytes'],c['llc_bytes'])
                  for factor in (0.5,1,2)} | {c['dram_bytes']})
    for t,b in [('f32',4),('f64',8)]:
        for size in sizes: add('locality','saxpy',t,size//(2*b))
if study in ('all','alignment'):
    for k in ('saxpy','dot','mul'):
        for t,b in [('f32',4),('f64',8)]:
            for base in c['align_n']:
                for tail in (0,1,3):
                    for offset in (0,b): add('alignment',k,t,base+tail,offset)
if study in ('all','stride'):
    for k in ('saxpy','dot','mul'):
        for t in ('f32','f64'):
            for n in c['stride_n']:
                for stride in (1,2,4,8): add('stride',k,t,n,stride=stride)
if study in ('all','dtype'):
    # Equal total active bytes, rather than silently comparing different cache regimes.
    for k in ('saxpy','dot','mul'):
        arrays=3 if k=='mul' else 2
        for size in (max(c['l1_bytes']//2,4096),max(c['l2_bytes']//2,65536),c['dram_bytes']):
            for t,b in [('f32',4),('f64',8)]: add('dtype',k,t,size//(arrays*b))
if study in ('all','roofline','negative'):
    for t,b in [('f32',4),('f64',8)]:
        n=c['dram_bytes']//(2*b)
        # SAXPY is the bandwidth calibration itself: same logical read/read/write traffic as roofline kernel.
        if study in ('all','roofline'):
            add('bandwidth','saxpy',t,n)
            for size in sorted({max(c['l1_bytes']//2,4096),max(c['l2_bytes']//2,65536),c['dram_bytes']}):
                add('roofline','saxpy',t,size//(2*b))
        if study in ('all','negative'): add('negative','saxpy',t,n)
with (out/'plan.csv').open('w') as f:
    w=csv.writer(f,lineterminator='\n')
    w.writerow(['study','build','kernel','dtype','n','offset_bytes','stride']); w.writerows(rows)
print(f'{len(rows)} configurations prepared in {out}/plan.csv')
PY
if [[ "$mode" == --plan ]]; then echo 'Plan only: no timings collected.'; exit 0; fi
mapfile -t config < <(python3 - "$out/environment.json" <<'PY'
import json,sys
m=json.load(open(sys.argv[1])); c=m['configuration']
for v in [c['reps'],c['warmup'],c['batch_elements'],int(c['cycles_requested']),int(m['pinning_active']),m['selected_cpu']]: print(v)
PY
)
prefix=(); if [[ ${config[4]} == 1 ]]; then prefix=(taskset -c "${config[5]}"); fi
extra=(); if [[ ${config[3]} == 1 ]]; then extra=(--cycles); fi
build/scalar --header > "$out/raw.csv"
while IFS=, read -r s build kernel dtype n offset stride; do
    [[ "$s" == study ]] && continue
    echo "$s $build $kernel $dtype N=$n offset=$offset stride=$stride" >&2
    "${prefix[@]}" "build/$build" --study "$s" --kernel "$kernel" --type "$dtype" --n "$n" \
        --offset "$offset" --stride "$stride" --reps "${config[0]}" --warmup "${config[1]}" \
        --batch-elements "${config[2]}" "${extra[@]}" >> "$out/raw.csv"
done < "$out/plan.csv"
python3 environment.py "$out/environment-after.json"
echo "Raw data: $out/raw.csv"
