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
export CHIMERA_EXE=$(which chimera)

ini_threshold=$1 # ini-threshold for use on remaining density to soften subtraction mask
extend=$2
soften=$3

if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]] ; then

  echo ""
  echo "Variables empty, usage is localrec_create_masks.sh (1) (2) (3)"
  echo ""
  echo "(1) = Input volume threshold"
  echo "(2) = Extend mask by n pixels (4)"
  echo "(3) = Soften mask by n pixels (9)"
  exit

fi

####################################################################################
# Get organised
rm -rf images
rm -rf masks

mkdir -p bin
echo "Script location for copying: "${LOCALREC_SCRIPTS}
scp -r ${LOCALREC_SCRIPTS}/bin/chimera_localrec_make_masks.py bin
scp -r ${LOCALREC_SCRIPTS}/localrec_create_subtraction_masks.sh bin

#Save these parameters to file for note taking
printf "localrec_create_masks parameters\n" > localrec_create_masks.out
printf "Input volume threshold: $ini_threshold\n" >> localrec_create_masks.out
printf "Extend mask by n pixels: $extend\n" >> localrec_create_masks.out
printf "Soften mask by n pixels: $soften\n" >> localrec_create_masks.out

####################################################################################

echo ''
echo 'This script is designed to create masks for relion localized reconstruction...'
echo 'It uses UCSF Chimera, an autorefine Relion map the same scale as your raw data and fitted PDBs'
echo ''
echo 'It assumes that your relion autorefine run_class001.mrc map is ./map'
echo 'Softened volumes will be created to include all density except for the PDBs contained in ./PDB'
echo 'These are suitable for signal subtracion in relion localized reconstruction'
echo ''
echo 'Local rec scripts:  '${LOCALREC_SCRIPTS}
echo 'Chimera executable: '${CHIMERA_EXE}
echo ''
echo 'If your directory structure and files are in place, press [Enter] key to continue...'
echo 'Note, existing cmm_marker, image and mask folders will be deleted'
read p
echo ''

# Create initial masks
echo 'Using UCSF Chimera to create initial masks selected by PDBs using scolor'
echo ''

scp -r bin/chimera_localrec_make_masks.py .
${CHIMERA_EXE} chimera_localrec_make_masks.py ${radius}

# Soften masks
echo 'Softening masks for signal subtraction using Relion...'
echo ''

for f in masks/*subtraction.mrc ; do

  echo "Working on ${f}..."
  file=${f%_subtraction.mrc}
  echo "Basename is $file"
  echo ''
  remaining=$file"_subtraction.mrc"                 #used to be *remaining_density.mrc
  remain_soft=$file"_subtraction_soft_mask.mrc"
  subtraction_soft=$file"_subtraction_soft.mrc"

  #Soften subtraction.mrc with relion_mask_create
  echo ""
  echo ">>> relion_mask_create --i ${remaining} --ini_threshold $ini_threshold --extend_inimask $extend --width_soft_edge $soften --o ${remain_soft}"
  relion_mask_create --i ${remaining} --ini_threshold $ini_threshold --extend_inimask $extend --width_soft_edge $soften --o ${remain_soft}
  #Soften subtraction.mrc with relion_mask_create and invert
  #relion_mask_create --i ${remaining} --ini_threshold $ini_threshold --width_soft_edge $soften --invert --o ${remain_soft}

  #Multiply inverted softened mask by subtraction.mrc mask to get soft density for subtraction
  echo ""
  echo ">>> relion_image_handler --i map/*.mrc --multiply ${remain_soft} --o $subtraction_soft"
  relion_image_handler --i map/*.mrc --multiply ${remain_soft} --o $subtraction_soft

  echo ""
  echo "Created soft mask for signal subtraction: ${subtraction_soft}"
  echo ''

done

echo ''
echo 'Done!'
echo ''
