import numpy as np
import matplotlib.pyplot as plt
import tkinter as tk
import os

from tkinter import filedialog
from skgstat import Variogram
from SurfaceTopography import Topography, PlasticTopography
from ContactMechanics import FreeFFTElasticHalfSpace
from ContactMechanics.Factory import make_plastic_system
from ContactMechanics.Tools.Logger import screen

root = tk.Tk()
root.withdraw()  
# Pop up a multi file selection box
file_paths = filedialog.askopenfilenames(
    title="Please select the file to import (multiple choices are allowed)",
    filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
)


file_paths = list(file_paths)
print(f"Choose {len(file_paths)} files")

for i, file_path in enumerate(file_paths):
    # Separate path, file name, and extension
    root, ext = os.path.splitext(file_path)
    folder = os.path.dirname(file_path)
    file_name = os.path.basename(root)
    print(f"\n is calculating NO.{i+1} files : {file_name}{ext}")
    
    #-------- Caculation part----------------------------------------------------------------
    data = np.loadtxt(file_path)
    sx,sy = (42,63)   
    nx,ny = data.shape
    h = data 
    topography = Topography(h, nb_grid_pts=(nx,ny),physical_sizes=(sx, sy))
    
    E  = 15370                     # MPa
    mu = 0.28
    Es = 1 /  (2 * (1-mu**2) / E)  # GPa
    hardness = Es*0.15             # MPa; 
    print('Harhness Value is :',hardness)
    #  system setup
    system = make_plastic_system(
                substrate = FreeFFTElasticHalfSpace(nb_grid_pts=topography.nb_grid_pts, young=Es, physical_sizes=topography.physical_sizes), 
                surface   = PlasticTopography(topography=topography, hardness=hardness)
            )
    external_pressures = np.linspace(0.5, 20 ,40)
    external_forces    = np.array(external_pressures)*sx*sy
    
    offsets = []
    plastic_areas = []
    contact_areas = [] # NOTICE!!!  This contact areas value  is  the actual region (mm^2) providing normal force.
                       # However, the contact area (Cf) used in this paper is NOT this value.
                       # Following numerous studies in the literature, we also define contact as all locations where aperture < a given threshold (0.02 mm).
    
    forces = np.zeros((len(external_forces), *topography.nb_grid_pts)) # forces[timestep,...]: array of forces for each gridpoint
    elastic_displacements = np.zeros((len(external_forces), *topography.nb_grid_pts))
    aperture       = np.zeros((len(external_forces), *topography.nb_grid_pts))
    mean_aperture  = np.zeros(len(external_forces))
    std_aperture   = np.zeros(len(external_forces)) 
    mean_closure   = np.zeros(len(external_forces))
    correlation_length = np.zeros(len(external_forces))
    plastified_topographies = []
    
    i = 0
    for external_force in external_forces:
        sol = system.minimize_proxy(external_force=external_force, #load controlled
                                    #mixfac = 1e-4,
                                    initial_displacements=disp0,
                                    maxiter = 1500,
                                    pentol  = 1e-10, # for the default value I had some spiky pressure fields during unloading
                                    logger=screen)   # display informations about each iteration
        assert sol.success
        disp0 = system.disp
        offsets.append(system.offset)
        plastic_areas.append(system.surface.plastic_area)
        contact_areas.append(system.compute_contact_area()) 
        plastified_topographies.append(system.surface.squeeze())
        forces[i,...] = system.force
        elastic_displacements[i, ...] = system.disp[system.surface.subdomain_slices]
        aperture[i,...]    = elastic_displacements[i]-plastified_topographies[i].heights()-offsets[i]
        std_aperture[i]    = np.std(aperture[i])
        mean_aperture[i]   = np.mean(aperture[i])
        mean_closure[i]    = np.mean(-topography.heights()) - mean_aperture[i]
        
        print("No.",i,"itration is Solved")
        
       
        np.savetxt(f'{root}_12_11_{external_force/sx/sy:05.1f}MPa.txt', aperture[i], fmt='%.4f')
        print(f'-------{root}_{external_pressures[i]}MPa.txt is soved--------')

        i+=1

plt.plot(external_forces/sx/sy, mean_closure,'+-')
plt.show()

#%%
numbels = aperture[0].size
Contact_ratio = np.sum(aperture[0] < 0.0001) / aperture[0].size

np.savetxt(f'{root}_Pressure_{external_force/sx/sy:05.1f}MPa.txt', forces[i-1], fmt='%.4f')
# %%

