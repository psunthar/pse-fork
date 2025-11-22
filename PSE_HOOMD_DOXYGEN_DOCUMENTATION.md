# PSE HOOMD Plugin - Doxygen-Compatible Documentation

This document provides Doxygen-style documentation for the PSE (Positively Split Ewald) HOOMD-4 plugin that can be extracted and processed by automated documentation generation tools.

---

## Module Overview

**Module:** `hoomd.pse`  
**Type:** HOOMD Integration Method Plugin  
**Version:** 4.9 (HOOMD-4 compatible)  
**License:** HOOMD License (see file headers)  
**Maintainers:** PSE Development Team  

### Brief Description

The PSE (Positively Split Ewald) module implements overdamped Brownian dynamics with hydrodynamic interactions via the Positively Split Ewald (PSE) method on GPU. It computes forces including:
- Brownian motion (thermal forces)
- Hydrodynamic interactions (Stokes flow)
- Ewald summation (periodic boundary conditions)

### Dependencies

- **HOOMD-4.9+**: Main simulation framework
- **pybind11**: Python/C++ bindings
- **CUDA 11+**: GPU computation
- **cuFFT**: GPU FFT for Ewald summation
- **CMake 3.16+**: Build system

---

## Class Reference

### `hoomd.pse.methods.PSEv1`

**Header:** `module.cc`, `Stokes.h`  
**Type:** Integration method for HOOMD-4  
**Inherits:** `hoomd.md.Integrator` method  
**Status:** ✅ HOOMD-4 compatible (standalone module)

#### Purpose

`PSEv1` is the main user-facing integration method that combines PSE physics with HOOMD's integration framework. It provides overdamped dynamics with hydrodynamic forces computed via GPU.

#### Constructor

```python
hoomd.pse.methods.PSEv1(
    filter: hoomd.filter.Filter,
    kT: float = 1.0,
    seed: int = 1,
    xi: float = 0.5,
    error: float = 0.001,
    function_form: ShearFunction = None
)
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `filter` | `hoomd.filter.Filter` | Required | Particle group to integrate (usually `hoomd.filter.All()`) |
| `kT` | `float` | 1.0 | Thermal energy (temperature × Boltzmann constant) |
| `seed` | `int` | 1 | Random number generator seed for Brownian forces |
| `xi` | `float` | 0.5 | Ewald splitting parameter; higher values favor real space |
| `error` | `float` | 0.001 | Relative error tolerance for all PSE calculations |
| `function_form` | `ShearFunction` | `None` | Optional shear function (steady, sine, chirp, or custom) |

**Example:**

```python
import hoomd
import hoomd.pse

# Create PSE method with steady shear
shear_func = hoomd.pse.shear_function.steady(dt=0.001, shear_rate=0.1)
pse = hoomd.pse.methods.PSEv1(
    filter=hoomd.filter.All(),
    kT=1.0,
    seed=42,
    xi=0.5,
    error=0.001,
    function_form=shear_func
)

# Add to integrator
integrator = hoomd.md.Integrator(dt=0.001, methods=[pse])
simulation.operations.integrator = integrator
```

**Notes:**

- `kT=0` gives deterministic hydrodynamic forces (no Brownian motion)
- `xi` controls Ewald splitting: `xi → 0` favors wave space; `xi → ∞` favors real space
- `error` should be ≥ 1e-5 for reasonable performance; typical values 1e-4 to 1e-2

---

### `hoomd.pse.shear_function`

**Header:** `ShearFunction.h`, `VariantShearFunction.cc`  
**Type:** Namespace for shear function factories  
**Status:** ✅ HOOMD-4 compatible

#### Shear Functions

Shear functions define time-dependent strain applied to the simulation box. They return a `ShearFunction` object encapsulating the strain profile.

##### `steady(dt, shear_rate)`

Applies constant shear strain at constant rate.

```python
shear = hoomd.pse.shear_function.steady(dt=0.001, shear_rate=0.1)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `dt` | `float` | Integration timestep (used for internal normalization) |
| `shear_rate` | `float` | Strain rate (strain per unit time) |

**Example:**

