#!/bin/bash
set -e

# Map architecture to NuGet platform name
case "$1" in
    arm64)  PLATFORM="osx-arm64" ;;
    x86_64) PLATFORM="osx-x64" ;;
    *)
        echo 'Specify first arg as either `arm64` or `x86_64`'
        exit 1
    ;;
esac

# Common cmake flags for NuGet builds
CMAKE_FLAGS="-DSECP256K1_ENABLE_MODULE_RECOVERY=ON \
    -DSECP256K1_BUILD_TESTS=OFF \
    -DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF \
    -DSECP256K1_BUILD_BENCHMARK=OFF \
    -DSECP256K1_BUILD_EXAMPLES=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES=$1"

rm -rf build lib/$PLATFORM
cmake -B build $CMAKE_FLAGS
cmake --build build

# Copy versioned library to NuGet package structure
mkdir -p lib/$PLATFORM
cp build/lib/libsecp256k1.*.dylib lib/$PLATFORM/libsecp256k1.dylib

# Clean up intermediate build artifacts
rm -rf build

# Validate the built library
echo "=== Validating $PLATFORM ==="

# Check architecture
echo "Architecture:"
file lib/$PLATFORM/* | tee /dev/stderr

case "$1" in
    arm64)  file lib/$PLATFORM/* | grep -q "arm64" ;;
    x86_64) file lib/$PLATFORM/* | grep -q "x86_64" ;;
esac || { echo "ERROR: Architecture mismatch"; exit 1; }

# Check dependencies (should only link to system libraries)
echo "Dependencies:"
otool -L lib/$PLATFORM/*.dylib | tee /dev/stderr

# Check exported symbols (must have RECOVERY module)
echo "Checking for RECOVERY module symbols:"
nm -gU lib/$PLATFORM/*.dylib | grep secp256k1_ecdsa_recover || { echo "ERROR: Missing RECOVERY symbols"; exit 1; }

echo "=== Validation passed for $PLATFORM ==="