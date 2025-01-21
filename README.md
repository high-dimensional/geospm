# GeoSPM v2.0.0

## Introduction

GeoSPM allows the spatial analysis of diverse geographic point data. It draws upon differential geometry and random field theory, by leveraging the procedures used in statistical parametric mapping (SPM): a framework for making topological inferences about spatially structured effects, with well-behaved spatial dependencies. This approach has been established for decades in the realm of (structural and functional) volumetric neuroimaging.

The core idea is to transform sparse spatial signals into a form suited to mass-univariate statistical testing on a chosen point grid: for example, testing that the spatially or regionally expression of a particular variable is greater than would be expected, under the null hypothesis of no regional effect. The probability of observing topological features in the observed map, such as peaks or clusters (i.e., level sets above some threshold), can then be evaluated, and used to ascribe a p-value to spatially organised effects.

An in-depth paper describing the method behind GeoSPM is available in [preprint](http://arxiv.org/abs/2204.02354).

GeoSPM was developed at the High Dimensional Neurology Group, University Collge London, and made available under the GNU General Public License Version 3.

## Requirements
1. [MATLAB](https://www.mathworks.com/products/matlab.html) release R2020a or newer. In order to produce georeferenced tiff files, GeoSPM requires the [Mathworks Mapping Toolbox](https://www.mathworks.com/products/mapping.html). In addition, GeoSPM uses the [Mathworks Image Processing Toolbox](https://www.mathworks.com/products/image.html) for extracting significant areas as ESRI shape files. GeoSPM should work without these toolboxes if the corresponding features are not used in a computation. For example, when calling `geospm.compute()`, pass the following name-value pairs to make sure the default settings are not used:
    ```
    geospm.compute(...
    'add_georeference_to_images', false,
    'trace_thresholds', false, ...
    );
    ```

2. [SPM12](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/), a MATLAB-based academic software toolkit for the analysis of functional imaging data.

2. A small extension for SPM12 developed by us, the [Synthetic Volumes Toolbox](https://github.com/high-dimensional/synthetic_volumes_toolbox/tags), which is available in a separate repository.

## Installation

1. Install SPM version `7771`, which is available for download [here](https://github.com/spm/spm12/releases/tag/r7771). To download, simply follow the "Source code (zip)" link under the 'Assets' heading. Extract the downloaded `.zip` archive and copy the directory named `spm12-r7771` into your MATLAB directory. Rename the directory from `spm12-r7771` to just `spm12`. More information on SPM itself can be found [here](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/).

    If you have SPM already installed, you can check whether you have the right version by running the following command in MATLAB:
    ```
    spm('version')
    ```

    This should produce the following output:
    ```
    >> spm('version')

    ans =

        'SPM12 (7771)'
    ```

    If SPM is not installed, the output would look like this:
    ```
    >> spm('version')
    Unrecognized function or variable 'spm'.
    ```

2. Install the [`Synthetic Volumes Toolbox`](https://github.com/high-dimensional/synthetic_volumes_toolbox/releases/) for SPM12, by copying its directory to the toolbox folder in your local SPM12 installation: `spm12/toolbox`.

3. Copy the root directory of this GeoSPM repository to your MATLAB directory. We assume it is named `geospm`.

4. Make sure that the following directories are on your MATLAB path in the order shown, so that `geospm` appears before `spm12` (`[...]` stands for the path on your machine where the MATLAB directory is located)

    ```
    [...]/MATLAB/geospm:
    [...]/MATLAB/spm12:
    ```
  To configure your MATLAB path, you can click on the "Set Path" button on the "Home" toolstrip.

5. Quit and restart MATLAB.

6. In the command window type and run:

   ```
   run_geospm_example
   ```

   which will output a list of available examples. Pick one of the examples, and re-run the command. To see the snowflakes example, type:

   ```
   run_geospm_example snowflakes
   ```

   Running an example creates a directory with a timestamp in your current MATLAB directory that contains all files produced by the computation. Colour-mapped images will be in `images` for the regression beta values and the corresponding t-statistic values. Volumetric data will be placed in `spm_output`. The thresholded maps are grouped in subdirectories, starting with `th_1`.
