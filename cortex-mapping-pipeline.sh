#!/bin/bash

## This script will create a midthickness surface, map tensor and NODDI values to this surface, and compute stats for each ROI from Freesurfer parcellation

set -x
set -e

#### Set cores ####
OMP_NUM_THREADS=8

#### make directory and copy metric files to folder ####
echo "making directories"
mkdir cortexmap ./cortexmap/cortexmap/
mkdir metric
mkdir ./cortexmap/cortexmap/label
mkdir ./cortexmap/cortexmap/func
mkdir raw
echo "making directories complete"

#### Variables ####
# parse inputs
echo "parsing inputs"
freesurfer=`jq -r '.freesurfer' config.json`
rois=`jq -r '.rois' config.json`
cortexmap=`jq -r '.cortexmap' config.json`
warp=`jq -r '.warp' config.json`
inv_warp=`jq -r '.inverse_warp' config.json`
fsurfparc=`jq -r '.fsurfparc' config.json`
fix_zeros=`jq -r '.fix_zeros' config.json`
volume_smooth_kernel=`jq -r '.volume_smooth_kernel' config.json`
surface_smooth_kernel=`jq -r '.surface_smooth_kernel' config.json`
surface_fwhm=`jq -r '.surface_fwhm' config.json`
smooth_method=`jq -r '.surface_smooth_method' config.json`
projfrac_min=`jq -r '.projfrac_min' config.json`
echo "parsing inputs complete"

# parsing smoothing-related inputs
vsk=""
fb=""
sfwhm=""
projmin=""
if [ ! -z ${volume_smooth_kernel} ]; then
	vsk="--fwhm ${volume_smooth_kernel}"
fi
if [[ ${fix_zeros} == true ]]; then
	fb="-fix-zeros"
fi
if [[ ${surface_fwhm} == true ]]; then
	sfwhm="-fwhm"
fi
if [[ ! -z ${projfrac_min} ]]; then
	projmin=${projfrac_min}
else
	projmin=0
fi

# set hemisphere labels
echo "set hemisphere labels"
HEMI="lh rh"
CARETHemi="L R"
echo "hemisphere labels set"

