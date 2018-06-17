#!/bin/bash

case "$1" in
    arm64) ;;
    x86_64) ;;
    *)
        echo 'Specify first arg as either `arm64` or `x86_64`'
        exit 0
    ;;
esac

rm -rf "build"
cmake -H. -Bbuild "-DCMAKE_OSX_ARCHITECTURES=$1"
cmake --build ./build --target secp256k1 --config MinSizeRel