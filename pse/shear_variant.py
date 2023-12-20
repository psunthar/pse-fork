"""Define shear rate functions that vary over the simulation.

Various shear rate `Variant`so 

"""

from hoomd import _hoomd


class SteadyShearRate(_hoomd.VariantConstant, hoomd.variant.Constant):
    """A constant shear rate

    Args:
        value (float): The value.  Default = 0 (equilibrium)

    `SteadyShearRate` returns `value` at all time steps.

    .. rubric:: Example:

    .. code-block:: python

            variant = pse.shear_variant.SteadyShearRate(1.0)

    Attributes:
        value (float): The value.
    """
    _eq_attrs = ("value",)

    def __init__(self, value=0):
        # Variant.__init__(self)
        super().__init__()
        _hoomd.VariantSteadyShearRate.__init__(self, value)

    __eq__ = Variant._private_eq
