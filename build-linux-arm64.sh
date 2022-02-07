#!/bin/bash

docker run --rm dockcross/linux-arm64 > ./dockcross-linux-arm64
chmod +x ./dockcross-linux-arm64
./dockcross-linux-arm64 bash -c 'rm -rf "build" && cmake -H. -Bbuild && cmake --build ./build --target secp256k1 --config Release'
