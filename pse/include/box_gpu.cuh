#pragma once

#include "hoomd_texture.cuh"
#include <hoomd/BoxDim.h>

namespace hoomd {
namespace detail {

class BoxDimGPU {
public:
    HOST_DEVICE BoxDimGPU() = default;
    BoxDimGPU(const BoxDim& box);

    HOST_DEVICE const Scalar3& getLo() const { return lo; }
    HOST_DEVICE const Scalar3& getHi() const { return hi; }
    HOST_DEVICE const Scalar3& getL() const { return L; }
    HOST_DEVICE const int3& getPeriodic() const { return periodic; }

    HOST_DEVICE void wrap(Scalar3& pos, int3& img) const
    {
        // Wrap coordinates according to periodic boundary conditions
        if (periodic.x)
        {
            if (pos.x >= hi.x)
            {
                pos.x -= L.x;
                img.x++;
            }
            else if (pos.x < lo.x)
            {
                pos.x += L.x;
                img.x--;
            }
        }

        if (periodic.y)
        {
            if (pos.y >= hi.y)
            {
                pos.y -= L.y;
                img.y++;
            }
            else if (pos.y < lo.y)
            {
                pos.y += L.y;
                img.y--;
            }
        }

        if (periodic.z)
        {
            if (pos.z >= hi.z)
            {
                pos.z -= L.z;
                img.z++;
            }
            else if (pos.z < lo.z)
            {
                pos.z += L.z;
                img.z--;
            }
        }
    }

private:
    Scalar3 lo;
    Scalar3 hi;
    int3 periodic;
    Scalar3 L;
};

} // namespace detail
} // namespace hoomd