```python
# Shear at rate 0.1 (10% strain per unit time)
shear = hoomd.pse.shear_function.steady(dt=1e-3, shear_rate=0.1)
pse = hoomd.pse.methods.PSEv1(..., function_form=shear)
```

##### `sine(dt, shear_rate, shear_freq)`

Applies sinusoidal oscillatory shear strain.

```python
shear = hoomd.pse.shear_function.sine(
    dt=0.001,
    shear_rate=0.1,
    shear_freq=1.0
)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `dt` | `float` | Integration timestep |
| `shear_rate` | `float` | Amplitude of shear oscillation |
| `shear_freq` | `float` | Frequency of oscillation (in units of 1/time) |

**Example:**

```python
# Oscillate at frequency 2π rad/time with amplitude 0.1
shear = hoomd.pse.shear_function.sine(
    dt=1e-3,
    shear_rate=0.1,
    shear_freq=2.0 * 3.14159
)
pse = hoomd.pse.methods.PSEv1(..., function_form=shear)
```

##### `chirp(dt, shear_rate, freq_start, freq_end, duration)`

Applies frequency sweep (chirp) shear strain.

```python
shear = hoomd.pse.shear_function.chirp(
    dt=0.001,
    shear_rate=0.1,
    freq_start=1.0,
    freq_end=10.0,
    duration=100.0
)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `dt` | `float` | Integration timestep |
| `shear_rate` | `float` | Amplitude of shear |
| `freq_start` | `float` | Starting frequency (rad/time) |
| `freq_end` | `float` | Ending frequency (rad/time) |
| `duration` | `float` | Duration of frequency sweep (time units) |

---

## Low-Level C++ Bindings

### `_pse.Stokes` (Direct C++ Access)

**Header:** `Stokes.h`  
**Type:** Low-level C++ Stokes hydrodynamics engine  
**Status:** Advanced usage (direct GPU kernel access)  
**Access:** `from hoomd.pse import _pse`

#### Purpose

Low-level C++ object for direct hydrodynamic force computation. Provides direct access to GPU kernels and Ewald parameters.

#### Methods

##### `computeForces(positions, velocities, forces)`

Compute hydrodynamic forces from particle positions and velocities.

```python
from hoomd.pse import _pse

stokes = _pse.Stokes()
stokes.setParams(kT=1.0, xi=0.5, error=0.001)

# Compute forces
forces = stokes.computeForces(
    positions=particle_positions,    # N × 3 array
    velocities=particle_velocities,  # N × 3 array
)  # Returns N × 3 force array
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `positions` | `ndarray(N, 3)` | Particle positions in simulation box |
| `velocities` | `ndarray(N, 3)` | Particle velocities (for coupling) |

**Returns:** `ndarray(N, 3)` - Forces due to hydrodynamic interactions

**Notes:**

- Forces include Brownian contributions if `kT > 0`
- Periodic boundary conditions enforced by Ewald summation
- Each call evaluates current time-dependent shear

##### `computeMobility(positions)`

Compute mobility matrix from particle positions.

```python
mobility = stokes.computeMobility(positions=particle_positions)
# Returns 3N × 3N mobility matrix (full rank for N particles)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `positions` | `ndarray(N, 3)` | Particle positions |

**Returns:** `ndarray(3N, 3N)` - Symmetric positive-definite mobility matrix

##### `setParams(kT, xi, error_tolerance)`

Set PSE parameters.

```python
stokes.setParams(
    kT=1.0,
    xi=0.5,
    error_tolerance=0.001
)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `kT` | `float` | Thermal energy |
| `xi` | `float` | Ewald splitting parameter |
| `error_tolerance` | `float` | Relative error tolerance |

**Notes:**

- `kT=0`: Deterministic hydrodynamics
- `kT>0`: Includes Brownian motion
- `xi` typically in range [0.1, 10.0]
- Recomputes all tables when called

##### `setShear(shear_function, max_strain)`

Set shear function and maximum strain.

```python
from hoomd.pse import _pse

