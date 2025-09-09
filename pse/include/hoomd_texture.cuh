#pragma once

#ifdef __CUDACC__
#define DEVICE __device__
#define HOST_DEVICE __host__ __device__
#else
#define DEVICE
#define HOST_DEVICE
#endif

#include <cuda_runtime.h>
#include <hoomd/HOOMDMath.h>

namespace hoomd {
namespace gpu {

// Texture fetch functions for common types
template<typename T>
DEVICE T tex1Dfetch_texobj(cudaTextureObject_t texObj, int idx)
{
    return tex1Dfetch<T>(texObj, idx);
}

template<>
DEVICE Scalar4 tex1Dfetch_texobj<Scalar4>(cudaTextureObject_t texObj, int idx)
{
    float4 val = tex1Dfetch<float4>(texObj, idx);
    return make_scalar4(val.x, val.y, val.z, val.w);
}

} // namespace gpu
} // namespace hoomd
