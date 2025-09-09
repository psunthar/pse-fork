#pragma once

#ifdef __CUDACC__
#include "gcc_wrapper.h"
#else
#include <x86intrin.h>
#endif

#include <cuda_runtime.h>
