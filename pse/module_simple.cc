#include <pybind11/pybind11.h>

// Simple PSE module that just provides basic functionality
PYBIND11_MODULE(_pse, m) {
    m.doc() = "PSE (Positively Split Ewald) module for HOOMD";
    
    // Add a simple test function
    m.def("test_function", []() {
        return "PSE module loaded successfully!";
    });
    
    // We'll add actual PSE functionality here once the basic module works
}
