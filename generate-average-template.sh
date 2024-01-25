#!/bin/bash

# set configurable inputs
inputs=($(jq -r '.inputs' config.json  | tr -d '[]," '))
threshold=`jq -r '.threshold' config.json`
dilate=`jq -r '.dilate' config.json`

# identify number of inputs
num_inputs=`echo ${#inputs[@]}`

# set hemispheres
hemispheres="lh rh"

# need to update this to grab all files and remove duplicates in cases where first input doesn't have all the func files from the other inputs
func_files=`ls ${inputs[0]}/func/`
surf_files=`ls ${inputs[0]}/surf/`
label_files=`ls ${inputs[0]}/label/`

# make output directory
[ ! -d ./cortexmap/ ] && mkdir -p cortexmap cortexmap/cortexmap cortexmap/cortexmap/surf cortexmap/cortexmap/func cortexmap/cortexmap/label

# native space surfaces
for surf in ${surf_files}
do
    if [[ ${surf} == *".surf.gii" ]]; then
        echo "surface - ${surf}"
        tmp_command=""
        for i in ${inputs[*]}
        do
            tmp_command="$tmp_command -surf `echo ${i}/surf/${surf}`"
        done

        wb_command -surface-average ./cortexmap/cortexmap/surf/${surf} ${tmp_command}
    elif [[ ${surf} == *".shape.gii" ]]; then
        echo "surface - ${surf}"

        # sum first two files
        wb_command -metric-math '(x+y)' ./cortexmap/cortexmap/surf/${surf} -var 'x' ${inputs[0]}/surf/${surf} -var 'y' ${inputs[1]}/surf/${surf}

        # if more than two, sum remaining
        if [ ${num_inputs} -gt 2 ]; then
            for (( i=2; i<${num_inputs}; i++ ))
            do 
                wb_command -metric-math '(x+y)' ./cortexmap/cortexmap/surf/${surf} -var 'x' ./cortexmap/cortexmap/surf/${surf} -var 'y' ${inputs[$i]}/surf/${surf}
            done
        fi

        # compute average
        tmp_command="wb_command -metric-math '(x/${num_inputs})' ./cortexmap/cortexmap/surf/${surf} -var 'x' ./cortexmap/cortexmap/surf/${surf}"
        eval `echo $tmp_command`

        # update header info
        wb_command -metric-palette ./cortexmap/cortexmap/surf/${surf} \
            MODE_AUTO_SCALE_PERCENTAGE \
            -pos-percent 4 96 \
            -interpolate true \
            -palette-name videen_style \
            -disp-pos true \
            -disp-neg false \
            -disp-zero false
    fi
done

# if mni directory is there, generate average mni surface
if [ -d ${inputs[0]}/surf/mni ]; then

    mni_surf_files=`ls ${inputs[0]}/surf/mni/`
    [ ! -d ./cortexmap/surf/mni ] && mkdir -p cortexmap/cortexmap/surf/mni

    for surf in ${mni_surf_files}
    do
        if [[ ${surf} == *".surf.gii" ]]; then
            echo "mni surface - ${surf}"

            tmp_command=""
            for i in ${inputs}
            do
                tmp_command="$tmp_command -surf `echo ${i}/surf/mni/${surf}`"
            done

            wb_command -surface-average ./cortexmap/cortexmap/surf/mni/${surf} ${tmp_command}
        fi
    done
fi

# loop through functional files and average
for func in ${func_files}
do
    echo "generating average for ${func}"
    
    # sum first two files
    number_of_func_subjects=1
    if [ -f ${inputs[1]}/func/${func} ]; then
        wb_command -metric-math '(x+y)' ./cortexmap/cortexmap/func/${func} -var 'x' ${inputs[0]}/func/${func} -var 'y' ${inputs[1]}/func/${func}
        number_of_func_subjects=$((number_of_func_subjects+1))
    else
        cp ${inputs[0]}/func/${func} ./cortexmap/cortexmap/func/${func}
    fi
    
    # if more than two, sum remaining
    if [ ${num_inputs} -gt 2 ]; then
        for (( i=2; i<${num_inputs}; i++ ))
        do 
            if [ -f ${inputs[$i]}/func/${func} ]; then
                wb_command -metric-math '(x+y)' ./cortexmap/cortexmap/func/${func} -var 'x' ./cortexmap/cortexmap/func/${func} -var 'y' ${inputs[$i]}/func/${func}
                number_of_func_subjects=$((number_of_func_subjects+1))
            fi
        done
    fi

    # compute average
    tmp_command="wb_command -metric-math '(x/${number_of_func_subjects})' ./cortexmap/cortexmap/func/${func} -var 'x' ./cortexmap/cortexmap/func/${func}"
    eval `echo $tmp_command`

    #wb_command -metric-math 'x/${num_inputs}' ./cortexmap/cortexmap/func/${func} -var 'x' ./cortexmap/cortexmap/func/${func}

    # update header info
    wb_command -metric-palette ./cortexmap/cortexmap/func/${func} \
        MODE_AUTO_SCALE_PERCENTAGE \
        -pos-percent 4 96 \
        -interpolate true \
        -palette-name videen_style \
        -disp-pos true \
        -disp-neg false \
        -disp-zero false
