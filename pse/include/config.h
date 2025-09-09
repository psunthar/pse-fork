#pragma once

// Declare texture template class for older CUDA versions
#if !defined(__CUDA_ARCH__) || __CUDA_ARCH__ >= 300
    #define TEXTURE_FETCH(a,b) tex1Dfetch(a, b)
#else
    #define TEXTURE_FETCH(a,b) tex1Dfetch(a, b)
#endif

// Define CUDA textures if needed
#if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ < 350)
    template<typename T>
    struct texture {
        T data;
    };
#endif