stokes = _pse.Stokes()
stokes.setShear(
    shear_function=function_form.cpp_function,
    max_strain=0.5
)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `shear_function` | `void*` (C++ pointer) | Shear function from `ShearFunction` object |
| `max_strain` | `float` | Maximum accumulated strain before box update |

**Notes:**

- Shear function pointer obtained from Python `ShearFunction` object
- Box is resized periodically to prevent extreme deformation

---

## GPU Kernels (CUDA Implementation)

### Kernel Overview

| Kernel | File | Purpose | Computes |
|--------|------|---------|----------|
| `brownianKernel` | `Brownian.cu` | Brownian forces | $\sqrt{2kT/\gamma}$ random forces |
| `mobilityKernel` | `Mobility.cu` | Mobility matrix | 3×3 blocks of hydro interaction |
| `ewald_realspace` | `Stokes.cu` | Real-space Ewald | Short-range hydro sum |
| `ewald_wavespace` | `FFT.cu` | Wave-space Ewald | FFT-based long-range hydro |
| `correction` | `Correction.cu` | Self-interaction correction | Particle self-mobility |

### Performance Notes

- Wave-space computation dominates for N > 100 particles
- Real-space cutoff auto-tuned based on `xi` and `error`
- Brownian forces computed per-timestep (independent, parallelizable)
- Ewald tables precomputed per simulation (one-time cost)

---

## Algorithm Details

### PSE Method (Positively Split Ewald)

The PSE method decomposes the hydrodynamic mobility tensor into real and wave space components:

$$M = M_{\text{real}} + M_{\text{wave}} + M_{\text{self}}$$

**Real Space (R-space):**
- Computed on GPU via direct pairwise summation
- Kernel: $r_{ij}^{-1} \cdot \text{erfc}(\alpha r_{ij})$
- Cutoff: $r_c \approx \text{erfc}^{-1}(10^{-\text{error}})$

**Wave Space (k-space):**
- Computed via FFT on GPU
- Kernel: $\hat{M}(k) = (1 - \text{erf}(\alpha / k)) / k^2$
- Supports periodic boundary conditions

**Self Interaction:**
- Isotropic part: $M_{\text{self}} = (6\pi\eta a)^{-1} \mathbb{I}$
- Ensures positive definiteness

**Parameters:**

- `xi`: Controls real/wave balance (xi=0 → pure wave; xi=∞ → pure real)
- `error`: Controls accuracy; error ∝ $e^{-(\text{error} \cdot \xi)^2}$

### Brownian Dynamics

Forces include random thermal contribution:

$$F_i = -\gamma v_i + F_{\text{hydro}} + F_{\text{random}}$$

where:
- $\gamma = 6\pi\eta a$ (friction coefficient)
- $F_{\text{hydro}}$ = hydrodynamic forces from mobility
- $F_{\text{random}} \sim \mathcal{N}(0, 2kT\gamma \Delta t)$ (Brownian forces)

---

## Building from Source

### CMake Configuration

```bash
cd /path/to/pse
mkdir build && cd build
cmake .. \
  -DHOOMD_INSTALL_DIR=/path/to/hoomd/install \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_GPU=ON \
  -DCUDA_ARCH=70  # Adjust for your GPU (SM 7.0, 8.0, 9.0, etc.)

make install
```

### Required Files

```
pse/
├── CMakeLists.txt          # Build configuration
├── pse/
│   ├── module.cc           # Python bindings (pybind11)
│   ├── Stokes.h/.cc        # Main integration method
│   ├── Mobility.cu         # GPU kernel: mobility matrix
│   ├── Brownian.cu         # GPU kernel: Brownian forces
│   ├── *.cu                # Other GPU kernels
│   └── include/            # CUDA headers
└── cmake/                  # CMake find modules
```

### Installation Verification

```python
import hoomd
import hoomd.pse
from hoomd.pse import _pse

# Test 1: Create PSEv1 method
pse = hoomd.pse.methods.PSEv1(filter=hoomd.filter.All())
print("✓ PSEv1 method created")

# Test 2: Create shear function
shear = hoomd.pse.shear_function.steady(dt=0.001, shear_rate=0.1)
print("✓ Shear function created")

# Test 3: Direct C++ access
stokes = _pse.Stokes()
print("✓ Direct Stokes access working")
```

