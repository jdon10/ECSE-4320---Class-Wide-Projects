#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v objdump >/dev/null || { echo 'Install binutils for objdump.' >&2; exit 1; }
python3 - <<'PY'
from pathlib import Path
import os,re,subprocess
source=Path('bench.cpp').read_text().splitlines()
last=next(i for i,s in enumerate(source,1) if '// Independent scalar' in s)
failed=False
for build in ('scalar','auto','native'):
    dump=subprocess.check_output(['objdump','-d','-C','--no-show-raw-insn',f'build/{build}'],text=True)
    funcs={}; current=None
    for line in dump.splitlines():
        header=re.match(r'^[0-9a-f]+ <(.*)>:$',line)
        if header:
            name=header[1]
            current=name if re.match(r'(float|double) (saxpy|dot|mul)<',name) else None
            if current: funcs[current]=[line]
        elif current: funcs[current].append(line)
    if len(funcs)!=6:
        raise SystemExit(f'{build}: expected six named kernel functions, found {len(funcs)}; inspect symbols')
    Path(f'build/{build}.kernels.asm').write_text('\n'.join('\n'.join(v) for v in funcs.values())+'\n')
    evidence=[]
    report=Path(f'build/{build}.vec').read_text()
    evidence += ['Kernel-only GCC loop reports:']
    for line in report.splitlines():
        loc=re.match(r'bench.cpp:(\d+):',line)
        if loc and int(loc[1])<last and ('optimized:' in line or 'missed: couldn\'t vectorize loop' in line):
            evidence.append(line)
    for name,lines in funcs.items():
        # Packed x86 FP arithmetic or AArch64 vector FP arithmetic, not mere xmm register use.
        packed=[s for s in lines if re.search(r'\b(?:v?(?:mul|add|sub|fmadd\d*|fmsub\d*))(?:ps|pd)\b',s)
                or re.search(r'\b(?:fmla|fmul|fadd)\s+v\d+\.[24][sd]',s)]
        evidence.append(f'\n{name}\n  packed arithmetic instructions: {len(packed)}')
        if build=='scalar' and packed:
            failed=True; evidence.append('  ERROR: packed arithmetic in scalar kernel')
        if build!='scalar' and not packed:
            evidence.append('  WARNING: no recognized packed arithmetic; inspect compiler report and assembly manually')
        # A few representative instructions; full targeted functions are in .kernels.asm.
        samples=[]
        for s in packed:
            key=re.sub(r'^.*?:\s*','',s).split()[0]
            regs=re.findall(r'\b(?:xmm|ymm|zmm)\d+|v\d+\.[24][sd]',s)
            signature=(key,tuple(re.sub(r'\d+','',r) for r in regs))
            if signature not in [x[0] for x in samples]: samples.append((signature,s))
        evidence.extend(s for _,s in samples[:4])
    text='\n'.join(evidence)+'\n'
    Path(f'build/{build}.evidence.txt').write_text(text)
    print(text)
# Check the effective GCC scalar switches, using exactly the Makefile's flags.
flags=subprocess.check_output(['make','--no-print-directory','flags'],text=True)
settings=dict(s.split('=',1) for s in flags.splitlines() if '=' in s)
cmd=[settings['CXX']]+settings['COMMON'].split()+settings['SCALAR'].split()+['-Q','--help=optimizers']
p=subprocess.run(cmd,text=True,capture_output=True,check=True)
selected=[line for line in p.stdout.splitlines() if re.search(r'-ftree-(loop|slp)-vectorize\s',line)]
Path('build/scalar-flags.evidence.txt').write_text(' '.join(cmd)+'\n'+'\n'.join(selected)+'\n')
if len(selected)!=2 or any('[disabled]' not in s for s in selected):
    raise SystemExit('Scalar vectorization flags did not verify as disabled')
print('\n'.join(selected))
if failed: raise SystemExit('Scalar verification failed')
PY
