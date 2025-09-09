#include "include/hoomd_utils.h"
#include "include/box_gpu.cuh"
#include <cuda_runtime.h>

namespace hoomd {

// GPU texture type
typedef unsigned int gpu_texture_t;

// Forward declarations of kernels
__global__ void gpu_stokes_mobility_kernel(
    const Scalar4* pos,
    Scalar4* forces,
    const detail::BoxDimGPU box,
    const Scalar4* pos_data,
    const Scalar4* forces_data,
    unsigned int N);

// Kernel implementation
__global__ void gpu_stokes_mobility_kernel(
    const Scalar4* pos,
    Scalar4* forces,
    const detail::BoxDimGPU box,
    const Scalar4* pos_data,
    const Scalar4* forces_data,
    unsigned int N)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= N) return;

    // Load position data
    Scalar4 my_pos = pos[idx];
    Scalar3 pos_i = make_scalar3(my_pos.x, my_pos.y, my_pos.z);
    
    // Initialize force accumulator
    Scalar3 force = make_scalar3(0.0f, 0.0f, 0.0f);
    
    // Loop over other particles for interactions
    for (int j = 0; j < N; j++)
    {
        if (j != idx)
        {
            // Load other particle position
            Scalar4 other_pos = pos[j];
            Scalar4 other_force = forces[j];
            Scalar3 pos_j = make_scalar3(other_pos.x, other_pos.y, other_pos.z);
            Scalar3 force_j = make_scalar3(other_force.x, other_force.y, other_force.z);
            
            // Calculate separation vector with periodic BC
            Scalar3 dx = pos_j - pos_i;
            int3 image = make_int3(0, 0, 0);
            box.wrap(dx, image);
            
            // Compute mobility tensor contribution
            Scalar r = sqrtf(dot(dx, dx));
            if (r > 0.0f)
            {
                Scalar mobility = 1.0f / (8.0f * M_PI * r);
                force += mobility * force_j;
            }
        }
    }
    
    // Store result
    forces[idx] = make_scalar4(force.x, force.y, force.z, 0.0f);
}

// Launch GPU kernel
void gpu_stokes_mobility(
    const Scalar4* pos,
    Scalar4* forces,
    const BoxDim& box,
    unsigned int N)
{    
    // Calculate grid and block dimensions
    int block_size = 256;
    int n_blocks = (N + block_size - 1) / block_size;
    
    // Launch kernel
    gpu_stokes_mobility_kernel<<<n_blocks, block_size>>>(
        pos,
        forces,
        detail::BoxDimGPU(box),
        pos,
        forces,
        N);
}

} // namespace hoomd
