#!/bin/bash
#

####################################################################################
# Variables
exe=$0
path=$(which ${0})
# Program path, name and extension
ext=$(echo ${path##*.})
name=$(basename $path .${ext})
dir=$(dirname $path)
# Program paths
export LOCALREC_SCRIPTS=${dir}
export CHIMERA_EXE=$(which chimera)

####################################################################################

starin=$1
map=$2
angpix=$3
box=$4

if [[ -z $1 ]] ; then

  echo ""
  echo "Variables empty, usage is $(basename $0) (1) (2) (3) (4)"
  echo ""
  echo "(1) = Input star file"
  echo "(2) = map to project from for singal subtraction"
  echo "(3) = angpix"
  echo "(4) = box size (optional)"
  echo ""
  exit

fi

####################################################################################

mkdir -p bin
echo "Script location for copying: "${LOCALREC_SCRIPTS}
scp -r $0 bin
scp -r ${LOCALREC_SCRIPTS}/bin/relion_star_2_to_1.4.py bin

####################################################################################

#Resizing map for projections if requested
if [[ -z $4 ]] ; then
  echo "Keep projection volume at original size"
else
  file=$(basename $map .mrc)
  resized=${file}_resized.mrc
  echo "Projection volume resize requested, using relion_image_handler to resize..."
  echo ">>> relion_image_handler --i ${map} --o map/${resized} --new_box ${box}"
  relion_image_handler --i ${map} --o map/${resized} --new_box ${box}
  map=map/$resized
fi

# Create partial signal subtracted particles ready for localrec subparticle extraction
echo 'Using relion_project to create partial signal subtracted particles for locarec subparticle extraction'
echo ''

for f in masks/*subtraction_soft_mask.mrc ; do

  echo "Working on ${f}..."
  file=${f%_subtraction_soft_mask.mrc}
  echo "Basename is $file"
  echo ''

  #Check if file already exists
  if [[ -d Subtract/${file} ]] ; then
    echo "Subtract/${file} exists, skipping subtraction..."
  else
    #Do signal subtraction via relion_project
    echo ""
    echo "Creating directory for subtracted particles: Subtract/${file}"
    mkdir -p Subtract/${file}
    echo ""
    echo ">>> relion_project --subtract_exp --i $map --mask $f --ang $starin --o Subtract/${file}/subtracted --ctf --angpix $angpix"
    relion_project --subtract_exp --i $map --mask $f --ang $starin --o Subtract/${file}/subtracted --ctf --angpix $angpix
    echo ""
    echo "Created partial signal subtracted particles: Subtract/${file}/subtracted"
    echo ''
  fi

done

echo ''
echo 'Done!'
echo ''
