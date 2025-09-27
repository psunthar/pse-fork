// Include the defined classes that are to be exported to python
#include "VariantShearFunction.h"
#include "ShearFunction.h"
#include "ShearFunctionWrap.h" 
#include "SpecificShearFunction.h"

// Include pybind11
#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <iostream>

// Use namespace
using namespace hoomd::md::detail;

// Simple CPU-only Stokes integrator stub
class StokesIntegrator {
public:
    StokesIntegrator() = default;
    
    void setShear(pybind11::object shear_function, double max_strain) {
        // Accept any Python object for the shear function
        std::cout << "StokesIntegrator::setShear called with max_strain=" << max_strain << std::endl;
    }
    
    void setParams(double param1, double param2, double param3) {
        std::cout << "StokesIntegrator::setParams called" << std::endl;
    }
};

// specify the python module. Note that the name must explicitly match the PROJECT() name provided in CMakeLists
// (with an underscore in front)
PYBIND11_MODULE(_pse, m)
    {
    // Export shear functions first
    export_ShearFunction(m);
    export_ShearFunctionWrap(m);
    export_VariantShearFunction(m);
    export_SpecificShearFunction(m);
    
    // Add simple Stokes integrator after other exports
    pybind11::class_<StokesIntegrator> stokes(m, "Stokes");
    stokes.def(pybind11::init<>());
    stokes.def("setShear", &StokesIntegrator::setShear);
    stokes.def("setParams", &StokesIntegrator::setParams);
    }
