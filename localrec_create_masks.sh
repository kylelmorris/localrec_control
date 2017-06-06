#!/bin/bash
#

#User set variables
export LOCALREC_SCRIPTS='/Users/lfsmbe/Dropbox/Scripts/github/localrec_control/bin'
export CHIMERA_EXE='/Applications/Science/Chimera.app/Contents/MacOS/chimera'
export ini_threshold='0.00283'
export soften='9'

echo ''
echo 'This script is designed to create masks for relion localized reconstruction...'
echo 'It uses UCSF Chimera, an autorefine Relion map the same scale as your raw data and fitted PDBs'
echo ''
echo 'It assumes that your relion autorefine run_class001.mrc map is ./map'
echo 'Masks will be created to exclude all density except for the PDBs contained in ./PDB'
echo ''
echo 'Local rec scripts:  '${LOCALREC_SCRIPTS}
echo 'Chimera executable: '${CHIMERA_EXE}
echo ''
echo 'If your directory structure and files are in place, press [Enter] key to continue...'
echo 'Note, existing cmm_marker, image and mask folders will be deleted'
read p
echo ''

# Get organised
scp -r ${LOCALREC_SCRIPTS}/chimera_localrec_make_masks.py .

rm -rf cmm_markers
rm -rf images
rm -rf masks

# Create initial masks
echo 'Using UCSF Chimera to create initial masks selected by PDBs using scolor'
echo ''

${CHIMERA_EXE} ./chimera_localrec_make_masks.py

# Soften masks
echo 'Softening masks for signal subtraction using Relion...'
echo ''

for f in masks/*subtraction.mrc ; do

  echo "Working on ${f}..."
  file=${f%_subtraction.mrc}
  echo "Basename is $file"
  echo ''
  remaining=$file"_remaining_density.mrc"
  remain_soft_inv=$file"_remaining_density_soft_inv_mask.mrc"
  subtraction_soft=$file"_subtraction_soft.mrc"

  #Soften remaining_density.mrc with relion_mask_create and invert
  relion_mask_create --i ${remaining} --ini_threshold $ini_threshold --width_soft_edge $soften --invert --o ${remain_soft_inv}

  #Multiply inverted softened mask by subtraction.mrc mask to get soft density for subtraction
  relion_image_handler --i $f --multiply ${remain_soft_inv} --o $subtraction_soft

  echo "Created soft mask for signal subtraction: ${subtraction_soft}"
  echo ''

done

echo 'Cleaning up...'
rm -rf chimera_localrec_make_masks.py
rm -rf chimera_localrec_make_masks.pyc

echo ''
echo 'Done!'
echo ''
