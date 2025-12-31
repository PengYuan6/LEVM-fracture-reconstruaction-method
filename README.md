# LEVM：A Multi-device Data fusion Method for Rock Tensile Fracture Reconstruction 
This repository provides open-source code and datasets for a three-dimensional rock fracture reconstruction method. The associated manuscript has been submitted to IJRMMS.
>**Notice**: 
>As the authors were occupied with completing the master’s thesis, some code and dataset annotations may not be sufficiently detailed. If there are **ANY** questions regarding the code or data, please contact the me at l15650107296@163.com. **All** inquiries will be responded to in a timely manner.
>
The overall workflow of the proposed method is illustrated in the figure. Its core advantages can be summarized as follows:

![Uploading image.png…](https://github.com/PengYuan6/LEVM-Multi-device-data-fusion-method-for-3D-fracture-resconstuction/blob/main/images/LEVM_Workflow.jpg)

- By integrating the complementary strengths of CT imaging and 3D scanning, two relatively low-cost and individually lower-precision devices are effectively combined to achieve a more accurate reconstruction of three-dimensional fracture geometry.
- Only local CT scanning of the fracture region is required to recover the complete tensile fracture structure.
- The reconstructed fracture geometry is well suited for subsequent hydro-mechanical simulations.
---
The workflow of the program is as follows:
- `NDT_algorithm.m` Used to ensure that the top and bottom fracture surfaces are properly aligned and parallel.
  - **Required data format**：Input data `.ply` file.
- `STILT.m` Used to extract local enclosed volumes from CT images.
  - **Included functions**：`aspect_ratio_filter.m` `MorphProgram.m` 
  - Example Demonstrates the iterative extraction and processing image.
- `Enclosed_Volume_Cal_from_Point_Clouds.m` Used to calculate the enclosed volume between fracture surfaces, accurately reflecting the true relative position of the fracture walls.
- `NormalContactSimulation.py`
  - More details and required packages are provided in the **ContactMechanics** directory.
  - This program can only be executed on **Linux** and **macOS** systems.
  - The fracture aperture data must be provided in **matrix form** and the surfaces must be **composite surfaces**, aperture values must be **negative**
