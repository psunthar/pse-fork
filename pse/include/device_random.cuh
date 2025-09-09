#pragma once

#include "cuda_config.h"
#include "hoomd_utils.h"
#include <curand_kernel.h>

namespace hoomd {
namespace gpu {

// Random number generator
struct RandomGenerator {
    curandState state;
    
    __device__ inline RandomGenerator(unsigned int seed, unsigned int sequence=0) {
        curand_init(seed, sequence, 0, &state);
    }

    __device__ inline float uniform() {
        return curand_uniform(&state);
    }

    __device__ inline float normal() {
        return curand_normal(&state);
    }

    __device__ inline Scalar2 normal2() {
        float x = normal();
        float y = normal();
        return hoomd::make_scalar2(x, y);
    }

    __device__ inline float operator()() {
        return uniform();
    }
};

} // namespace gpu
} // namespace hoomd
