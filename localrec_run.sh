#!/bin/bash
#

star=run_data_pixcor_dosecor.star      # The data star file which points to your whole particle stacks
subptclno=3             # The number of sub-particles you are extracting i.e. number of masks or cmm vectors
apix=1.070              # The pixel size the data is at
box=384                 # The original particle box size
length=55               # Distance from centre of whole particle to subparticle in Angstroms i.e. average cmm marker length
newbox=384               # The size of the box in which sub-particles will be extracted
project=AP_tN_A1_wt_17Apr05     # The name that will be appended to all sub-particle extractions
ptcldir=Particles_localrec_cor2_62k_224_pixcor # The directory name used for the extracted sub-particles
maskdir=		        # mask location, leave empty for no partial singla subtraction

echo "Woud you like to overwrite any preexisting subparticle extractions?"
read p

if [ $p == "y" ] ; then
  echo "Overwriting preexisting subparticles..."
  rm -rf .localrec*
elif [ $p == "n" ] ; then
  echo "No overwrite. Only doing unfinished subparticle extraction..."
fi

if [ -z $p ] ; then
  echo "Did not understand input, exiting..."
  exit
fi

echo "+++ source_relion1.4"
echo ""

export PATH=${APP_HOME}/relion-1.4/bin:$PATH && export LD_LIBRARY_PATH=${APP_HOME}/relion-1.4/lib:$LD_LIBRARY_PATH


if [ -z $1 ] ; then
  i=1
else
  i=$1
fi

echo ""
echo "The sub-particle count is set to ${subptclno}"
echo ""
echo "You have not specified which sub-particle to start from, so will start from the first"
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
read -p "Press [Enter] key to confirm and run script..."
echo ""

## Set up partilces for relion localized reconstruction
j=$(($subptclno+1))

while [ $i -lt $j ] ; do

  if [[ -e .localrec_${i} ]] ; then
    echo "Skipping localrec subparticle extraction ${i}, already processed"
  else
    if [[ -z $maskdir ]] ; then
      echo "scipion run relion_localized_reconstruction.py --prepare_particles --create_subparticles --align_subparticles --extract_subparticles --sym C1 --cmm cmm_markers/marker${i}.cmm --angpix ${apix} --particle_size ${box} --length ${length} --subparticle_size ${newbox} --output ${ptcldir}/localrec_${project}_${i} ${star}"
      scipion run relion_localized_reconstruction.py --prepare_particles --create_subparticles --align_subparticles --extract_subparticles --sym C1 --cmm cmm_markers/marker${i}.cmm --angpix ${apix} --particle_size ${box} --length ${length} --subparticle_size ${newbox} --output ${ptcldir}/localrec_${project}_${i} ${star}
    else
      echo "scipion run relion_localized_reconstruction.py --prepare_particles --masked_map ${maskdir}/mask${i}_subtraction.mrc  --create_subparticles --align_subparticles --extract_subparticles --sym C1 --cmm cmm_markers/marker${i}.cmm --angpix ${apix} --particle_size ${box} --length ${length} --subparticle_size ${newbox} --output ${ptcldir}/localrec_${project}_${i} ${star}"
      scipion run relion_localized_reconstruction.py --prepare_particles --masked_map ${maskdir}/mask${i}_subtraction.mrc  --create_subparticles --align_subparticles --extract_subparticles --sym C1 --cmm cmm_markers/marker${i}.cmm --angpix ${apix} --particle_size ${box} --length ${length} --subparticle_size ${newbox} --output ${ptcldir}/localrec_${project}_${i} ${star}
    fi
    echo done > .localrec_${i}
  fi

  i=$(($i+1))

done

i=1

while [ $i -lt $j ] ; do

  if [[ -e .localrec_vol_${i} ]] ; then
    echo "Skipping reconstruction ${i}, already processed"
  else
    echo ""
    echo "+++ scipion run relion_localized_reconstruction.py --reconstruct_subparticles --subsym C1 --maxres 15 --output ${ptcldir}/localrec_${project}_${i}"
    scipion run relion_localized_reconstruction.py --reconstruct_subparticles --subsym C1 --maxres 15 --output ${ptcldir}/localrec_${project}_${i}
    echo ""
    echo done > .localrec_vol_${i}
  fi

  i=$(($i+1))

done
