#!/bin/bash
#

####################################################################################
#User VARIABLES
#export LOCALREC_SCRIPTS='/Users/lfsmbe/Dropbox/Scripts/github/localrec_control/bin'
#export CHIMERA_EXE='/Applications/Science/Chimera.app/Contents/MacOS/chimera'

#export LOCALREC_SCRIPTS='/home/kmorris/Dropbox/Scripts/github/localrec_control/bin'
#export CHIMERA_EXE='/usr/bin/chimera'

#export LOCALREC_SCRIPTS=$(which localrec_create_masks.sh | sed 's/\ /\\ /g' | sed 's/(/\\(/g' | sed 's/)/\\)/g' | sed 's/\/localrec_create_masks.sh//g')
#export LOCALREC_SCRIPTS=$(which localrec_create_masks.sh | sed 's/\/localrec_create_masks.sh//g')
export LOCALREC_SCRIPTS=~/Dropbox/Scripts/github/localrec_control

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
  if [[ -d subtracted/${file} ]] ; then 
    echo "subtracted/${file} exists, skipping subtraction..."
  else
    #Do signal subtraction via relion_project
    echo ""
    echo "Creating directory for subtracted particles: subtracted/${file}"
    mkdir -p subtracted/${file}
    echo ""
    echo ">>> relion_project --subtract_exp --i $map --mask $f --ang $starin --o subtracted/${file}/subtracted --ctf --angpix $angpix"
    relion_project --subtract_exp --i $map --mask $f --ang $starin --o subtracted/${file}/subtracted --ctf --angpix $angpix
    echo ""
    echo "Created partial signal subtracted particles: subtracted/${file}/subtracted"
    echo ''
  fi

done

echo ''
echo 'Done!'
echo ''
