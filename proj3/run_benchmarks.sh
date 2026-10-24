set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
exec 9>.run.lock
flock -n 9 || { echo 'Another project runner is active.' >&2; exit 1; }
session=$(python3 experiments.py "$@")
[[ -n "$session" ]] || exit 0
while IFS= read -r job; do
    python3 experiments.py _before "$session" "$job"
    echo "Running $job" >&2
    if ! /usr/bin/fio "$session/configs/$job.fio" --output-format=json \
        --output="$session/raw/$job.json" 2>"$session/raw/$job.stderr"; then
        echo "FIO failed: inspect $session/raw/$job.stderr and JSON. Stopping." >&2
        exit 1
    fi
    python3 experiments.py _after "$session" "$job"
done < "$session/order.txt"
python3 experiments.py _finish "$session"
echo "Saved session: $session"
