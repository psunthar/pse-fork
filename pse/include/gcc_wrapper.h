#pragma once

#ifdef __CUDACC__
// Provide dummy implementations for AMX intrinsics
__device__ inline void __builtin_ia32_ldtilecfg(void *) {}
__device__ inline void __builtin_ia32_sttilecfg(void *) {}
#endif

#include <x86intrin.h>
