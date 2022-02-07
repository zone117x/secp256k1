#!/bin/bash

rm -rf "build"
cmake -H. -Bbuild "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64"
cmake --build ./build --target secp256k1 --config Release