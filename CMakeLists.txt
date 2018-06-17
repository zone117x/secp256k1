# This CMake config file for secp256k1 project from https://github.com/bitcoin-core/secp256k1

cmake_minimum_required(VERSION 3.4)
project(secp256k1 LANGUAGES C)

set(COMMON_COMPILE_FLAGS ENABLE_MODULE_ECDH ENABLE_MODULE_RECOVERY USE_BASIC_CONFIG)

message("CMAKE_OSX_ARCHITECTURES: ${CMAKE_OSX_ARCHITECTURES}")
message("CMAKE_HOST_SYSTEM_PROCESSOR: ${CMAKE_HOST_SYSTEM_PROCESSOR}")
message("CMAKE_SYSTEM_PROCESSOR: ${CMAKE_SYSTEM_PROCESSOR}")
message("CMAKE_CROSSCOMPILING: ${CMAKE_CROSSCOMPILING}")
message("CMAKE_GENERATOR: ${CMAKE_GENERATOR}")
message("CMAKE_GENERATOR_PLATFORM: ${CMAKE_GENERATOR_PLATFORM}")

if (MSVC)
	if("${CMAKE_GENERATOR_PLATFORM}" STREQUAL "ARM64")
		set(PLATFORM_COMPILE_FLAGS SECP256K1_LITTLE_ENDIAN=1)
		message("Windows ARM64 detected, enabling SECP256K1_LITTLE_ENDIAN")
	endif()
	
	set(COMPILE_OPTIONS "")
	set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
	set(CompilerFlags
		CMAKE_CXX_FLAGS
		CMAKE_CXX_FLAGS_DEBUG
		CMAKE_CXX_FLAGS_RELEASE
		CMAKE_CXX_FLAGS_RELWITHDEBINFO
		CMAKE_C_FLAGS
		CMAKE_C_FLAGS_DEBUG
		CMAKE_C_FLAGS_RELEASE
		CMAKE_C_FLAGS_RELWITHDEBINFO
	)
	foreach(CompilerFlag ${CompilerFlags})
		string(REPLACE "/MD" "/MT" ${CompilerFlag} "${${CompilerFlag}}")
	endforeach()
else()
	set(COMPILE_OPTIONS -O3 -DNDEBUG -W -std=c89 -pedantic -Wall -Wextra -Wcast-align -Wnested-externs -Wshadow -Wstrict-prototypes -Wno-unused-function -Wno-long-long -Wno-overlength-strings)
endif()

add_library(secp256k1 SHARED src/precomputed_ecmult_gen.c src/precomputed_ecmult.c src/secp256k1.c)

target_compile_definitions(secp256k1 PRIVATE ECMULT_GEN_PREC_BITS=4)
target_compile_definitions(secp256k1 PRIVATE ECMULT_WINDOW_SIZE=15)

target_compile_definitions(secp256k1 PRIVATE ${COMMON_COMPILE_FLAGS} ${PLATFORM_COMPILE_FLAGS} ${COMPILE_FLAGS})

target_include_directories(secp256k1 PRIVATE ${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/include ${CMAKE_SOURCE_DIR}/src)
target_compile_options(secp256k1 PRIVATE ${COMPILE_OPTIONS})
