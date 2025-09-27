cmake_minimum_required(VERSION 3.12)
project(pse)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Python
find_package(Python COMPONENTS Interpreter Development REQUIRED)

# Find pybind11 with explicit path
set(pybind11_DIR "/home/mohit/miniconda3/envs/hoomd-py310/lib/python3.10/site-packages/pybind11/share/cmake/pybind11")
find_package(pybind11 REQUIRED)

# PSE source files - CPU only to avoid CUDA compatibility issues
set(PSE_SOURCES
    pse/module.cc
    pse/VariantShearFunction.cc
    pse/ShearFunctionWrap.cc
    pse/SpecificShearFunction.cc
    pse/ShearFunction.cc
    pse/VariantShearRate.cc
)

# PSE Python module
pybind11_add_module(_pse ${PSE_SOURCES})

# Set module properties
set_property(TARGET _pse PROPERTY CXX_STANDARD 17)

# Add HOOMD include directories
target_include_directories(_pse PRIVATE 
    "/home/mohit/miniconda3/envs/hoomd-py310/lib/python3.10/site-packages/hoomd/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/custom_include"
    "${CMAKE_CURRENT_SOURCE_DIR}/pse"
)

# Add HOOMD defines
target_compile_definitions(_pse PRIVATE
    HOOMD_LONGREAL_SIZE=64
    HOOMD_SHORTREAL_SIZE=32
)
