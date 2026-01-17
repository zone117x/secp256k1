#!/bin/bash
set -e

if [[ $# -eq 0 ]] ; then
    echo 'Specify a target:'
    echo '  Linux (glibc): linux-x64, linux-x86, linux-arm64'
    echo '  Linux (musl):  linux-musl-x64, linux-musl-arm64'
    echo '  Windows:       windows-shared-x64, windows-shared-x86, windows-arm64'
    exit 1
fi

# Map target name to NuGet platform name
case "$1" in
    linux-x64)           PLATFORM="linux-x64" ;;
    linux-x86)           PLATFORM="linux-x86" ;;
    linux-arm64)         PLATFORM="linux-arm64" ;;
    linux-musl-x64)      PLATFORM="linux-musl-x64" ;;
    linux-musl-arm64)    PLATFORM="linux-musl-arm64" ;;
    windows-shared-x64)  PLATFORM="win-x64" ;;
    windows-shared-x86)  PLATFORM="win-x86" ;;
    windows-arm64)       PLATFORM="win-arm64" ;;
    *)
        echo "Unknown target: $1"
        exit 1
        ;;
esac

# Clean up any previous build artifacts
rm -rf build lib/$PLATFORM
rm -f dockcross-$1

# Common cmake flags for NuGet builds
CMAKE_FLAGS="-DSECP256K1_ENABLE_MODULE_RECOVERY=ON \
    -DSECP256K1_BUILD_TESTS=OFF \
    -DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF \
    -DSECP256K1_BUILD_BENCHMARK=OFF \
    -DSECP256K1_BUILD_EXAMPLES=OFF \
    -DCMAKE_BUILD_TYPE=Release"

# Add static linking for MinGW to avoid runtime dependencies
if [[ "$1" == windows-* ]]; then
    CMAKE_FLAGS="$CMAKE_FLAGS -DCMAKE_SHARED_LINKER_FLAGS=-static-libgcc"
fi

# linux-x86 on arm64 hosts needs special handling: bypass entrypoint to avoid
# linux32 syscall which fails under Rosetta emulation on Apple Silicon
if [[ "$1" == "linux-x86" && "$(uname -m)" == "arm64" ]]; then
    docker run --rm --platform linux/amd64 --entrypoint /bin/bash \
        -v "$(pwd)":/work -w /work dockcross/$1 \
        -c "cmake -B build $CMAKE_FLAGS -DCMAKE_C_COMPILER=/usr/bin/i686-linux-gnu-gcc && cmake --build build"
# linux-musl-x64: use Alpine directly (no dockcross image available)
elif [[ "$1" == "linux-musl-x64" ]]; then
    docker run --rm --platform linux/amd64 -v "$(pwd)":/work -w /work alpine:latest sh -c "
        apk add --no-cache gcc musl-dev cmake make &&
        cmake -B build $CMAKE_FLAGS &&
        cmake --build build &&
        mkdir -p lib/linux-musl-x64 &&
        cp build/lib/libsecp256k1.so.6.* lib/linux-musl-x64/libsecp256k1.so &&
        rm -rf build
    "
    SKIP_COPY=1
# linux-musl-arm64: use dockcross with musl
elif [[ "$1" == "linux-musl-arm64" ]]; then
    docker run --rm dockcross/linux-arm64-musl > ./dockcross-linux-arm64-musl
    chmod +x ./dockcross-linux-arm64-musl
    ./dockcross-linux-arm64-musl bash -c "cmake -B build $CMAKE_FLAGS && cmake --build build"
    rm -f ./dockcross-linux-arm64-musl
else
    docker run --rm dockcross/$1 > ./dockcross-$1
    chmod +x ./dockcross-$1
    ./dockcross-$1 bash -c "cmake -B build $CMAKE_FLAGS && cmake --build build"
    rm -f ./dockcross-$1
fi

# Copy and rename versioned library to NuGet package structure
# (skip if already done inside container, e.g., for Alpine builds)
if [[ -z "$SKIP_COPY" ]]; then
    mkdir -p lib/$PLATFORM
    if [[ "$1" == windows-* ]]; then
        cp build/bin/libsecp256k1-*.dll lib/$PLATFORM/secp256k1.dll
    else
        cp build/lib/libsecp256k1.so.6.* lib/$PLATFORM/libsecp256k1.so
    fi
    # Clean up intermediate build artifacts
    rm -rf build
fi

# Validate the built library
echo "=== Validating $PLATFORM ==="

# Check architecture
echo "Architecture:"
file lib/$PLATFORM/* | tee /dev/stderr

case "$1" in
    linux-x64|linux-musl-x64)  file lib/$PLATFORM/* | grep -q "ELF 64-bit.*x86-64" ;;
    linux-x86)                 file lib/$PLATFORM/* | grep -q "ELF 32-bit.*Intel 80386" ;;
    linux-arm64|linux-musl-arm64) file lib/$PLATFORM/* | grep -q "ELF 64-bit.*ARM aarch64" ;;
    windows-shared-x64)        file lib/$PLATFORM/* | grep -q "PE32+.*x86-64" ;;
    windows-shared-x86)        file lib/$PLATFORM/* | grep -q "PE32 executable.*Intel 80386" ;;
    windows-arm64)             file lib/$PLATFORM/* | grep -q "PE32+.*Aarch64" ;;
esac || { echo "ERROR: Architecture mismatch"; exit 1; }

# Check dependencies (no MinGW runtime for Windows, only libc/libm for Linux)
echo "Dependencies:"
if [[ "$1" == windows-* ]]; then
    # Use strings for Windows DLLs (objdump doesn't support all PE formats like ARM64)
    # Filter out the library's own internal name (libsecp256k1-*.dll)
    strings lib/$PLATFORM/*.dll | grep -iE "\.dll$" | grep -vi "libsecp256k1" | sort -u | tee /dev/stderr
    if strings lib/$PLATFORM/*.dll | grep -qiE "libgcc.*\.dll|libwinpthread.*\.dll"; then
        echo "ERROR: Unwanted MinGW runtime dependencies"
        exit 1
    fi
elif [[ "$1" == linux-musl-* ]]; then
    # musl builds should only depend on musl libc, not glibc
    objdump -p lib/$PLATFORM/*.so | grep NEEDED | tee /dev/stderr
    if objdump -p lib/$PLATFORM/*.so | grep NEEDED | grep -qvE "libc\.(so|musl)"; then
        echo "ERROR: Unexpected dependencies for musl build"
        exit 1
    fi
    # Verify it's linked against musl, not glibc
    if readelf -d lib/$PLATFORM/*.so 2>/dev/null | grep -q "libc\.so\.6"; then
        echo "ERROR: musl build is linked against glibc"
        exit 1
    fi
else
    # Use objdump instead of ldd (ldd requires matching architecture)
    objdump -p lib/$PLATFORM/*.so | grep NEEDED | tee /dev/stderr
fi

# Check exported symbols (must have RECOVERY module)
echo "Checking for RECOVERY module symbols:"
if [[ "$1" == windows-* ]]; then
    # Use strings for Windows DLLs (objdump doesn't support all PE formats like ARM64)
    strings lib/$PLATFORM/*.dll | grep "secp256k1_ecdsa_recover" || { echo "ERROR: Missing RECOVERY symbols"; exit 1; }
else
    nm -D lib/$PLATFORM/*.so | grep secp256k1_ecdsa_recover || { echo "ERROR: Missing RECOVERY symbols"; exit 1; }
fi

echo "=== Validation passed for $PLATFORM ==="
