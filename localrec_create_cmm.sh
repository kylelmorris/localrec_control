#!/bin/bash
#

####################################################################################
# Variables
exe=$0
path=$(which ${0})

ext=$(echo ${path##*.})
name=$(basename $path .${ext})
dir=$(dirname $path)

export LOCALREC_SCRIPTS=${dir}
export CHIMERA_EXE=$(which chimera)

####################################################################################
# Get organised
rm -rf cmm_markers
rm -rf bin
rm -rf chimera_localrec_make_cmm.py*

mkdir bin
echo "Script location for copying: "${LOCALREC_SCRIPTS}
scp -r ${LOCALREC_SCRIPTS}/bin/chimera_localrec_make_cmm.py bin
scp -r ${LOCALREC_SCRIPTS}/localrec_create_cmm.sh bin
scp -r ${LOCALREC_SCRIPTS}/localrec_create_subparticles.sh bin

####################################################################################

echo ''
echo 'This script is designed to cmm markers for relion localized reconstruction...'
echo 'It uses UCSF Chimera, an autorefine Relion map the same scale as your raw data and fitted PDBs'
echo ''
echo 'It assumes that your relion autorefine run_class001.mrc map is ./map'
echo 'Cmm markers will be created to create vectors to the PDBs contained in ./PDB'
echo ''
echo 'Local rec scripts:  '${LOCALREC_SCRIPTS}
echo 'Chimera executable: '${CHIMERA_EXE}
echo ''
echo 'If your directory structure and files are in place, press [Enter] key to continue...'
echo 'Note, existing cmm_marker folders will be deleted'
echo ''
echo 'Hit Enter to continue or ctrl-c to quit...'
read p
echo ''

# Create initial masks
echo 'Using UCSF Chimera to create cmm marker vectors describing subparticle locations'
echo ''

ln -s bin/chimera_localrec_make_cmm.py .
${CHIMERA_EXE} chimera_localrec_make_cmm.py

#Find out the average length to the cmm marker
echo "Average distance between centre of map and centre of PDB, i.e. cmm marker distance is:"
#cat cmm_markers/*log | awk '{print $11}' | sed '/^$/d' | awk -F : '{sum+=$1} END {print "AVG=",sum/NR}'
stats=$(cat cmm_markers/*log | grep "minimum distance" | awk '{print $8'} | sed '/^$/d' | awk -F ', '  '{   sum=sum+$1 ; sumX2+=(($1)^2)} END { printf "Average: %f. Standard Deviation: %f \n", sum/NR, sqrt(sumX2/(NR) - ((sum/NR)^2) )}')
echo ''
echo $stats
echo "Average distance between centre of map and centre of PDB, i.e. cmm marker distance is:" > cmm_markers/marker_distance_stats.log
echo $stats >> cmm_markers/marker_distance_stats.log
echo 'See log files for individual measurements...'

echo ''
echo 'Inspect the markers in chimera!'
echo 'Yellow is centre and blue the subparticle'
echo ''

#Make PDB copy
scp -r PDB cmm_markers/PDB
#Tidy up the logs
mkdir -p cmm_markers/logs
mv cmm_markers/*log cmm_markers/logs

echo ''
echo 'Done!'
echo ''
