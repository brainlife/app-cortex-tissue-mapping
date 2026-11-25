[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-brainlife.app.159-blue.svg)](https://doi.org/10.25663/brainlife.app.159)

# app-cortex-tissue-mapping
This app will map volumated measure files (i.e. tensor, NODDI) to the cortical surface following Fukutomi et al (2018; 10.1016/j.neuroimage.2018.02.017) using Connectome Workbench. This app needs for inputs: DWI, measure volume files (i.e. tensor (optional), NODDI (optional)), freesurfer, and a smoothing sigma value. This app outputs a cortexmap datatype, which contains three folders: func (contains mapped measures to surface), surf (contains all surface derivatives generated, including midthickness surface), and label (contains aparc.a2009s.aseg label niftis). 

### Authors
- Brad Caron (bacaron@iu.edu)

### Contributors
- Soichi Hayashi (hayashi@iu.edu)
- Franco Pestilli ([@francopestilli](https://github.com/francopestilli))

### Funding
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)

## Running the App 

### On Brainlife.io

You can submit this App online at [https://doi.org/10.25663/brainlife.app.159](https://doi.org/10.25663/bl.app.159) via the "Execute" tab.

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
        "sigma":  "5/3"
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

The main output of this App is DWI datatype and a mask datatype.

#### Product.json
The secondary output of this app is `product.json`. This file allows web interfaces, DB and API calls on the results of the processing. 

### Dependencies

This App requires the following libraries when run locally.

  - singularity: https://singularity.lbl.gov/
  - FSL: https://hub.docker.com/r/brainlife/fsl/tags/5.0.9
  - jsonlab: https://github.com/fangq/jsonlab.git
  - Connectome Workbench: https://hub.docker.com/r/brainlife/connectome_workbench
  
### References

Fukutomi, H. et al. Neurite imaging reveals microstructural variations in human cerebral cortical gray matter. Neuroimage (2018). doi:10.1016/j.neuroimage.2018.02.017
