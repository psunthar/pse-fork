// Include the defined classes that are to be exported to python
#include "Stokes.h"
#include "VariantShearFunction.h"
#include "ShearFunction.h"
#include "ShearFunctionWrap.h"
#include "SpecificShearFunction.h"

#include <pybind11/pybind11.h>

namespace hoomd
{
namespace md
{
namespace detail
{

// specify the python module. Note that the name must explicitly match 
// the PROJECT() name provided in CMakeLists 
// (with an underscore in front)
PYBIND11_MODULE(_PSEv1, m)
{
// #ifdef ENABLE_CUDA
#ifdef ENABLE_HIP
export_Stokes(m);
#endif
    export_ShearFunction(m);
    export_ShearFunctionWrap(m);
    export_VariantShearFunction(m);
    export_SpecificShearFunction(m);
}
} // end namespace detail
} // end namespace md
} // end namespace hoomd