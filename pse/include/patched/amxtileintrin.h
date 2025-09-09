#pragma once

#ifdef __CUDACC__
// Dummy implementations for CUDA compilation
#define __builtin_ia32_ldtilecfg(ptr)
#define __builtin_ia32_sttilecfg(ptr)
#else
#include_next <amxtileintrin.h>
#endif
