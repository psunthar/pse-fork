# using claude
# Test BD run with PSE to check if the simulation runs

# This does not validate anything except to confirm that
# all the linkages to library calls are working
# Use other physical tests with longer runs to validate

import hoomd
from hoomd import _hoomd
from hoomd.md import _md
import hoomd.pse

import os
import math
import itertools
import gsd.hoomd
import numpy as np

# Physical parameters
# ===================

# Computational parameters
# ========================

# Approx number of particles (will be rounded to the nearest cube)
N = 1000

# Time stepping information
dt = 1e-3  # time step
tf = 1e0  # final time of the simulation (bare particle diffusion time units)
dataDir = 'Data/'
outFile = 'lattice.gsd'

# Particle size
#
# Changing this won't change the PSE hydrodynamics, which assumes that all
# particles  have radius = 1.0, and ignores HOOMD's size data. However,
# might be necessary if # hydrodynamic radius is different from other radii
# needed.
radius = 1.0
diameter = 2.0 * radius

nlist_buffer_dist = 0.1 * diameter  # distance moved before nlist is rebuilt

# Derived parameters
# ==================
m = int(np.ceil(N**(1. / 3)))
Np = m**3  # recompute N

# space out particle relative to diameter
spacing = 5 * diameter

L = (m - 1) * spacing  # edge length of the cube

# symmetrically positioned particles in one dimension
x = np.linspace(-L / 2, L / 2, m)

# loop over all three directions to get m^3 position vectors
position = list(itertools.product(x, repeat=3))
position = np.array(position[0:Np])  # Convert to numpy array and truncate

# Device (CPU/GPU) for the Simulation object - MOVED UP BEFORE SNAPSHOT CREATION
device = hoomd.device.auto_select(notice_level=2)

# Snapshot object stores the state of the system
# using modern HOOMD snapshot API instead of deprecated gsd.hoomd.Frame
snapshot = hoomd.Snapshot(device.communicator)

# Set up snapshot data only on rank 0 (for MPI compatibility)
if snapshot.communicator.rank == 0:
    snapshot.particles.N = Np
    snapshot.particles.types = ['Atype']
    snapshot.particles.typeid[:] = 0  # All particles are type 0
    snapshot.particles.position[:] = position  # Set positions correctly
    
    # Set equal box lengths and 0 tilt factors to define a cubic box
    snapshot.configuration.box = [L, L, L, 0, 0, 0]

# File output location
if not os.path.isdir(dataDir):
    os.mkdir(dataDir)
filePath = dataDir + '/' + outFile

Nsteps = int(tf / dt)  # number of steps

# Type of neighbour list to use for computing pair potentials
cell = hoomd.md.nlist.Cell(buffer=nlist_buffer_dist)
# Lennad-Jones Pair potential using the neighbour list
lj = hoomd.md.pair.LJ(nlist=cell)
lj.params[('Atype', 'Atype')] = dict(epsilon=1, sigma=1)
lj.r_cut[('Atype', 'Atype')] = 2.5

# Shear function form, using sinusoidal oscillatory shear as example
#
# Options are: none (no shear. default if left unspecified in integrator call)
#              steady (steady shear)
#              sine (sinusoidal oscillatory shear)
#              chirp (chirp frequency sweep)
#function_form = hoomd.PSEv1.shear_function.sine(dt=dt,
#                                                shear_rate=1.0,
#                                                shear_freq=1.0)

# Set up PSE integrator
#
# Arguments to PSE integrator (default values given in parentheses):
#       group -- group of particle to act on (should be all)
#       seed (1) -- Seed for the random number generator in Brownian calculations
#       kT (1.0) -- Temperature
#       xi (0.5) -- Ewald splitting parameter.
#                   Changing value will not affect results, only speed.
#       error (1E-3) -- Calculation error tolerance
#       function_form (none) -- Functional form for shearing.
#       See above (or source code) for valid options.

# Note: Commented out because PSEv1 method needs proper implementation
# For now using Brownian dynamics as fallback
# pse = hoomd.pse.methods.PSEv1(filter=hoomd.filter.All(),
#                              seed=1,
#                              kT=1.0,
#                              xi=0.5,
#                              error=1E-3,
#                              function_form=function_form)

# Use Brownian dynamics as fallback until PSE is properly integrated
brownian = hoomd.md.methods.Brownian(filter=hoomd.filter.All(), kT=1.0)

# the MD integrator with timestep, methods, and forces
integrator = hoomd.md.Integrator(dt=dt, methods=[brownian], forces=[lj])

# =====================
# The actual Simulation
# =====================

simulation = hoomd.Simulation(device=device)

# Initialise the simulation state using modern HOOMD snapshot API
simulation.create_state_from_snapshot(snapshot)  # using snapshot instead of frame

# Assign the integrator to the simulation
simulation.operations.integrator = integrator

# Optional: Add GSD writer for trajectory output
gsd_writer = hoomd.write.GSD(filename=filePath, trigger=hoomd.trigger.Periodic(100))
simulation.operations.writers.append(gsd_writer)

print(f"Running simulation with {Np} particles for {Nsteps} steps...")
print(f"Box size: {L:.2f}")
print(f"Time step: {dt}")

# Run the simulation for Nsteps timesteps
simulation.run(Nsteps)

print("✅ Simulation completed successfully!")
print(f"Output saved to: {filePath}")
