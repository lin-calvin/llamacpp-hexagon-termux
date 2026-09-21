#!/data/data/com.termux/files/usr/bin/bash
#
# Run a llama.cpp tool from Termux with the right environment.
#
#   ./run-termux.sh llama-bench -m model.gguf -dev HTP0 -ngl 99
#   ./run-termux.sh llama-cli   -m model.gguf -dev HTP0 -ngl 99 -p "hello"
#
# NOTE: do NOT add /vendor/lib64 to LD_LIBRARY_PATH. On devices where an app
# uid cannot open /dev/fastrpc-cdsp, libcdsprpc.so falls back to the
# vendor.qti.hardware.dsp HAL, and having /vendor/lib64 on LD_LIBRARY_PATH
# makes that service lookup return null. Symptom: "FastRPC capability query
# failed (err 114)" / "failed to open session ... error 0x72".
#
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

export LD_LIBRARY_PATH="$DIR/lib"
export ADSP_LIBRARY_PATH="$DIR/lib"
export GGML_HEXAGON_DEVICES="${GGML_HEXAGON_DEVICES:-HTP0}"

tool="${1:-llama-cli}"
if [ "$#" -gt 0 ]; then shift; fi

exec "$DIR/bin/$tool" "$@"
