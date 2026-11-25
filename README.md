[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-brainlife.app.379-blue.svg)](https://doi.org/10.25663/brainlife.app.379)

# app-cortex-tissue-mapping
This app will map volumated measure files (i.e. tensor, NODDI, myelin) to the cortical surface following procedures outlined in Fukutomi et al (2018; 10.1016/j.neuroimage.2018.02.017) using Connectome Workbench and the minimal preprocessing pipeline of the Human Connectome Project (2013; 10.1016/j.neuroimage.2013.04.127). Specifically, this app generates a mid-thickness surface (i.e. the mid-distance spline between the cortical and pial surfaces) and maps measures to this surface. This surface can be in native space, or, if a warp to a template space is provided, template space. This app needs for inputs: DWI, measure volume files (i.e. tensor, NODDI), freesurfer, and an optional brainmask. If a template surface is requested, the user must input a warp datatype with the warp and inverse warp niftis. See "FSL Anat" for an app that generates these warp files. This app outputs a cortexmap datatype, which contains three folders: func (contains mapped measures to surface), surf (contains all surface derivatives generated, including midthickness surface), and label (contains aparc.a2009s.aseg label niftis). The output surfaces and functional measures can be viewed using the Connectome Workbench viewer.

The code for this app was adapted from HCP's PostFreesurfer pipeline (https://github.com/Washington-University/HCPpipelines/blob/master/PostFreeSurfer/scripts/FreeSurfer2CaretConvertAndRegisterNonlinear.sh) and RIKEN - Brain Connectomics Imaging Laboratory's NoddiSurfaceMapping repository (https://github.com/RIKEN-BCIL/NoddiSurfaceMapping) for use on brainlife.io.

![glasser_ndi](https://github.com/brainlife/app-cortex-tissue-mapping/blob/v1.1/glasser_ndi.png)

### Authors
- Brad Caron (bacaron@iu.edu)

### Contributors
- Soichi Hayashi (hayashi@iu.edu)
- Franco Pestilli ([@francopestilli](https://github.com/francopestilli))

### Funding
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)

### References

Fukutomi, H. et al. Neurite imaging reveals microstructural variations in human cerebral cortical gray matter. Neuroimage (2018). doi:10.1016/j.neuroimage.2018.02.017

Glasser MF, Sotiropoulos SN, Wilson JA, et al. The minimal preprocessing pipelines for the Human Connectome Project. Neuroimage. 2013;80:105-124. doi:10.1016/j.neuroimage.2013.04.127

## Running the App 

### On Brainlife.io

You can submit this App online at [https://doi.org/10.25663/brainlife.app.379](https://doi.org/10.25663/bl.app.379) via the "Execute" tab.

### Running Locally (on your machine)

1. git clone this repo.
2. Inside the cloned directory, create `config.json` with something like the following content with paths to your input files.

```json
{
        "dwi": "./input/dwi/dwi.nii.gz",
        "bval": "./input/dwi/dwi.bvals",
        "bvec": "./input/dwi/dwi.bvecs",
        "freesurfer": "./input/freesurfer/output/.",
        "fa": "./input/tensor/fa.nii.gz",
        "ad": "./input/tensor/ad.nii.gz",
        "md": "./input/tensor/md.nii.gz",
        "rd": "./input/tensor/rd.nii.gz",
        "icvf": "null",
        "isovf": "null",
        "od": "null",
        "brainmask":  "null",
        "warp": "null",
        "inverse_warp": "null"
}
```

### Sample Datasets

You can download sample datasets from Brainlife using [Brainlife CLI](https://github.com/brain-life/cli).

```
npm install -g brainlife
bl login
mkdir input
bl dataset download --id 5b96bbf2059cf900271924f3 && mv 5b96bbf2059cf900271924f3 input/
bl dataset download --id 5967bffa9b45c212bbec8958 && mv 5967bffa9b45c212bbec8958 input/freesurfer
bl dataset download --id 5c5d35e3f5d2a10052842848 && mv 5c5d35e3f5d2a10052842848 input/tensor

```


3. Launch the App by executing `main`

```bash
./main
```

## Output

The main output of this app is a folder entitled 'cortexmap', with the subdirectories 'func', 'label', and 'surf'. 'func' contains the measures mapped to the surface in the form of .func.gii files. 'label' contains the aparc.a2009s labels converted to CARET in the form of .label.gii files. 'surf' contains the surface files, including the midthickness surface, in the form of '.surf.gii' and '.shape.gii' files. This app also outputs a folder entitled 'raw', which contains the derivatives generated during the application. These are intended to be used in either quality assurance or generating figures.

#### Product.json
The secondary output of this app is `product.json`. This file allows web interfaces, DB and API calls on the results of the processing. 

### Dependencies

This App requires the following libraries when run locally.

  - singularity: https://singularity.lbl.gov/
  - FSL: https://hub.docker.com/r/brainlife/fsl/tags/5.0.9
  - Freesurfer: https://hub.docker.com/r/brainlife/freesurfer/tags/6.0.0
  - jsonlab: https://github.com/fangq/jsonlab.git
  - Connectome Workbench: https://hub.docker.com/r/brainlife/connectome_workbench
  
