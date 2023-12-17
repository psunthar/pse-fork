# Test BD run with PSE to check if the simulation runs

# This does not validate anything except to confirm that 
# all the linkages to library calls are working
# Use other physical tests with longer runs to validate

import hoomd;
from hoomd import _hoomd
from hoomd.md import _md
import hoomd.PSEv1

import os;
import math
import itertools
import gsd.hoomd
import numpy as np



## Physical parameters

## Computational parameters

# Approx number of particles (will be rounded to the nearest cube)
N = 1000


# Time stepping information
dt = 1e-3      # time step
tf = 1e0       # the final time of the simulation (in units of bare particle diffusion time)
dataDir = 'Data/'
outFile = 'lattice.gsd'


# Particle size
#
# Changing this won't change the PSE hydrodynamics, which assumes that all particles
# have radius = 1.0, and ignores HOOMD's size data. However, might be necessary if 
# hydrodynamic radius is different from other radii needed.
radius = 1.0
diameter = 2.0 * radius

nlist_buffer_dist = 0.1 * diameter # distance moved before nlist is rebuilt

## Derived parameters
m = int(np.ceil(N**(1./3)))
Np = m**3 # recompute N

# space out particle relative to diameter
spacing = 5 * diameter

L = (m - 1) * spacing # edge length of the cube

# symmetrically positioned particles in one dimension
x = np.linspace(-L/2, L/2, m)

# loop over all three directions to get m^3 position vectors
position = list(itertools.product(x, repeat=3))

# Frame object stores the state of the system
# and gsd is the native format to store the state including trajectories
frame = gsd.hoomd.Frame()
frame.particles.N = Np
frame.particles.position = position[0:Np]  # in case there are more!

# There is a single type of particle in this simulation
frame.particles.types = ['Atype']
frame.particles.typeid = [0] * Np

# GSD represents boxes with a 6-element array. Three box lengths L_x, L_y, L_z,
# and 3 tilt factors. Set equal box lengths and 0 tilt factors to define a
# cubic box.
frame.configuration.box = [L, L, L, 0, 0, 0]


# File output location
if not os.path.isdir( loc ):
        os.mkdir( loc )
filePath = outDir + '/' + outFile

# write (append) this snapshot to disk
with gsd.hoomd.open(name=filePath, mode='w') as f:
    f.append(frame)

Nsteps = tf / dt # number of steps


# Type of neighbour list to use for computing pair potentials
cell = hoomd.md.nlist.Cell(buffer=nlist_buffer_dist)
# Lennad-Jones Pair potential using the neighbour list
lj = hoomd.md.pair.LJ(nlist=cell)
lj.params[('Atype', 'Atype')] = dict(epsilon=1, sigma=1)
lj.r_cut[('Atype', 'Atype')] = 2.5



# Simple cubic crystal of 1000 particles
#L = 64
#n = math.ceil(N ** (1.0/3.0)) # number of particles along 1D
#a = L / n # spacing between particles
# Create the box and particles
#hoomd.init.create_lattice(unitcell=hoomd.lattice.sc(a=a),n=n)

# Shear function form, using sinusoidal oscillatory shear as example
#
# Options are: none (no shear. default if left unspecified in integrator call)
#              steady (steady shear)
#              sine (sinusoidal oscillatory shear)
#              chirp (chirp frequency sweep)
function_form = hoomd.PSEv1.shear_function.sine( dt = dt, shear_rate = 1.0, 
                                                 shear_freq = 1.0 )

# Set up PSE integrator
#
# Arguments to PSE integrator (default values given in parentheses):
# 	group -- group of particle to act on (should be all)
#	seed (1) -- Seed for the random number generator used in Brownian calculations
#       T (1.0) -- Temperature
#       xi (0.5) -- Ewald splitting parameter. Changing value will not affect results, only speed.
#       error (1E-3) -- Calculation error tolerance
#       function_form (none) -- Functional form for shearing. See above (or source code) for valid options. 

pse = hoomd.pse.methods.PSEv1( group = hoomd.group.all(), seed = 1, T = 1.0, xi = 0.5, error = 1E-3, function_form = function_form )
#pse = hoomd.PSEv1.integrate.PSEv1( group = hoomd.group.all(), seed = 1, T = 1.0, xi = 0.5, error = 1E-3, function_form = function_form )


# Set up the MD integrator with timestep
integrator = hoomd.md.Integrator(dt=dt, methods=[pse], forces=[lj])



## Select the Device (CPU/GPU) for the Simulation object
device = hoomd.device.auto_select(notice_level=2)


## The actual Simulation
simulation = hoomd.Simulation(device=device)
# deprecated: hoomd.context.initialize('');

# Initialise the simulation state
simulation.create_state_from_snapshot(frame) # from gsd.hoomd.Frame
# simulation.create_state_from_gsd(filename=filePath) # from disk

# Assign the integrator to the simulation
simulation.operations.integrator = integrator

# Run the simulation for Nsteps timesteps
simulation.run(Nsteps)

#hoomd.md.integrate.mode_standard(dt=dt)
#pse = hoomd.PSEv1.integrate.PSEv1( group = hoomd.group.all(), seed = 1, T = 1.0, xi = 0.5, error = 1E-3, function_form = function_form )
# Run the simulation
#hoomd.run( nrun )


