#pragma once

#include <cuda_runtime.h>
#include <stdexcept>

namespace hoomd {
namespace gpu {

template<typename T>
class DeviceMemory {
public:
    DeviceMemory() : m_data(nullptr), m_size(0) {}

    DeviceMemory(size_t size) : m_data(nullptr), m_size(size)
    {
        if (size > 0)
            allocate();
    }

    ~DeviceMemory()
    {
        free();
    }

    // No copy constructor or assignment
    DeviceMemory(const DeviceMemory&) = delete;
    DeviceMemory& operator=(const DeviceMemory&) = delete;

    // Move constructor and assignment
    DeviceMemory(DeviceMemory&& other) noexcept
        : m_data(other.m_data), m_size(other.m_size)
    {
        other.m_data = nullptr;
        other.m_size = 0;
    }

    DeviceMemory& operator=(DeviceMemory&& other) noexcept
    {
        if (this != &other)
        {
            free();
            m_data = other.m_data;
            m_size = other.m_size;
            other.m_data = nullptr;
            other.m_size = 0;
        }
        return *this;
    }

    void allocate(size_t size)
    {
        m_size = size;
        allocate();
    }

    void free()
    {
        if (m_data)
        {
            cudaFree(m_data);
            m_data = nullptr;
        }
        m_size = 0;
    }

    T* get() const { return m_data; }
    size_t size() const { return m_size; }

private:
    void allocate()
    {
        if (m_size > 0)
        {
            cudaError_t err = cudaMalloc((void**)&m_data, m_size * sizeof(T));
            if (err != cudaSuccess)
            {
                throw std::runtime_error("Failed to allocate device memory");
            }
        }
    }

    T* m_data;
    size_t m_size;
};

template<typename T>
class TextureObject {
public:
    TextureObject() : m_tex(0) {}
    ~TextureObject() { unbind(); }

    void bind(const T* data, size_t size)
    {
        // Create resource descriptor
        cudaResourceDesc resDesc = {};
        resDesc.resType = cudaResourceTypeLinear;
        resDesc.res.linear.devPtr = const_cast<T*>(data);
        resDesc.res.linear.desc = cudaCreateChannelDesc<T>();
        resDesc.res.linear.sizeInBytes = size * sizeof(T);

        // Create texture descriptor
        cudaTextureDesc texDesc = {};
        texDesc.addressMode[0] = cudaAddressModeClamp;
        texDesc.filterMode = cudaFilterModePoint;
        texDesc.readMode = cudaReadModeElementType;
        texDesc.normalizedCoords = 0;

        // Create texture object
        cudaCreateTextureObject(&m_tex, &resDesc, &texDesc, nullptr);
    }

    void unbind()
    {
        if (m_tex)
        {
            cudaDestroyTextureObject(m_tex);
            m_tex = 0;
        }
    }

    cudaTextureObject_t get() const { return m_tex; }

private:
    cudaTextureObject_t m_tex;
};

} // namespace gpu
} // namespace hoomd
