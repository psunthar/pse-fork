
// Include the defined classes that are to be exported to python
#include "Stokes.h"
#include <pybind11/pybind11.h>

namespace hoomd {
namespace md {
namespace detail {

// specify the python module. Note that the name must explicitly match 
// the PROJECT() name provided in CMakeLists 
// (with an underscore in front)
PYBIND11_MODULE(_pse, m)
{
#ifdef ENABLE_CUDA
    export_Stokes(m);
#endif
}
} // end namespace detail
} // end namespace md
} // end namespace hoomd

