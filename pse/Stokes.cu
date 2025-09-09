#include "include/hoomd_texture.cuh"
#include "include/cuda_helpers.cuh"
#include "include/device_memory.cuh"
#include "include/box_gpu.cuh"

namespace hoomd {

// Forward declarations of kernels
__global__ void gpu_stokes_step_one(
    Scalar4* pos,
    const Scalar4* force,
    const detail::BoxDimGPU box,
    cudaTextureObject_t pos_tex,
    cudaTextureObject_t force_tex,
    unsigned int N);

__global__ void gpu_stokes_step_two(
    Scalar4* pos,
    const detail::BoxDimGPU box,
    cudaTextureObject_t pos_tex,
    unsigned int N);

// Kernel implementations
__global__ void gpu_stokes_step_one(
    Scalar4* pos,
    const Scalar4* force,
    const detail::BoxDimGPU box,
    cudaTextureObject_t pos_tex,
    cudaTextureObject_t force_tex,
    unsigned int N)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= N) return;

    // Load position and force using texture fetch
    Scalar4 my_pos = gpu::tex1Dfetch_texobj<Scalar4>(pos_tex, idx);
    Scalar4 my_force = gpu::tex1Dfetch_texobj<Scalar4>(force_tex, idx);
    
    // Update position
    Scalar3 dr = make_scalar3(my_force.x, my_force.y, my_force.z);
    Scalar3 pos_i = make_scalar3(my_pos.x, my_pos.y, my_pos.z);
    pos_i = gpu::scalar3_add(pos_i, dr);
    
    // Wrap with periodic boundary conditions
    int3 image = make_int3(0, 0, 0);
    box.wrap(pos_i, image);
    
    // Store updated position
    pos[idx] = make_scalar4(pos_i.x, pos_i.y, pos_i.z, my_pos.w);
}

__global__ void gpu_stokes_step_two(
    Scalar4* pos,
    const detail::BoxDimGPU box,
    cudaTextureObject_t pos_tex,
    unsigned int N)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= N) return;

    // Load position using texture fetch
    Scalar4 my_pos = gpu::tex1Dfetch_texobj<Scalar4>(pos_tex, idx);
    Scalar3 pos_i = make_scalar3(my_pos.x, my_pos.y, my_pos.z);
    
    // Wrap with periodic boundary conditions
    int3 image = make_int3(0, 0, 0);
    box.wrap(pos_i, image);
    
    // Store wrapped position
    pos[idx] = make_scalar4(pos_i.x, pos_i.y, pos_i.z, my_pos.w);
}

// Host function implementations
void gpu_stokes_update_one(
    Scalar4* pos,
    const Scalar4* force,
    const BoxDim& box,
    unsigned int N)
{
    // Create texture objects
    gpu::TextureObject<Scalar4> pos_tex;
    gpu::TextureObject<Scalar4> force_tex;
    
    pos_tex.bind(pos, N);
    force_tex.bind(force, N);
    
    // Calculate grid and block dimensions
    int block_size = 256;
    int n_blocks = (N + block_size - 1) / block_size;
    
    // Launch kernel
    gpu_stokes_step_one<<<n_blocks, block_size>>>(
        pos,
        force,
        detail::BoxDimGPU(box),
        pos_tex.get(),
        force_tex.get(),
        N);
        
    // Cleanup texture objects
    pos_tex.unbind();
    force_tex.unbind();
}

void gpu_stokes_update_two(
    Scalar4* pos,
    const BoxDim& box,
    unsigned int N)
{
    // Create texture object
    gpu::TextureObject<Scalar4> pos_tex;
    pos_tex.bind(pos, N);
    
    // Calculate grid and block dimensions
    int block_size = 256;
    int n_blocks = (N + block_size - 1) / block_size;
    
    // Launch kernel
    gpu_stokes_step_two<<<n_blocks, block_size>>>(
        pos,
        detail::BoxDimGPU(box),
        pos_tex.get(),
        N);
        
    // Cleanup texture object
    pos_tex.unbind();
}

} // namespace hoomd
