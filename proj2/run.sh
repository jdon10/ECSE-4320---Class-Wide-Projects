set -euo pipefail
cd -- "$(dirname -- "$0")"
usage() {
    echo 'Usage: ./run.sh latency|pattern|knee|working|tlb|pitfall|all [OUTPUT_DIRECTORY]'
    echo 'Overrides: CPU REPS MS WARMUPS SEED PERF MAX_BYTES PATTERN_BYTES KNEE_BYTES PITFALL_SMALL PYTHON'
}
if [[ ${1:-} == --help ]]; then usage; exit 0; fi
suite=${1:-all}
case "$suite" in latency|pattern|knee|working|tlb|pitfall|all) ;; *) usage >&2; exit 1;; esac
out=${2:-data/$(date -u +%Y%m%dT%H%M%S)-$suite}
[[ ! -e "$out" ]] || { echo "Refusing to overwrite $out; choose a new directory." >&2; exit 1; }
make benchmark
CPU=${CPU:-$("${PYTHON:-python3}" -c 'import os; print(min(os.sched_getaffinity(0)))')}
REPS=${REPS:-5}; MS=${MS:-100}; WARMUPS=${WARMUPS:-2}; SEED=${SEED:-42}; PERF=${PERF:-0}
MAX_BYTES=${MAX_BYTES:-268435456}
PATTERN_BYTES=${PATTERN_BYTES:-$MAX_BYTES}; KNEE_BYTES=${KNEE_BYTES:-$MAX_BYTES}
PITFALL_SMALL=${PITFALL_SMALL:-16384}
export CPU REPS MS WARMUPS SEED PERF
common=(--cpu "$CPU" --reps "$REPS" --ms "$MS" --warmups "$WARMUPS" --seed "$SEED")
if [[ $PERF == 1 ]]; then common+=(--perf); elif [[ $PERF != 0 ]]; then echo 'PERF must be 0 or 1' >&2; exit 1; fi
./benchmark "${common[@]}" --size "$MAX_BYTES" --check-only >/dev/null
mkdir -p "$out"
./environment.sh > "$out/environment.txt"
printf '%s\n' "suite=$suite MAX_BYTES=$MAX_BYTES PATTERN_BYTES=$PATTERN_BYTES KNEE_BYTES=$KNEE_BYTES PITFALL_SMALL=$PITFALL_SMALL" > "$out/settings.txt"
./benchmark --header > "$out/raw.csv"
run() {
    printf './benchmark' >> "$out/commands.txt"
    printf ' %q' "${common[@]}" "$@" >> "$out/commands.txt"
    printf '\n' >> "$out/commands.txt"
    echo "Running $*" >&2
    ./benchmark "${common[@]}" "$@" >> "$out/raw.csv"
}
run_suite() {
    case "$1" in
    latency|working)
        local size=4096
        while (( size <= MAX_BYTES )); do
            run --experiment "$1" --size "$size" --stride 64
            size=$((size*2))
        done
        ;;
    pattern)
        for gran in 8 64; do
            for read in 100 0 70 50; do
                for pattern in sequential random; do
                    run --experiment pattern --pattern "$pattern" --size "$PATTERN_BYTES" --stride "$gran" --granularity "$gran" --read "$read"
                done
                for stride in 64 256 1024; do
                    run --experiment pattern --pattern stride --size "$PATTERN_BYTES" --stride "$stride" --granularity "$gran" --read "$read"
                done
            done
        done
        ;;
    knee)
        for intensity in 1 2 4 8 16 32; do
            run --experiment knee --size "$KNEE_BYTES" --intensity "$intensity"
        done
        ;;
    tlb)
        local page_stride
        page_stride=$(getconf PAGESIZE)
        for page in normal huge; do
            local size=65536
            while (( size <= MAX_BYTES )); do
                run --experiment tlb --size "$size" --stride "$page_stride" --pages "$page"
                size=$((size*2))
            done
        done
        ;;
    pitfall)
        for size in "$PITFALL_SMALL" "$MAX_BYTES"; do
            run --experiment pitfall --pattern sequential --size "$size" --stride 8
        done
        ;;
    esac
}
if [[ $suite == all ]]; then
    for item in latency pattern knee tlb pitfall; do run_suite "$item"; done
else
    run_suite "$suite"
fi
printf '\nFinished. Raw rows: %s/raw.csv\nAnalyze with: %s analyze.py %q/raw.csv --out %q\n' "$out" "${PYTHON:-python3}" "$out" "results/$(basename "$out")"
