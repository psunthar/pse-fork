// Maintainer: Gang Wang

/*! \file VariantShearFunction.h
    \brief Declares the VariantShearFunction class
*/

#ifdef NVCC
#error This header cannot be compiled by nvcc
#endif

#include <pybind11/pybind11.h>

#ifndef __VARIANT_SHEAR_FUNCTION_H__
#define __VARIANT_SHEAR_FUNCTION_H__

#include <hoomd/Variant.h>
#include <cmath>
#include "ShearFunction.h"


namespace hoomd
{
namespace md
{

//! Variant class for shear flowfield described by a function
/*! This variant gives the strain value based on a function (which is ShearFunction type)
    The strain is wrapped based on the min_value and max_value since HOOMD cannot deal with
    very thin box. In most cases, max_value - min_value is an integer (and the recommended value
    is [-0.5, 0.5]). If the timestep is smaller than offset, 0 is returned when calling
    getValue; if the timestep is larger than offset + total_timestep, the strain of the last
    time point is returned.
 */
class VariantShearFunction : public Variant
{
public:
    //! Constructs a VariantShearFunction type with a shared_ptr to ShearFunction and total timestep
    /*! \param shear_func the shared pointer to the ShearFunction object
        \param total_timestep total time step this Variant is going to be effective
        \param min_value the minimal value of this Variant
        \param max_value the maximal value of this Variant
    */
    VariantShearFunction(std::shared_ptr<ShearFunction> shear_func,
        unsigned int total_timestep,
        double min_value,
        double max_value);

    //! Gets the value at a given time step
    virtual double getValue(unsigned int timestep);

    //! Wrap the value between m_min_value and m_max_value
    double wrapValue(double functionValue) {
        return functionValue - m_value_range * floor( (functionValue - m_min_value) / m_value_range );
    }

    // method nolonger implemented in hoomd4.Variant
    void setOffset(unsigned int offset) {
        m_offset = offset;
    }

    // min() and max() need to be implemented in a derived class
    // as Variant is now an abstract class with these
    // two pure virtual functions
    Scalar min() {
        return m_min_value;
    }
    Scalar max() {
        return m_max_value;
    }



private:
    const std::shared_ptr<ShearFunction> m_shear_func;
    const unsigned int m_total_timestep; //!< the total timestep for the Variant class
    const Scalar m_min_value; //!< minimum value of the output of the Variant class
    const Scalar m_max_value; //!< maximum value of the output of the Variant class
    Scalar m_end_value; //!< the last value of output after time > m_offset + m_total_timestep
    Scalar m_value_range; //!< max_value - min_value

    // additional attributes no longer defined in hoomd4.Variant
    unsigned int    m_offset; // Offset time used in _shear_function
};

namespace detail {
//! Exports VariantShearFunction class to python
void export_VariantShearFunction(pybind11::module& m);
} // end namespace detail

} // end namespace md
} // end namespace hoomd


#endif // __VARIANT_SHEAR_FUNCTION_H__