# if cortexmap already exists, copy
if [[ -f ${cortexmap}/surf/lh.midthickness.native.surf.gii ]]; then
	cp -RL ${cortexmap}/label/* ./cortexmap/cortexmap/label/
	cp -RL ${cortexmap}/surf/* ./cortexmap/cortexmap/surf/
	cp -RL ${cortexmap}/func/* ./cortexmap/cortexmap/func/
	chmod -R +rw ./cortexmap
	cmap_exist=1
else
	cmap_exist=0
fi
# set other variables for ease of scripting
echo "setting useful variables"
if [[ ! ${warp} == 'null' ]]; then
	SPACES="native mni"
	SPACES_DIR=("./cortexmap/cortexmap/surf" "./cortexmap/cortexmap/surf/mni")
else
	SPACES="native"
	SPACES_DIR=("./cortexmap/cortexmap/surf/")
fi

if [[ ${cmap_exist} == 0 ]]; then
	for spaces in ${SPACES_DIR[*]}
	do
		mkdir -p ${spaces}
	done
fi

FUNC_DIR=("./cortexmap/cortexmap/func/")
surfs="pial.surf.gii white.surf.gii"
echo "variables set"

#### copy over rois; set roi_names
if [[ ! -d ./rois ]]; then
	cp -RL ${rois} ./rois
	chmod -R +rw ./rois
	roi_names=(`ls ./rois/`)
fi

#### copy over freesurfer
if [[ ! -d ./output ]]; then
	cp -RL ${freesurfer} ./output
	chmod -R +rw ./output
	freesurfer='./output'
fi

#### identify transform between freesurfer space and anat space. See HCP pipeline for more reference ####
if [ ! -f c_ras.mat ]; then
	echo "identifying transform between freesurfer and anat space"
	MatrixXYZ=`mri_info --cras ${freesurfer}/mri/brain.finalsurfs.mgz`
	MatrixX=`echo ${MatrixXYZ} | awk '{print $1;}'`
	MatrixY=`echo ${MatrixXYZ} | awk '{print $2;}'`
	MatrixZ=`echo ${MatrixXYZ} | awk '{print $3;}'`
	echo "1 0 0 ${MatrixX}" >  c_ras.mat
	echo "0 1 0 ${MatrixY}" >> c_ras.mat
	echo "0 0 1 ${MatrixZ}" >> c_ras.mat
	echo "0 0 0 1"          >> c_ras.mat
fi
echo "transform computed"

#### convert ribbons and surface files ####
# ribbon
echo "converting ribbon files"
[ ! -f ${SPACES_DIR[0]}/ribbon.nii.gz ] && mri_convert ${freesurfer}/mri/ribbon.mgz ${SPACES_DIR[0]}/ribbon.nii.gz

# extract hemispheric ribbons
[ ! -f ./ribbon_lh.nii.gz ] && fslmaths ${SPACES_DIR[0]}/ribbon.nii.gz -thr 3 -uthr 3 -bin ./ribbon_lh.nii.gz
[ ! -f ./ribbon_rh.nii.gz ] && fslmaths ${SPACES_DIR[0]}/ribbon.nii.gz -thr 42 -uthr 42 -bin ./ribbon_rh.nii.gz
echo "converting ribbon files complete"


export SUBJECTS_DIR=./

# hemisphere ribbon and surfaces (obtained directly from HCP PostFreesurfer pipeline and amended for BL: https://github.com/Washington-University/HCPpipelines/blob/master/PostFreeSurfer/scripts/FreeSurfer2CaretConvertAndRegisterNonlinear.sh)
echo "looping through hemispheres and creating appropriate surface files"
for hemi in $HEMI
do
		if [[ ${hemi} == 'lh' ]]; then
			STRUCTURE="CORTEX_LEFT"
		else
			STRUCTURE="CORTEX_RIGHT"
		fi

		for SURFS in $surfs
		do
			# convert files and set structure
			if [ ! -f ${SPACES_DIR[0]}/${hemi}.${SURFS} ]; then
				mris_convert ${freesurfer}/surf/${hemi}.${SURFS::-9} ${SPACES_DIR[0]}/${hemi}.${SURFS}

				# set up gifti structure
				wb_command -set-structure ${SPACES_DIR[0]}/${hemi}.${SURFS} \
					${STRUCTURE} \
					-surface-type ANATOMICAL
			fi

			# apply affine
			[ ! -f ${SPACES_DIR[0]}/${hemi}.cras.${SURFS} ] && wb_command -surface-apply-affine ${SPACES_DIR[0]}/${hemi}.${SURFS} \
				c_ras.mat \
				${SPACES_DIR[0]}/${hemi}.cras.${SURFS}

			if [[ ! ${warp} == 'null' ]]; then
				# apply MNI warp
				[ ! -f ${SPACES_DIR[1]}/${hemi}.mni.${SURFS} ] && wb_command -surface-apply-warpfield ${SPACES_DIR[0]}/${hemi}.cras.${SURFS} ${inv_warp} \
					${SPACES_DIR[1]}/${hemi}.mni.${SURFS} \
					-fnirt \
					${warp}
			fi
		done

		# create midthickness surfaces
		if [ ! -f ${SPACES_DIR[0]}/${hemi}.midthickness.native.surf.gii ]; then 
			wb_command -surface-average \
				${SPACES_DIR[0]}/${hemi}.midthickness.native.surf.gii \
				-surf ${SPACES_DIR[0]}/${hemi}.cras.white.surf.gii \
				-surf ${SPACES_DIR[0]}/${hemi}.cras.pial.surf.gii

			wb_command -set-structure \
				${SPACES_DIR[0]}/${hemi}.midthickness.native.surf.gii \
				${STRUCTURE} \
				-surface-type ANATOMICAL \
				-surface-secondary-type MIDTHICKNESS

			if [[ ! ${warp} == 'null' ]]; then
				[ ! -f ${SPACES_DIR[1]}/${hemi}.midthickness.mni.surf.gii ] && wb_command -surface-apply-warpfield ${SPACES_DIR[0]}/${hemi}.midthickness.native.surf.gii ${inv_warp} \
					${SPACES_DIR[1]}/${hemi}.midthickness.mni.surf.gii \
					-fnirt \
					${warp}
			fi
		fi

		# identify number of vertices for inflation
		NativeVerts=$(wb_command -file-information ${SPACES_DIR[0]}/${hemi}.midthickness.native.surf.gii | grep 'Number of Vertices:' | cut -f2 -d: | tr -d '[:space:]')
        NativeInflationScale=$(echo "scale=4; 0.75 * $NativeVerts / 32492" | bc -l)

        # inflate surfaces
        for spaces in ${SPACES}
        do
        	if [[ ${spaces} == 'native' ]]; then
        		outdir=${SPACES_DIR[0]}
        	else
        		outdir=${SPACES_DIR[1]}
        	fi

	        # inflate native
	        [ ! -f ${outdir}/${hemi}.midthickness.very_inflated.${spaces}.surf.gii ] && wb_command -surface-generate-inflated \
	        	${outdir}/${hemi}.midthickness.${spaces}.surf.gii \
	        	${outdir}/${hemi}.midthickness.inflated.${spaces}.surf.gii \
	        	${outdir}/${hemi}.midthickness.very_inflated.${spaces}.surf.gii \
	        	-iterations-scale $NativeInflationScale
	    done

	    # volume-specific operations
	    volume_name="volume.shape.gii"
	    outdir=${SPACES_DIR[0]}
	    if [ ! -f ${outdir}/${hemi}.${volume_name} ]; then
	    	mris_convert -c ${freesurfer}/surf/${hemi}.volume \
	    		${freesurfer}/surf/${hemi}.white \
	    		${outdir}/${hemi}.${volume_name}

			wb_command -set-structure ${outdir}/${hemi}.${volume_name} \
				${STRUCTURE}

			wb_command -set-map-names ${outdir}/${hemi}.${volume_name} \
				-map 1 ${hemi}_Volume

			wb_command -metric-palette ${outdir}/${hemi}.${volume_name} \
				MODE_AUTO_SCALE_PERCENTAGE \
				-pos-percent 2 98 \
				-palette-name Gray_Interp \
				-disp-pos true \
				-disp-neg true \
				-disp-zero true
			
			wb_command -metric-math "abs(volume)" \
				${outdir}/${hemi}.${volume_name} \
				-var volume \
				${outdir}/${hemi}.${volume_name}

			wb_command -metric-palette ${outdir}/${hemi}.${volume_name} \
				MODE_AUTO_SCALE_PERCENTAGE \
				-pos-percent 4 96 \
				-interpolate true \
				-palette-name videen_style \
				-disp-pos true \
				-disp-neg false \
				-disp-zero false
		fi

		# thickness-specific operations
		thickness_name="thickness.shape.gii"
		outdir=${SPACES_DIR[0]}
		if [ ! -f ${outdir}/${hemi}.${thickness_name} ]; then
			mris_convert -c ${freesurfer}/surf/${hemi}.thickness \
				${freesurfer}/surf/${hemi}.white \
				${outdir}/${hemi}.${thickness_name}

			wb_command -set-structure ${outdir}/${hemi}.${thickness_name} \
				${STRUCTURE}

			wb_command -metric-math "var * -1" ${outdir}/${hemi}.${thickness_name} \
				-var var\
				${outdir}/${hemi}.${thickness_name}

			wb_command -set-map-names ${outdir}/${hemi}.${thickness_name} \
				-map 1 ${hemi}_Thickness

			wb_command -metric-palette ${outdir}/${hemi}.${thickness_name} \
				MODE_AUTO_SCALE_PERCENTAGE \
				-pos-percent 2 98 \
				-palette-name Gray_Interp \
				-disp-pos true \
				-disp-neg true \
				-disp-zero true

			wb_command -metric-math "abs(thickness)" \
				${outdir}/${hemi}.${thickness_name} \
				-var thickness \
				${outdir}/${hemi}.${thickness_name}

			wb_command -metric-palette ${outdir}/${hemi}.${thickness_name} \
				MODE_AUTO_SCALE_PERCENTAGE \
				-pos-percent 4 96 \
				-interpolate true \
				-palette-name videen_style \
				-disp-pos true \
				-disp-neg false \
				-disp-zero false

			wb_command -metric-math "thickness > 0" \
				${outdir}/${hemi}.roi.shape.gii \
				-var thickness \
				${outdir}/${hemi}.${thickness_name}

			wb_command -metric-fill-holes \
				${outdir}/${hemi}.midthickness.native.surf.gii \
				${outdir}/${hemi}.roi.shape.gii \
				${outdir}/${hemi}.roi.shape.gii

			wb_command -metric-remove-islands \
				${outdir}/${hemi}.midthickness.native.surf.gii \
				${outdir}/${hemi}.roi.shape.gii \
				${outdir}/${hemi}.roi.shape.gii

			wb_command -set-map-names \
				${outdir}/${hemi}.roi.shape.gii \
				-map 1 \
				"${hemi}"_ROI
		fi

		# set up aparc.a2009s labels
		if [ ! -f ./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii ]; then
			mris_convert --annot \
				${freesurfer}/label/${hemi}.${fsurfparc}.annot \
				${freesurfer}/surf/${hemi}.pial \
				./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii

			wb_command -set-structure \
				./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii \
				${STRUCTURE}

			wb_command -set-map-names \
				./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii \
				-map 1 \
				"${hemi}"_${fsurfparc}

			wb_command -gifti-label-add-prefix \
				./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii \
				"${hemi}_" \
				./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii
		fi
done
echo "surface files generated"

#### metric surface mapping ####
echo "looping through endpoints and mapping to cortex"
for vol in ${roi_names[*]}
do
	vol_name=`echo ${vol%%.nii.gz}`

	echo "mapping ${vol} to cortex"
	[ ! -f ./metric/${vol}_ribbon.nii.gz ] && mri_vol2vol --mov ./rois/${vol} \
		--targ ${SPACES_DIR[0]}/ribbon.nii.gz \
		--regheader \
		--interp nearest \
		--o ./metric/${vol_name}_ribbon.nii.gz

	# fslmaths ./metric/${vol%%.nii.gz}_ribbon.nii.gz -mul ribbon_lh.nii.gz -bin lh.nii.gz
	# fslmaths ./metric/${vol%%.nii.gz}_ribbon.nii.gz -mul ribbon_rh.nii.gz -bin rh.nii.gz
	# lh_vol=(`fslstats lh.nii.gz -V`)
	# rh_vol=(`fslstats rh.nii.gz -V`)

	# if [[ ${lh_vol} -gt 0 && ${rh_vol} -gt 0 ]]; then
	# 	if [[ ${lh_vol} -le $(( rh_vol+(rh_vol/10) )) && ${lh_vol} -ge $(( rh_vol-(rh_vol/10) )) ]];
	# 	then
	# 		hemis="lh rh"
	# 	elif [[ ${lh_vol} -lt $(( rh_vol+(rh_vol/10) )) ]]; then
	# 		hemis="rh"
	# 	else
	# 		hemis="lh"
	# 	fi
	# fi

	for hemi in ${HEMI}
	do
		if [[ ${hemi} == 'lh' ]]; then
			STRUCTURE="CORTEX_LEFT"
		else
			STRUCTURE="CORTEX_RIGHT"
		fi

		vol_data="./metric/${vol%%.nii.gz}_ribbon.nii.gz"
		outdir=${SPACES_DIR[0]}
		funcdir=${FUNC_DIR[0]}

		# map volumes to surface
		if [ ! -f ${funcdir}/${hemi}.${vol}.func.gii ]; then
			mri_vol2surf --mov ${vol_data} \
				--hemi ${hemi} \
				--surf white \
				--projfrac-max ${projmin} 1 0.1 \
				--regheader $freesurfer \
				--o ${funcdir}/${hemi}.${vol_name}.func.gii ${vsk}
			
			# set structure
			wb_command -set-structure \
				${funcdir}/${hemi}.${vol_name}.func.gii \
				${STRUCTURE}

			# set map name and pallete
			wb_command -set-map-names ${funcdir}/${hemi}.${vol_name}.func.gii \
				-map 1 \
				"$hemi"_"${vol%%.nii.gz}"

			wb_command -metric-palette ${funcdir}/${hemi}.${vol_name}.func.gii \
				MODE_AUTO_SCALE_PERCENTAGE \
				-pos-percent 0 100 \
				-interpolate true \
				-palette-name videen_style \
				-disp-pos true \
				-disp-neg false \
				-disp-zero false
		fi

		# fail out if map is not created
		if [ -f ${funcdir}/${hemi}.${vol_name}.func.gii ]; then
			echo "${hemi} ${vol_name} mapped to cortex"
		else
			echo "${hemi} ${vol_name} failed. check logs"
			exit 1
		fi

		# if user requests the metric to be smoothed on the surface, smooth based on surface kernel
		if [ ! -z ${surface_smooth_kernel} ]; then
			wb_command -metric-smoothing ${outdir}/${hemi}.white.surf.gii \
				${funcdir}/${hemi}.${vol_name}.func.gii \
				${surface_smooth_kernel} \
				${funcdir}/${hemi}.${vol_name}.smooth_${surface_smooth_kernel}.func.gii \
				-method ${smooth_method} ${sfwhm} ${fb}
		fi
	done
	
	# filter based on what should be left vs right hemisphere. get rid of other hemisphere files.
	# need this as sometimes data can be mapped to the incorrect hemisphere
	# need to make this better, but good enough for now
	lh_file=${funcdir}/lh.${vol_name}.func.gii
	rh_file=${funcdir}/rh.${vol_name}.func.gii
	lh_smooth_file=${funcdir}/lh.${vol_name}.smooth_${surface_smooth_kernel}.func.gii
	rh_smooth_file=${funcdir}/rh.${vol_name}.smooth_${surface_smooth_kernel}.func.gii
	cnz_lh=`wb_command -metric-stats ${lh_file} -reduce COUNT_NONZERO`
	cnz_rh=`wb_command -metric-stats ${rh_file} -reduce COUNT_NONZERO`
	total_verts=`wb_command -file-information ${lh_file} -no-map-info | grep -nwi "Number of Vertices" | cut -f3 -d ':' | xargs`
	if [[ ${cnz_lh} -gt 0 || ${cnz_rh} -gt 0 ]] && [[ $(( cnz_lh+cnz_rh )) -ge 10 ]]; then
		if [[ ${vol_name} == *"rh"* ]] || [[ ${vol_name} == *"right"* ]] || [[ ${vol_name} == *"RH"* ]] || [[ ${vol_name} == *"RIGHT"* ]]; then 
			echo "keeping right hemisphere"
			rm -rf ${lh_file}
			if [ -f ${lh_smooth_file} ]; then
				rm -rf ${lh_smooth_file}
			fi
		elif [[ ${vol_name} == *"lh"* ]] || [[ ${vol_name} == *"left"* ]] || [[ ${vol_name} == *"LH"* ]] || [[ ${vol_name} == *"LEFT"* ]]; then
			echo "keeping left hemisphere"
			rm -rf ${rh_file}
			if [ -f ${rh_smooth_file} ]; then
				rm -rf ${rh_smooth_file}
			fi
		elif [[ ${cnz_lh} -le $(( cnz_rh+(cnz_rh/10) )) && ${cnz_lh} -ge $(( cnz_rh-(cnz_rh/10) )) ]]; then 
			echo "keeping both hemispheres"
		elif [[ ${cnz_lh} -lt ${cnz_rh} ]]; then
			echo "keeping right hemisphere"
			rm -rf ${lh_file}
			if [ -f ${lh_smooth_file} ]; then
				rm -rf ${lh_smooth_file}
			fi
		else 
			echo "keeping left hemisphere"
			rm -rf ${rh_file}
			if [ -f ${rh_smooth_file} ]; then
				rm -rf ${rh_smooth_file}
			fi
		fi
	fi
done
