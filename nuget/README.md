# Secp256k1.Native

This package contains platform-specific native shared library builds of [secp256k1](https://github.com/bitcoin-core/secp256k1), an optimized C library for ECDSA signatures and secret/public key operations on curve secp256k1.

This package is built from a [fork](https://github.com/zone117x/secp256k1) of the upstream bitcoin-core/secp256k1 repository. The fork exists solely to build native shared libraries for the various platforms and architectures supported by .NET, and publish them as a NuGet package for .NET projects to consume.

## Included Platforms

- **Windows**: x64, x86, arm64
- **Linux**: x64, x86, arm64
- **Linux (musl/Alpine)**: x64, arm64
- **macOS**: x64, arm64 (Apple Silicon)

## Usage

This package is a dependency for [Secp256k1.Net](https://www.nuget.org/packages/Secp256k1.Net), a .NET wrapper library that provides a managed C# API for secp256k1 functionality.

The native libraries are placed in the `runtimes/{rid}/native/` folder structure and will be automatically copied to the output directory based on your target runtime.

## License

This package contains builds of secp256k1, which is licensed under the MIT License. See the LICENSE file for details.

## Source

The secp256k1 library is maintained by the Bitcoin Core project: https://github.com/bitcoin-core/secp256k1
