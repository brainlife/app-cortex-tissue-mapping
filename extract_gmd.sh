#!/bin/bash

# configurable inputs
5tt=`jq -r '.5tt' config.json`

# extract gmd and make it's own nifti volume
[ ! -f 5tt.mif ] && mrconvert ${5tt} -stride 1,2,3,4,5 5tt.mif -force -nthreads $NCORE

[ ! -f gmd.nii.gz ] && mrconvert -coord 3 0 5tt.mif gmd.nii.gz -force -nthreads $NCORE 