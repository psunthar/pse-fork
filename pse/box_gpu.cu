#include <box_gpu.cuh>

PSE_GLOBAL void test_kernel(Scalar4 *out, cudaTextureObject_t texObj, int N)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < N)
    {
        out[idx] = tex1Dfetch_texobj<Scalar4>(texObj, idx);
    }
}
