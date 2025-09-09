#pragma once

#include "hoomd_texture.cuh"
#include <cuda_runtime.h>

namespace hoomd {
namespace gpu {

// Device functions for vector operations
HOST_DEVICE inline Scalar3 scalar3_add(const Scalar3& a, const Scalar3& b)
{
    return make_scalar3(a.x + b.x, a.y + b.y, a.z + b.z);
}

HOST_DEVICE inline Scalar3 scalar3_mul(Scalar s, const Scalar3& v)
{
    return make_scalar3(s * v.x, s * v.y, s * v.z);
}

} // namespace gpu
} // namespace hoomd
