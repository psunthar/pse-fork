set(pse_SOURCES
    box_gpu.cu
    Stokes.cu)

add_library(pse SHARED ${pse_SOURCES})
