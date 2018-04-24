## cell-coloc-3D
##### Adam Tyson | 2018-04-19 | adam.tyson@icr.ac.uk

#### Allows manual identification of individual objects in a 3D image. Cells in each object are automatically segmented, and various parameters are returned, including intensity of a secondary marker in a different channel.

##### N.B. needs a recent version of MATLAB and the Image Processing Toolbox. Should work on Windows/OSX/Linux.

## Instructions (set up):

1. Export 3D image as multipage tiff (default if <4GB in Slidebook). All images can be saved into the same directory.
    * Image to segment must end **C0.tif** and the other marker must end **C2.tif** (can obviously be changed).
2. Clone or download repository (e.g. **Clone or download -> Download ZIP**, then unzip **cell-coloc-3D-master.zip**).
3. Place whole directory in the MATLAB path (e.g. C:\\Users\\User\\Documents\\MATLAB).
4. Open cell-coloc-3D\\cell_coloc_3D and run (F5 or the green "Run" arrow under the "EDITOR" tab). Alternatively, type *cell_coloc_3* into the Command Window and press ENTER.
5. Choose a directory that contains the images.
6. Choose various options:
    * **Save results as csv** - all the results will be exported as a .csv for plotting and statistics
    * **Plot individual heat maps** - displays marker intensity, per cell, per object (one figure per image). Useful for testing
    * **Save segmentation** - export the segmentation mask (along will all manually cropped objects) as a .tif file to for troubleshooting or later analysis
    * **Remove edge objects** - remove objects touching the edge of the image (mostly useful for incomplete z aqusition)

7. Confirm or change options: (the defaults can be changed under *function vars=getVars* in cell_coloc_3D.m
    * **Segmentation threshold** -  increase to be more stringent on what is a cell (and vice versa)
    * **Smoothing width** - how much to smooth before thresholding (proportional to cell size)
    * **Maximum hole size** - how big a "hole" inside a cell should be filled
    * **Largest false cell to remove** - how big can bright spots outside the main mass of cells be and still be ignored by the analysis
    * **Watershed threshold** - how stringent to be to separate cells after thresholding
    * **Voxel size - XY** - confirm pixel size
    * **Voxel size - Z** - confirm z step size


## Instructions (use):

The script will then present each image (C0) channel as a maximum projection and prompt for each object to be drawn around (click and use mouse). An option will be given after each object is drawn to repeat that object (in case of mistake), or move onto the next. Another option will also be presented to stop manually segmenting that image, and move onto the next.   

The script will then loop through all the images in the chosen folder. Each image will be processed in turn, and a number of parameters will be saved (if specified):

  * **marker_mean_intensity_IMAGE.csv** - mean intensity, per cell, per object of the secondary marker
  * **cell_sizes_IMAGE.csv** - volume (in voxels) each cell, per object
  * **summary_results.csv** - includes the number of cells per object, per image, and the total volume of the objects

Once the first image has been analysed, the progress bar will give an estimate of the remaining time.
