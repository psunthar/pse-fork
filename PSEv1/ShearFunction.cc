// Maintainer: Gang Wang
// Updated to HOOMD2.x compatibility by Andrew M. Fiore

/*! \file ShearFunction.cc
    \brief Defines ShearFunction class and relevant functions
*/

#ifdef WIN32
#pragma warning( push )
#pragma warning( disable : 4103 4244 )
#endif

#include "ShearFunction.h"

using namespace std;

namespace hoomd {
namespace md {
namespace detail {

void export_ShearFunction(pybind11::module& m)
{
    
    pybind11::class_<ShearFunction, std::shared_ptr<ShearFunction> >( m, "ShearFunction" )
    .def(pybind11::init< >())
    .def("getShearRate", &ShearFunction::getShearRate)
    .def("getStrain", &ShearFunction::getStrain)
    .def("getOffset", &ShearFunction::getOffset);

}

} // end namespace detail
} // end namespace md
} // end namespace hoomd

#ifdef WIN32
#pragma warning( pop )
#endif
