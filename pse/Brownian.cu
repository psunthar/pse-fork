#include <cuda_runtime.h>
#include "include/device_random.cuh"
#include "include/box_gpu.cuh"

namespace hoomd {
namespace kernel {

__global__ void gpu_stokes_BrownianGenerate_kernel(
    Scalar4* d_pos,
    const BoxDimGPU box,
    unsigned int seed,
    unsigned int timestep,
    unsigned int N)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= N) return;

    // Initialize RNG for this thread
    gpu::RandomGenerator rng(seed + timestep, idx);

    // Generate random displacement
    Scalar dx = rng.uniform() * 2.0f - 1.0f;  // Convert to [-1, 1]
    Scalar dy = rng.uniform() * 2.0f - 1.0f;
    Scalar dz = rng.uniform() * 2.0f - 1.0f;

    // Store result
    d_pos[idx] = make_scalar4(dx, dy, dz, 0.0f);
}

__global__ void gpu_stokes_BrownianGridGenerate_kernel(
    Scalar2* d_gridpos,
    const BoxDimGPU box,
    unsigned int seed,
    unsigned int timestep,
    unsigned int Nx,
    unsigned int Ny,
    unsigned int Nz)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= Nx * Ny * Nz) return;

    // Initialize RNG for this thread
    gpu::RandomGenerator rng(seed + timestep, idx);

    // Calculate grid position
    unsigned int iz = idx / (Nx * Ny);
    unsigned int iy = (idx - iz * Nx * Ny) / Nx;
    unsigned int ix = idx - iz * Nx * Ny - iy * Nx;

    // Calculate box dimensions
    Scalar3 L = box.getL();
    Scalar dx = L.x / Scalar(Nx);
    Scalar dy = L.y / Scalar(Ny);
    Scalar dz = L.z / Scalar(Nz);

    // Calculate grid point coordinates
    Scalar x = -L.x/2.0f + (ix + 0.5f) * dx;
    Scalar y = -L.y/2.0f + (iy + 0.5f) * dy;
    Scalar z = -L.z/2.0f + (iz + 0.5f) * dz;

    // Store each component with random displacement
    d_gridpos[idx + 0 * Nx * Ny * Nz] = make_scalar2(x, rng.uniform() * 2.0f - 1.0f);
    d_gridpos[idx + 1 * Nx * Ny * Nz] = make_scalar2(y, rng.uniform() * 2.0f - 1.0f);
    d_gridpos[idx + 2 * Nx * Ny * Nz] = make_scalar2(z, rng.uniform() * 2.0f - 1.0f);
}

} // namespace kernel

// Host function to launch kernels
void gpu_stokes_brownian_generate(
    Scalar4* d_pos,
    const BoxDim& box,
    unsigned int seed,
    unsigned int timestep,
    unsigned int N)
{
    int block_size = 256;
    int n_blocks = (N + block_size - 1) / block_size;

    kernel::gpu_stokes_BrownianGenerate_kernel<<<n_blocks, block_size>>>(
        d_pos,
        detail::BoxDimGPU(box),
        seed,
        timestep,
        N);
}

void gpu_stokes_brownian_grid_generate(
    Scalar2* d_gridpos,
    const BoxDim& box,
    unsigned int seed,
    unsigned int timestep,
    unsigned int Nx,
    unsigned int Ny,
    unsigned int Nz)
{
    int block_size = 256;
    int n_blocks = (Nx * Ny * Nz + block_size - 1) / block_size;

    kernel::gpu_stokes_BrownianGridGenerate_kernel<<<n_blocks, block_size>>>(
        d_gridpos,
        detail::BoxDimGPU(box),
        seed,
        timestep,
        Nx,
        Ny,
        Nz);
}

} // namespace hoomd
