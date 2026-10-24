import itertools
from pathlib import Path
import subprocess


def check(binary, kernel, dtype, n, stride, offset):
    subprocess.run([str(binary), '--kernel', kernel, '--type', dtype, '--n', str(n),
                    '--stride', str(stride), '--offset', str(offset), '--check-only'], check=True)


if __name__ == '__main__':
    total = 0
    binaries = [Path('build')/name for name in ('scalar','auto','native')]
    for binary, kernel, dtype, n, stride in itertools.product(
            binaries, ('saxpy','dot','mul'), ('f32','f64'), (1,3,17,65,257,4097), (1,2,4,8)):
        size = 4 if dtype=='f32' else 8
        for offset in (0,size,64-size):
            check(binary,kernel,dtype,n,stride,offset)
            total += 1
    for binary, dtype in itertools.product(binaries, ('f32','f64')):
        check(binary,'dot',dtype,1048583,1,0)
        total += 1
    invalid = [('--n','0'),('--n','-1'),('--n','18446744073709551615'),('--offset','1'),
               ('--offset','64'),('--stride','3'),('--type','bad'),('--kernel','bad'),
               ('--reps','0'),('--batch-elements','0'),('--study','a,b'),('--n','3x')]
    for args in invalid:
        p=subprocess.run(['build/scalar',*args,'--check-only'],text=True,capture_output=True)
        if p.returncode==0:
            raise SystemExit(f'Invalid arguments accepted: {args}')
    p=subprocess.run(['build/auto','--type','f64','--offset','4','--check-only'],capture_output=True)
    assert p.returncode!=0
    print(f'PASS: {total} reference/guard cases plus {len(invalid)+1} invalid-argument cases. No timings collected.')
