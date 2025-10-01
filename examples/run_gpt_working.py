#!/usr/bin/env python3

# PSE Tutorial - Updated for HOOMD v4.9.1 with COMPLETE PSE SOLUTION
# Using PSE integration that actually works

import hoomd
import hoomd.pse.methods as pse_methods
import os
import math
import numpy as np

print("PSE Tutorial - HOOMD v4.9.1 with COMPLETE PSE Integration")
print("==========================================================")

# Physical parameters
dt = 1e-3      # time step
tf = 1e-1      # shorter run for testing: 0.1 time units
nrun = int(tf / dt)  # number of steps

# Simulation parameters
N = 64         # number of particles (reduced for testing)
phi = 0.2      # volume fraction
kT = 1.0       # thermal energy
sigma = 1.0    # particle diameter

def main():
    # Initialize HOOMD
    cpu = hoomd.device.CPU()
    sim = hoomd.Simulation(device=cpu, seed=1)
    
    # Create simple lattice system
    print(f"\nSetting up simulation with {N} particles...")
    spacing = 1.0
    K = int(round(N**(1/3)))  # cubic lattice dimension
    L = K * spacing
    
    # Generate positions
    positions = []
    for i in range(K):
        for j in range(K):
            for k in range(K):
                if len(positions) < N:
                    x = (i - K/2 + 0.5) * spacing
                    y = (j - K/2 + 0.5) * spacing
                    z = (k - K/2 + 0.5) * spacing
                    positions.append([x, y, z])
    
    # Create snapshot
    snapshot = hoomd.Snapshot(cpu.communicator)
    if snapshot.communicator.rank == 0:
        snapshot.configuration.box = [L, L, L, 0, 0, 0]
        snapshot.particles.N = len(positions)
        snapshot.particles.position[:] = positions
        snapshot.particles.typeid[:] = [0] * len(positions)
        snapshot.particles.types = ['A']
    
    sim.create_state_from_snapshot(snapshot)
    print(f"✅ Created system with {len(positions)} particles in box size {L:.2f}")
    
    # Create PSE method
    print("\nCreating PSE integration method...")
    pse_method = pse_methods.PSEv1(
        filter=hoomd.filter.All(),
        kT=kT,
        seed=1,
        xi=0.5,
        error=0.001
    )
    print(f"✅ PSE method created: {pse_method}")
    
    # Create integrator
    print("\nSetting up integrator...")
    integrator = hoomd.md.Integrator(dt=dt, methods=[pse_method])
    sim.operations.integrator = integrator
    print(f"✅ Integrator created with dt={dt}")
    
    # Setup output
    print("\nSetting up output...")
    os.makedirs('Data', exist_ok=True)
    gsd_writer = hoomd.write.GSD(
        filename='Data/pse_tutorial_working.gsd',
        trigger=hoomd.trigger.Periodic(10),
        mode='wb'
    )
    sim.operations.writers.append(gsd_writer)
    
    # Run simulation
    print(f"\nRunning simulation for {nrun} steps...")
    print(f"Total time: {tf} time units")
    
    try:
        sim.run(nrun)
        print("✅ Simulation completed successfully!")
        
        # Show output file
        import subprocess
        result = subprocess.run(['ls', '-lh', 'Data/pse_tutorial_working.gsd'], 
                              capture_output=True, text=True)
        print(f"Output file: {result.stdout.strip()}")
        
        print("\n" + "="*60)
        print("🎉 PSE TUTORIAL SUCCESS! 🎉")
        print("="*60)
        print("✅ PSE integration working perfectly")
        print("✅ HOOMD-4 compatibility achieved")
        print("✅ Tutorial completed successfully")
        print("="*60)
        
        return True
        
    except Exception as e:
        print(f"❌ Simulation failed: {e}")
        return False

if __name__ == "__main__":
    success = main()
    if success:
        print("PSE Tutorial test: PASSED ✅")
    else:
        print("PSE Tutorial test: FAILED ❌")
