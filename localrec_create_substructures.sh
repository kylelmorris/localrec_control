#!/bin/bash
#

subptcli=$1

# Get user variables
if [[ -f ./.user_input ]] ; then
  echo ""
  echo "Previous user input found."
  echo ""
  cat ./.user_input
  echo ""
  star=$(cat .user_input | grep lrStar | awk '{print $2}')
  subptclno=$(cat .user_input | grep lrSubptclno | awk '{print $2}')
  apix=$(cat .user_input | grep lrApix | awk '{print $2}')
  box=$(cat .user_input | grep lrBox | awk '{print $2}')
  length=$(cat .user_input | grep lrLength | awk '{print $2}')
  newbox=$(cat .user_input | grep lrNewbox | awk '{print $2}')
  project=$(cat .user_input | grep lrProject | awk '{print $2}')
  ptcldir=$(cat .user_input | grep lrPtcldir | awk '{print $2}')
  maskdir=$(cat .user_input | grep lrMaskdir | awk '{print $2}')
  res=$(cat .user_input | grep lrResolution | awk '{print $2}')
  ctf=$(cat .user_input | grep lrCtf | awk '{print $2}')
  echo "Press Enter to continue or ctrl-c to quit and delete .user_input"
  read p
else
  echo "LocalRec parameters" > .user_input
  echo "Data star file which points to your whole particle stacks. i.e. ./star/run_data.star"
  read star
  echo "lrStar: ${star}" >> .user_input
  echo "The number of sub-particles you are extracting i.e. number of masks or cmm vectors"
  read subptclno
  echo "lrSubptclno: ${subptclno}" >> .user_input
  echo "The pixel size of the data"
  read apix
  echo "lrApix: ${apix}" >> .user_input
  echo "Original particle box size (px)"
  read box
  echo "lrBox: ${box}" >> .user_input
  echo "Distance from centre of whole particle to subparticle in Angstroms i.e. average cmm marker length"
  echo "Can set to auto"
  read length
  echo "lrLength: ${length}" >> .user_input
  echo "The size of the box in which sub-particles will be extracted (px)"
  read newbox
  echo "lrNewbox: ${newbox}" >> .user_input
  echo "The name that will be appended to all sub-particle extractions"
  read project
  echo "lrProject: ${project}" >> .user_input
  echo "The directory name used for the extracted sub-particles"
  read ptcldir
  echo "lrPtcldir: ${ptcldir}" >> .user_input
  echo "Mask location, leave empty for no partial singla subtraction"
  read maskdir
  echo "lrMaskdir: ${maskdir}" >> .user_input
  echo "Original reconstruction resolution (for lowpass filtering subparticle volumes)"
  read res
  echo "lrResolution: ${res}" >> .user_input
  echo "CTF correction behaviour for subparticle volumes, provide --ctf or blank"
  read ctf
  echo "lrCtf: ${ctf}" >> .user_input
fi

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

## Timestamp function
function timestamp() {
  date +%F_%T
}

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
    echo "${ptcldir} localrec_vol_${i}: completed reconstruction: $(timestamp)" >> .localrec_vol_progress
  fi

  i=$(($i+1))

done

## Make a copy of the script so that there is a record
scp -r $0 $ptcldir
echo ""
echo "Copy of this script made in subparticle directory: ${ptcldir}"
