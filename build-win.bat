@echo off

if NOT "%1" == "x64" if NOT "%1" == "x86" if NOT "%1" == "arm64" (
    echo Must specify first argument as x64, x86, or arm64
    goto :error
)
if "%1" == "x64" (
    set arch=x64
    set cmake_gen="Visual Studio 17 2022"
)
if "%1" == "x86" (
    set arch=Win32
    set cmake_gen="Visual Studio 17 2022"
)
if "%1" == "arm64" (
    set arch=ARM64
    set cmake_gen="Visual Studio 17 2022"
)

rd /s /q "build"
cmake -H. -Bbuild -G %cmake_gen% -A %arch%
cmake --build ./build --target secp256k1 --config Release