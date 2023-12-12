# From CMakeLists.txt template for building a plugin as an external component.

CMAKE_MINIMUM_REQUIRED(VERSION 3.9 FATAL_ERROR)

# Name the plugin project
project(PSEv1 LANGUAGES C CXX)

# Find the installed HOOMD
find_package(HOOMD 4.0.0 REQUIRED)

message(STATUS "Found HOOMD ${HOOMD_VERSION}: ${HOOMD_INSTALL_PREFIX}/${PYTHON_SITE_INSTALL_DIR}")

# Force installation to the HOOMD installation location
set(CMAKE_INSTALL_PREFIX ${HOOMD_INSTALL_PREFIX} CACHE PATH "Installation prefix" FORCE)

message(STATUS "CMake Install prefix: ${CMAKE_INSTALL_PREFIX}")

# Enable compiler warnings on gcc and clang (common compilers used by developers)
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wconversion -Wno-sign-conversion -Wno-unknown-pragmas -Wno-deprecated-declarations -Wno-unused-result")
endif()

# Add subdirectories
add_subdirectory(${PROJECT_NAME})


# ==========================
#set(CMAKE_C_COMPILER "gcc-6")
#set(CMAKE_CXX_COMPILER "g++-6")

#project(PSEv1)
#CMAKE_MINIMUM_REQUIRED(VERSION 2.6.2 FATAL_ERROR)

#set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_MODULE_PATH})

#include(FindHOOMD.cmake)

# plugins must be built as shared libraries
#if (ENABLE_STATIC)
#    message(SEND_ERROR "Plugins cannot be built against a statically compiled hoomd")
#endif (ENABLE_STATIC)

#set(BUILD_SHARED_LIBS on)

#if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
#  set(CMAKE_INSTALL_PREFIX ${HOOMD_ROOT} CACHE PATH "Installation prefix" FORCE)
#endif(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

#set(PYTHON_MODULE_BASE_DIR ${CMAKE_INSTALL_PREFIX})
#message(STATUS "Install plugin to: " ${PYTHON_MODULE_BASE_DIR})

# add subdirectories
#add_subdirectory(${PROJECT_NAME})
