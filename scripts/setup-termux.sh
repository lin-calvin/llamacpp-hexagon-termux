#!/data/data/com.termux/files/usr/bin/bash
#
# One-time setup: copy the vendor FastRPC / OpenCL libraries that live on the
# device into this package's own lib/ directory.
#
# Why: the built binaries are normal Android arm64 binaries. libggml-hexagon
# dlopen()s libcdsprpc.so at runtime, and libggml-opencl.so has a hard NEEDED
# on libOpenCL.so. Termux can only resolve those if they are reachable, and the
# safe way is to copy them here instead of putting /vendor/lib64 on
# LD_LIBRARY_PATH (that breaks FastRPC's HAL fallback, see run-termux.sh).
#
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$DIR/lib"
mkdir -p "$DEST"

LIBS="
libcdsprpc.so
vendor.qti.hardware.dsp@1.0.so
vendor.qti.hardware.dsp-V1-ndk.so
libvmmem.so
libOpenCL.so
"

for so in $LIBS; do
  src=""
  for d in /vendor/lib64 /system/lib64 /vendor/lib /system/lib; do
    if [ -f "$d/$so" ]; then src="$d/$so"; break; fi
  done
  if [ -n "$src" ]; then
    cp "$src" "$DEST/$so"
    echo "copied $src"
  else
    echo "WARN: $so not found on this device (Hexagon/OpenCL may not work)"
  fi
done

chmod +x "$DIR"/bin/* 2>/dev/null || true

echo
echo "setup done."
echo "next: ./run-termux.sh llama-bench -m /path/to/model.gguf -dev HTP0 -ngl 99"