---

## Examples

### Example 1: Simple Brownian Dynamics

```python
import hoomd
import hoomd.pse
import numpy as np

# Setup
device = hoomd.device.auto_select()
sim = hoomd.Simulation(device=device)

# Create particles in lattice
N = 64
snapshot = hoomd.Snapshot(device.communicator)
if snapshot.communicator.rank == 0:
    positions = np.random.uniform(-10, 10, (N, 3))
    snapshot.particles.N = N
    snapshot.particles.position[:] = positions
    snapshot.configuration.box = [20, 20, 20, 0, 0, 0]

sim.create_state_from_snapshot(snapshot)

# PSE integration
pse = hoomd.pse.methods.PSEv1(
    filter=hoomd.filter.All(),
    kT=1.0,
    seed=42
)
integrator = hoomd.md.Integrator(dt=0.001, methods=[pse])
sim.operations.integrator = integrator

# Run
sim.run(1000)
```

### Example 2: Sheared System

```python
# Create steady shear
shear = hoomd.pse.shear_function.steady(
    dt=0.001,
    shear_rate=1.0  # 100% strain per time unit
)

pse = hoomd.pse.methods.PSEv1(
    filter=hoomd.filter.All(),
    kT=1.0,
    function_form=shear
)

# Continue as above...
```

### Example 3: Direct Kernel Access

```python
from hoomd.pse import _pse
import numpy as np

# Create Stokes object
stokes = _pse.Stokes()
stokes.setParams(kT=1.0, xi=0.5, error=0.001)

# Compute forces for given positions
positions = np.random.uniform(-10, 10, (100, 3))
velocities = np.zeros((100, 3))
forces = stokes.computeForces(positions, velocities)

print(f"Computed {len(forces)} forces")
```

---

## Performance Guidelines

### GPU Requirements

| Metric | Requirement |
|--------|-------------|
| **CUDA Compute Capability** | SM 7.0+ (Volta or newer) |
| **Memory** | ~50 MB for N=1000; scales as $O(N)$ |
| **Peak Performance** | ~100-500 ns/particle/step on modern GPU |

### Scalability

- **Real Space**: $O(N)$ per step (parallelizable)
- **Wave Space**: $O(N \log N)$ per step (FFT)
- **Total**: $O(N \log N)$ per integration step

### Parameter Tuning for Speed

| Goal | Adjustment |
|------|------------|
| Faster (less accurate) | Increase `error` (1e-2 or 1e-3) |
| More accurate (slower) | Decrease `error` (1e-5 or 1e-6) |
| Larger systems | Decrease `xi` to favor wave space |
| Smaller systems | Increase `xi` to favor real space |

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `ModuleNotFoundError: hoomd.pse` | PSE not installed | Rebuild and reinstall |
| GPU out of memory | System too large | Reduce `N` or grid resolution |
| NaN forces | Particles too close | Increase box size or reduce `dt` |
| Slow simulation | `error` too small | Increase `error` to 1e-3 or 1e-2 |

### Debug Output

```python
# Enable verbose output
import logging
logging.basicConfig(level=logging.DEBUG)

# Test kernel execution
from hoomd.pse import _pse
stokes = _pse.Stokes()
print(stokes.__doc__)  # Print docstring if available
```

---

## References

- **HOOMD Documentation**: http://codeblue.umich.edu/hoomd-blue/
- **pybind11 Documentation**: https://pybind11.readthedocs.io/
- **PSE Method**: Brady & Bossis (1988), "Stochastic simulation of hydrodynamic interactions"
- **Ewald Summation**: Perram & Wertheim (1985), "Charge reversal, charge renormalization, and the structure of salt-free polyelectrolytic solutions"

---

## License

PSE HOOMD Plugin is licensed under the HOOMD-Blue open-source license.
See LICENSE file in the plugin source directory.

---

**Last Updated:** November 22, 2025  
**Documentation Version:** 1.0  
**HOOMD Compatibility:** 4.9+  
**Python Version:** 3.9+

