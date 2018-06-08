#!/bin/bash
#

subptcli=$1

# The data star file which points to your whole particle stacks
star=star/run_data_rln1.4.star
# The number of sub-particles you are extracting i.e. number of masks or cmm vectors
subptclno=32
# The pixel size the data is at
apix=1.705
# The original particle box size
box=750
# Distance from centre of whole particle to subparticle in Angstroms i.e. average cmm marker length
# Set to auto and the distance will be pulled from the cmm marker marker log file in ./cmm_markers
length=auto
# The size of the box in which sub-particles will be extracted
newbox=256
# The name that will be appended to all sub-particle extractions
project=CHC_LMB_all_localrec_1761ptcl
# The directory name used for the extracted sub-particles
ptcldir=Particles_localrec_cor2_256px_1761ptcl_nopflip
# mask location, leave empty for no partial singla subtraction
maskdir=
#Original reconstruction resolution (for lowpass filtering final volumes)
res=20
#CTF correction behaviour
ctf="--ctf"

#start at subparticle number
if [ -z $1 ] ; then
  i=1
else
  i=$1
fi

#Important info
echo ""
echo "The sub-particle count is set to ${subptclno}"
echo ""
echo "Will start at sub-particle       " $i
echo ""
echo 'Input star:                      ' $star
echo 'Subparticle no:                  ' $subptclno
echo 'apix:                            ' $apix
echo 'Input box size (px):             ' $box
echo 'Vector length to subparticle (A):' $length
echo 'New box size (px):               ' $newbox
echo 'Project name:                    ' $project
echo 'Subparticle directory name:      ' $ptcldir
echo 'Masks for subtraction location:  ' $maskdir
echo ""
echo "Relion version currently sourced:"
which relion
echo ""
read -p "Press [Enter] key to confirm and run script..."
echo ""

echo "Would you like to overwrite any preexisting subparticle extractions (y/n)?"
read p

## Set up job monitoring
if [[ -f .localrec_vol_progress ]] ; then
  echo ".localrec_vol_progress exists"
else
  echo ".localrec_vol_progress does not exist"
  echo "Localrec subparticle reconstruction progress:" > .localrec_vol_progress
fi

## Overwrite or not
if [ $p == "y" ] ; then
  echo "Overwriting preexisting subparticles..."
  sed -i "/${ptcldir}/d" .localrec_vol_progress
  echo ""
elif [ $p == "n" ] ; then
  echo "No overwrite. Only doing unfinished subparticles not listed in .localrec_vol_progress..."
  echo ""
fi

if [ -z $p ] ; then
  echo "Did not understand input, exiting..."
  exit
fi

## Set up partilces for relion localized reconstruction
j=$(($subptclno+1))

while [[ $i -lt $j ]] ; do

  localrec_vol_progress=$(grep ${ptcldir} .localrec_vol_progress | grep localrec_vol_${i})

  if [[ -n $localrec_vol_progress ]] ; then
    echo $localrec_vol_progress
    echo "Skipping reconstruction ${i}, already processed"
    echo ""
  else
    #echo ""
    #echo "+++ scipion run relion_localized_reconstruction.py --reconstruct_subparticles --subsym C1 --maxres 15 --output ${ptcldir}/localrec_${project}_${i}"
    #scipion run relion_localized_reconstruction.py --reconstruct_subparticles --subsym C1 --maxres 15 --output ${ptcldir}/localrec_${project}_${i}
    #echo ""
    echo "running relion reconstruct on localrec subparticles:"
    echo "+++ relion_reconstruct --i ${ptcldir}/localrec_${project}_${i}.star --o ${ptcldir}/localrec_${project}_${i}.mrc --angpix $apix --sym C1 --maxres 8 ${ctf}"
    relion_reconstruct --i ${ptcldir}/localrec_${project}_${i}.star --o ${ptcldir}/localrec_${project}_${i}.mrc --angpix $apix --sym C1 --maxres 8 ${ctf}
    echo ""
    echo "+++ relion_image_handler --angpix $apix --lowpass $res --i ${ptcldir}/localrec_${project}_${i}.mrc"
    relion_image_handler --angpix $apix --lowpass $res --i ${ptcldir}/localrec_${project}_${i}.mrc
    echo ""
    echo "${ptcldir} localrec_vol_${i}: completed reconstruction" >> .localrec_vol_progress
  fi

  i=$(($i+1))

done

## Make a copy of the script so that there is a record
scp -r $0 $ptcldir
echo ""
echo "Copy of this script made in subparticle directory: ${ptcldir}"