done

# loop through parcellations and average
for labs in ${label_files}
do
    echo "generating average for ${labs}"

    # merge all labels together
    first_line="-label ${inputs[0]}/label/${labs} -column 1"
    second_line=" -label ${inputs[1]}/label/${labs}"
    label_name=`echo ${labs%%.label.gii}`
    if [[ ${label_name} == *".native" ]]; then
        label_name=`echo ${label_name%%.native}`
    fi
    
    if [ ${num_inputs} -gt 2 ]; then
        for (( i=2; i<${num_inputs}; i++ ))
        do
            second_line=$second_line" -label ${inputs[$i]}/label/${labs}"
        done
    fi

    # merge labels
    wb_command -label-merge ./${label_name}.merged.label.gii ${first_line}${second_line}

    # compute probability
    wb_command -label-probability ./${label_name}.merged.label.gii ./${label_name}.probability.func.gii -exclude-unlabeled

    # threshold
    tmp_command="wb_command -metric-math '(x>${threshold})' ./${label_name}.mask.shape.gii -var 'x' ./${label_name}.probability.func.gii"
    eval `echo $tmp_command`
    #wb_command -metric-math "(x>${threshold})" ./${label_name}.mask.shape.gii -var 'x' ./${label_name}.probability.func.gii

    # export label table so we can import
    wb_command -label-export-table ${inputs[0]}/label/${labs} ./${label_name}.lut.txt

    # loop through roi names and multiply ROI binary by parcel ID value
    names=(`wb_command -file-information ./${label_name}.mask.shape.gii -only-map-names`)
    for (( i=0; i<${#names[@]}; i++ ))
    do
        j=$((i+1))
        tmp_command="wb_command -metric-math 'x*${j}' ${label_name}.${names[$i]}.shape.gii -var 'x' ./${label_name}.mask.shape.gii -column ${names[$i]}"
        eval `echo $tmp_command`
        #wb_command -metric-math "x * (${i}+1)" ${label_name}.${names[$i]}.shape.gii -var 'x' ./${label_name}.mask.shape.gii -column ${names[$i]}
    done

    # combine all rois to one file
    for (( i=0; i<${#names[@]}; i++ ))
    do 
        if [ ${i} -eq 0 ]; then 
            wb_command -metric-math 'x + y' ${label_name}.merge.func.gii -var 'x' ${label_name}.${names[$i]}.shape.gii -var 'y' ${label_name}.${names[$((i+1))]}.shape.gii
        elif [ ${i} -eq 1 ]; then 
            echo "done"
        else 
            wb_command -metric-math 'x + y' ${label_name}.merge.func.gii -var 'x' ${label_name}.merge.func.gii -var 'y' ${label_name}.${names[$i]}.shape.gii
        fi
    done

    # dilate merged average parcellation
    if [ -d ${inputs[0]}/surf/mni ]; then
        wb_command -metric-dilate ${label_name}.merge.func.gii ${inputs[0]}/surf/mni/${labs%%.aparc*}.midthickness.mni.surf.gii ${dilate} ${label_name}.merge.dilate.func.gii -nearest
    else
        wb_command -metric-dilate ${label_name}.merge.func.gii ${inputs[0]}/surf/${labs%%.aparc*}.midthickness.*.surf.gii ${dilate} ${label_name}.merge.dilate.func.gii -nearest
    fi

    # import lut table
    wb_command -metric-label-import ${label_name}.merge.dilate.func.gii ./${label_name}.lut.txt ./cortexmap/cortexmap/label/${label_name}.group.label.gii
    
    # set map name
    wb_command -set-map-name ./cortexmap/cortexmap/label/${label_name}.group.label.gii 1 "${label_name}"
done

# file check
func_files=(${func_files})
num_files=`echo ${#func_files[@]}`
if [ ! -f ./cortexmap/cortexmap/func/${func_files[$num_files-1]} ]; then
    echo "something went wrong. check derivatives and logs"
    exit 1
else
    echo "resampling complete"
    rm -rf *.gii *.lut.txt
    exit 0
fi
