#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo 'specify a dockcross image'
    exit 0
fi

docker run --rm dockcross/$1 > ./dockcross-$1
chmod +x ./dockcross-$1
./dockcross-$1 bash -c 'rm -rf "build" && cmake -H. -Bbuild && cmake --build ./build --target secp256k1 --config MinSizeRel'