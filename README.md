[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-brainlife.app.576-blue.svg)](https://doi.org/10.25663/brainlife.app.579)

#  Convert surface datatypes to cortexmap datatype 
This app will convert the surface/data and surface/vertices datatypes into a cortexmap datatype. This is intended for easier use with Connectome Workbench, including the viewers.

### Authors
- Brad Caron (bacaron@iu.edu)

### Contributors
- Soichi Hayashi (hayashi@iu.edu)
- Franco Pestilli ([@francopestilli](https://github.com/francopestilli))

### Funding
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-ACI-1916518](https://img.shields.io/badge/NSF_ACI-1916518-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1916518)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://grantome.com/grant/NIH/R01-EB029272-01)


### Citations

We kindly ask that you cite the following articles when publishing papers and code using this code.

1. Avesani, P., McPherson, B., Hayashi, S. et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. Sci Data 6, 69 (2019). https://doi.org/10.1038/s41597-019-0073-y

#### MIT Copyright (c) 2020 brainlife.io The University of Texas at Austin and Indiana University

## Running the App 

### On Brainlife.io

You can submit this App online at [https://doi.org/10.25663/brainlife.app.576](https://doi.org/10.25663/bl.app.576) via the "Execute" tab.

### Running Locally (on your machine)

1. git clone this repo.
2. Inside the cloned directory, create `config.json` with something like the following content with paths to your input files.

```json
{
        "surf_data_left": "./input/surf_data/left.gii",
        "surf_data_right": "./input/surf_data/right.gii",
        "label": "./input/surf_data/label.json",
        "surf_verts_left": "./input/surf_verts/left",
        "surf_verts_right": "./input/surf_verts/right"
}
```

<!-- ### Sample Datasets

You can download sample datasets from Brainlife using [Brainlife CLI](https://github.com/brain-life/cli).

```
npm install -g brainlife
bl login
mkdir input
bl dataset download --id 5b96bbf2059cf900271924f3 && mv 5b96bbf2059cf900271924f3 input/
bl dataset download --id 5967bffa9b45c212bbec8958 && mv 5967bffa9b45c212bbec8958 input/freesurfer
bl dataset download --id 5c5d35e3f5d2a10052842848 && mv 5c5d35e3f5d2a10052842848 input/tensor

``` -->


3. Launch the App by executing `main`

```bash
./main
```

## Output

The main output of this app is a folder entitled 'cortexmap', with the subdirectories 'func', 'label', and 'surf'. 'func' contains the measures mapped to the surface in the form of .func.gii files. 'label' contains the aparc.a2009s labels converted to CARET in the form of .label.gii files. 'surf' contains the surface files, including the midthickness surface, in the form of '.surf.gii' and '.shape.gii' files. This app also outputs a folder entitled 'raw', which contains the derivatives generated during the application. These are intended to be used in either quality assurance or generating figures.

#### Product.json
The secondary output of this app is `product.json`. This file allows web interfaces, DB and API calls on the results of the processing. 

### Dependencies


This App only requires [singularity](https://www.sylabs.io/singularity/) to run. If you don't have singularity, you will need to install following dependencies. If running locally without singularity, just requires a terminal with 'cp' function.
  
#### MIT Copyright (c) 2020 brainlife.io The University of Texas at Austin and Indiana University
