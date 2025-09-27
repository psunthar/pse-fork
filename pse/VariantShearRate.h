#pragma once

#include <cstdint>
#include <pybind11/pybind11.h>
#include <utility>

#include "hoomd/HOOMDMath.h"
#include "hoomd/Variant.h"

namespace hoomd
    {
/** Defines shear rate functions that vary with time steps.
*/
class VariantShearRate : public Variant {
    public:
    virtual ~VariantShearRate() = default;
    
    // Implement pure virtual functions from Variant base class
    virtual Scalar min() override { return Scalar(0); }
    virtual Scalar max() override { return Scalar(1); }
    
    // Pure virtual function to be implemented by derived classes
    virtual Scalar operator()(uint64_t timestep) = 0;
};

/** Constant value

    Variant that provides a constant value.
*/
class VariantSteadyShearRate : public VariantShearRate
    {
    public:
    /** Construct a VariantSteadyShearRate.

        @param value The value.
    */
    VariantSteadyShearRate(Scalar value) : m_value(value) { }

    /// Return the value.
    Scalar operator()(uint64_t timestep) override
        {
        return m_value;
        }

    /// Return the value
    Scalar getValue() const { return m_value; }
    
    /// Set the value
    void setValue(Scalar value) { m_value = value; }
    
    // Implement min/max based on the constant value
    Scalar min() override { return m_value; }
    Scalar max() override { return m_value; }

    private:
    Scalar m_value;
    };

namespace detail
    {
/** Export VariantShearRate to Python
*/
void export_VariantShearRate(pybind11::module& m);
    } // end namespace detail

    } // end namespace hoomd
