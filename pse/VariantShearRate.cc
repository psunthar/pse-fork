
#include "VariantShearRate.h"

namespace hoomd
    {
//* Trampoline for classes inherited in python

namespace detail
    {

void export_VariantShearRate(pybind11::module& m)
    {

    pybind11::class_<VariantSteadyShearRate, Variant, std::shared_ptr<VariantSteadyShearRate>>(m,
                                                                                 "VariantSteadyShearRate")
        .def(pybind11::init<Scalar>(), pybind11::arg("value"))
        .def_property("value", &VariantSteadyShearRate::getValue, &VariantSteadyShearRate::setValue)
        .def(pybind11::pickle(
            [](const VariantSteadyShearRate& variant) { return pybind11::make_tuple(variant.getValue()); },
            [](pybind11::tuple params) { return VariantSteadyShearRate(params[0].cast<Scalar>()); }));

    }

    } // end namespace detail

    } // end namespace hoomd
