# llamacpp-hexagon-termux

Cloud-built (GitHub Actions) **arm64 Android** llama.cpp with the **Hexagon NPU
(HTP)** and **Adreno OpenCL** backends, packaged to run from **Termux** on
Snapdragon phones.

The build uses Qualcomm's own public cross-compilation toolchain image
(`ghcr.io/snapdragon-toolchain/arm64-android`) exactly like the upstream
[Snapdragon backend docs](https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/snapdragon/README.md),
so no local Docker / NDK / Hexagon SDK is needed.

## Download

Grab `llama.cpp-snapdragon-android.tar.xz` from the rolling
[`latest` release](../../releases/tag/latest). Verify with `sha256sums.txt`.

```bash
# in Termux
pkg install -y wget tar xz-utils
wget https://github.com/lin-calvin/llamacpp-hexagon-termux/releases/download/latest/llama.cpp-snapdragon-android.tar.xz
tar -xJf llama.cpp-snapdragon-android.tar.xz
cd llama-hexagon
./setup-termux.sh
```

## Run

```bash
cd llama-hexagon
./run-termux.sh llama-bench -m /sdcard/models/Llama-3.2-1B-Instruct-Q4_0.gguf -dev HTP0 -ngl 99 -p 32 -n 8
./run-termux.sh llama-cli   -m /sdcard/models/Llama-3.2-1B-Instruct-Q4_0.gguf -dev HTP0 -ngl 99 -p "hello"
```

`run-termux.sh` sets `LD_LIBRARY_PATH=$PWD/lib ADSP_LIBRARY_PATH=$PWD/lib
GGML_HEXAGON_DEVICES=HTP0` and dispatches to `bin/<tool>`.

## Why the helper scripts

Two things that are easy to get wrong on Android/Termux:

1. **Never put `/vendor/lib64` on `LD_LIBRARY_PATH`.** On devices where an app
   uid cannot open `/dev/fastrpc-cdsp`, `libcdsprpc.so` must fall back to the
   `vendor.qti.hardware.dsp` HAL. With `/vendor/lib64` on the path that lookup
   returns null and the session fails with `err 114` / `error 0x72`.
   `setup-termux.sh` copies the needed vendor libs into the package `lib/`
   instead.
2. **`libc++_shared.so` must ship with the package** (it is copied out of the
   NDK during the CI build), otherwise the binaries won't start under Termux.

## How the build works

`.github/workflows/build.yml`:

1. `ubuntu-latest` runner, frees disk space.
2. Checks out `ggml-org/llama.cpp` (default `master`, override via
   `workflow_dispatch`).
3. `docker pull ghcr.io/snapdragon-toolchain/arm64-android:v0.7` and runs
   `cmake --preset arm64-android-snapdragon-release` inside it.
4. Installs to `pkg/llama-hexagon`, adds `libc++_shared.so`, strips host
   binaries, drops `test-*`, bundles the Termux scripts.
5. Uploads the artifact and refreshes the rolling `latest` release.

Triggers: push to `main`, manual `workflow_dispatch`, weekly cron.

## Caveats

- **Hexagon needs an unlocked/unsigned PD.** Whether the DSP accepts the
  unsigned shared object is a property of your device/firmware, not of this
  build. Some retail devices refuse (`createUnsignedPD ... not supported`).
- The `libggml-htp-v73/v75/v79/v81.so` skels are built for all four DSP arch
  versions; only the one matching your SoC is used at runtime.
- This is experimental upstream code. Credit for the Termux specifics goes to
  the reporter of [llama.cpp#27677](https://github.com/ggml-org/llama.cpp/issues/27677).
