# Maintainer: Andrew M. Fiore

set(COMPONENT_NAME PSEv1)

# Check that the HOOMD build configuration supports plugin dependencies
if(NOT BUILD_MD)
    message(WARNING "The HOOMD build configuration does not support MD. Skipping build of "
            "plugin component ${COMPONENT_NAME}.")
    return()
endif()

# Specify any C++ sources
set(_${COMPONENT_NAME}_sources
    module.cc
    Stokes.cc
    ShearFunction.cc
    ShearFunctionWrap.cc
    SpecificShearFunction.cc
    VariantShearFunction.cc
    )

# Specify any CUDA sources
set(_${COMPONENT_NAME}_cu_sources
    Stokes.cu
    Brownian.cu
    Helper.cu
    Mobility.cu
    )

if (ENABLE_HIP)
    set(_cuda_sources ${_${COMPONENT_NAME}_cu_sources})
endif (ENABLE_HIP)

# https://hoomd-blue.readthedocs.io/en/v4.4.0/migrating.html
# Deprecated in HOOMD v3
#if (ENABLE_CUDA)
#CUDA_COMPILE(_CUDA_GENERATED_FILES ${_${COMPONENT_NAME}_cu_sources} OPTIONS ${CUDA_ADDITIONAL_OPTIONS} SHARED)
#endif (ENABLE_CUDA)

pybind11_add_module(_${COMPONENT_NAME} SHARED ${_${COMPONENT_NAME}_sources} ${_cuda_sources} NO_EXTRAS)
#pybind11_add_module(_${COMPONENT_NAME} SHARED ${_${COMPONENT_NAME}_sources} ${_CUDA_GENERATED_FILES} NO_EXTRAS)

if (APPLE)
set_target_properties(_${COMPONENT_NAME} PROPERTIES INSTALL_RPATH "@loader_path/..;@loader_path")
else()
set_target_properties(_${COMPONENT_NAME} PROPERTIES INSTALL_RPATH "\$ORIGIN/..;\$ORIGIN")
endif()

#q Find additional libraries to be linked for the plugin
find_library( LAPACKE_LIBRARIES lapacke PATHS /usr/local/lapack-3.6.0/lib/ )
find_library( LAPACK_LIBRARIES lapack PATHS /usr/local/lapack-3.6.0/lib/ )
find_library( BLAS_LIBRARIES blas PATHS /usr/local/lapack-3.6.0/lib/ )
find_library( CBLAS_LIBRARIES cblas PATHS /usr/local/lapack-3.6.0/lib/ )
if( LAPACKE_LIBRARIES-NOTFOUND )
        message(FATAL_ERROR "lapacke libraries not found")
endif( LAPACKE_LIBRARIES-NOTFOUND )
message(STATUS  "found lapacke libraries: ${LAPACKE_LIBRARIES}")
if( LAPACK_LIBRARIES-NOTFOUND )
        message(FATAL_ERROR "lapack libraries not found")
endif( LAPACK_LIBRARIES-NOTFOUND )
message(STATUS  "found lapack libraries: ${LAPACK_LIBRARIES}")
set( LAPACK_LIBRARIES ${LAPACKE_LIBRARIES} ${LAPACK_LIBRARIES} ${CBLAS_LIBRARIES}  ${BLAS_LIBRARIES} )

# Link the library to its dependencies. Add or remove HOOMD extension modules (and/or external C++
# libraries) as needed.
target_link_libraries(_${COMPONENT_NAME}
                      PUBLIC HOOMD::_hoomd
                      PUBLIC HOOMD::_md
                      PUBLIC ${LAPACK_LIBRARIES}
                      )
# target_link_libraries(_${COMPONENT_NAME} PRIVATE ${HOOMD_LIBRARIES} ${LAPACK_LIBRARIES})

# if we are compiling with MPI support built in, set appropriate
# compiler/linker flags
if (ENABLE_MPI)
   if(MPI_COMPILE_FLAGS)
       set_target_properties(_${COMPONENT_NAME} PROPERTIES COMPILE_FLAGS "${MPI_CXX_COMPILE_FLAGS}")
   endif(MPI_COMPILE_FLAGS)
   if(MPI_LINK_FLAGS)
       set_target_properties(_${COMPONENT_NAME} PROPERTIES LINK_FLAGS "${MPI_CXX_LINK_FLAGS}")
   endif(MPI_LINK_FLAGS)
endif(ENABLE_MPI)

# Deprecated in HOOMD v4 (see migration doc)
# fix_cudart_rpath(_${COMPONENT_NAME})

# Install the library.
install(TARGETS _${COMPONENT_NAME}
        LIBRARY DESTINATION ${PYTHON_SITE_INSTALL_DIR}/${COMPONENT_NAME}
        )

################ Python only modules
# Copy python modules to the build directory to make it a working python package. Any files that
# should be copied to the install directory should be listed here.
set(files
    __init__.py
    integrate.py
    shear_function.py
    variant.py
    )

install(FILES ${files}
        DESTINATION ${PYTHON_SITE_INSTALL_DIR}/${COMPONENT_NAME}
       )

copy_files_to_build("${files}" "${COMPONENT_NAME}" "*.py")

# Python tests.
#add_subdirectory(pytest)