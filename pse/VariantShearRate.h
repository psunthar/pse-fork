#pragma once

#include <cstdint>
#include <pybind11/pybind11.h>
#include <utility>

#include "HOOMDMath.h"

namespace hoomd
    {
/** Defines shear rate functions that vary with time steps.

    
*/

class VariantShearRate : public Variant {


}



/** Constant value

    Variant that provides a constant value.
*/
class VariantSteadyShearRate : public VariantShearRate
    {
    public:
    /** Construct a VariantConstant.

        @param value The value.
    */
    VariantConstant(Scalar value) : m_value(value) { }

    /// Return the value.
    Scalar operator()(uint64_t timestep)
        {
        return m_value;
        }

    /// Set the value.
    void setValue(Scalar value)
        {
        m_value = value;
        }

    /// Get the value.
    Scalar getValue() const
        {
        return m_value;
        }

    /// Returns the given constant, c
    virtual Scalar min()
        {
        return m_value;
        }

    /// Returns the given constant, c
    virtual Scalar max()
        {
        return m_value;
        }

    protected:
    /// The value.
    Scalar m_value;
    };

namespace detail
    {
/// Export Variant classes to Python
void export_Variant(pybind11::module& m);

    } // end namespace detail

    } // end namespace hoomd
