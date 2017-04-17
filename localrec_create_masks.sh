#!/bin/bash
#

export LOCALREC_SCRIPTS='/home/kmorris/Dropbox/Scripts/github/localrec_control/bin'
export CHIMERA_EXE='/usr/local/bin/chimera'

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

scp -r ${LOCALREC_SCRIPTS}/chimera_localrec_make_masks.py .

rm -rf cmm_markers
rm -rf images
rm -rf masks

${CHIMERA_EXE} ./chimera_localrec_make_masks.py

echo 'Cleaning up...'
rm -rf chimera_localrec_make_masks.py
rm -rf chimera_localrec_make_masks.pyc

echo ''
echo 'Done!'
echo ''
