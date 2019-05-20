#!/bin/bash
#

subptcli=$1

# Get user variables
if [[ -f ./.user_input ]] ; then
  echo ""
  echo "Previous user input found."
  echo "Press Enter to continue or ctrl-c to quit and delete .user_input"
  echo ""
  cat ./.user_input
  echo ""
  read p
  star=$(cat .user_input | grep star | awk '{print $2}')
  subptclno=$(cat .user_input | grep subptclno | awk '{print $2}')
  apix=$(cat .user_input | grep apix | awk '{print $2}')
  box=$(cat .user_input | grep box | awk '{print $2}')
  length=$(cat .user_input | grep length | awk '{print $2}')
  newbox=$(cat .user_input | grep newbox | awk '{print $2}')
  project=$(cat .user_input | grep project | awk '{print $2}')
  ptcldir=$(cat .user_input | grep ptcldir | awk '{print $2}')
  maskdir=$(cat .user_input | grep maskdir | awk '{print $2}')
else
  echo "LocalRec parameters" > .user_input
  echo "Data star file which points to your whole particle stacks. i.e. ./star/run_data.star"
  read star
  echo "star: ${star}" >> .user_input
  echo "The number of sub-particles you are extracting i.e. number of masks or cmm vectors"
  read subptclno
  echo "subptclno: ${subptclno}" >> .user_input
  echo "The pixel size of the data"
  read apix
  echo "apix: ${apix}" >> .user_input
  echo "Original particle box size (px)"
  read box
  echo "box ${box}" >> .user_input
  echo "Distance from centre of whole particle to subparticle in Angstroms i.e. average cmm marker length"
  echo "Can set to auto"
  read length
  echo "length ${length}" >> .user_input
  echo "The size of the box in which sub-particles will be extracted (px)"
  read newbox
  echo "newbox ${newbox}" >> .user_input
  echo "The name that will be appended to all sub-particle extractions"
  read project
  echo "project ${project}" >> .user_input
  echo "The directory name used for the extracted sub-particles"
  read ptcldir
  echo "ptcldir ${ptcldir}" >> .user_input
  echo "Mask location, leave empty for no partial singla subtraction"
  read maskdir
  echo "maskdir ${maskdir}" >> .user_input
fi

#start at subparticle number
if [ -z $1 ] ; then
  i=1
else
  i=$1
fi

#Inform that cmm_marker lengths will be pulled from log files
if [[ $length == auto ]] ; then
  echo "Sub-particle length is set to auto..."
  echo "Subparticle length parameter will be pulled from ./cmm_markers/logs/*log files"
  if [[ -f ./cmm_markers/logs/marker_distance_stats.log ]] ; then
    echo ""
    echo "marker_distance_stats.log exists, proceeding"
    echo ""
    cat ./cmm_markers/logs/marker_distance_stats.log
    echo ""
  else
    echo ""
    echo "marker_distance_stats.log does not exist, are you sure you want to continue?"
    read p
  fi
else
  echo "Sub-particle length is set manually to ${length}..."
fi

## Check for relion1.4
command -v relion >/dev/null 2>&1 || { echo >&2 "Relion does not appear to be installed or sourced..."; exit 1; }
exe=$(which relion | grep 1.4)
if [[ -z ${exe} ]]; then
  echo 'Relion installation:'
  which relion
  echo ''
  echo 'Path does not contain 1.4, are you sure this is Relion-1.4?'
  echo 'Press Enter to continue or ctrl-c to quit and fix your Relion version'
  read p
else
  echo 'Relion installation:'
  which relion
  echo 'Found 1.4 in path, appears to be Relion-1.4'
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

echo "Woud you like to overwrite any preexisting subparticle extractions (y/n)?"
read p

## Set up job monitoring
if [[ -f .localrec_progress ]] ; then
  echo ".localrec_progress exists"
else
  echo ".localrec_progress does not exist"
  echo "Localrec subparticle extraction progress:" > .localrec_progress
fi

## Timestamp function
function timestamp() {
  date +%F_%T
}

## Overwrite or not
if [ $p == "y" ] ; then
  echo "Overwriting preexisting subparticles..."
  sed -i "/${ptcldir}/d" .localrec_progress
  echo ""
elif [ $p == "n" ] ; then
  echo "No overwrite. Only doing unfinished subparticle extraction..."
  echo ""
fi

if [ -z $p ] ; then
  echo "Did not understand input, exiting..."
  exit
fi

## Set up partilces for relion localized reconstruction
j=$(($subptclno+1))

if [[ $length == auto ]] ; then
  autolength=1
fi

while [ $i -lt $j ] ; do

  #Search .localrec_progress and assess whether subparticles have previously been extracted
  localrec_progress=$(grep ${ptcldir} .localrec_progress | grep localrec_subparticles_${i})

  #Get distance to subparticle from cmm_marker log file
  if [[ $autolength == 1 ]] ; then
    length=$(cat cmm_markers/marker_${i}_distance.log | awk '{print $11}' | sed -n 1p)
    echo ""
    echo "Distance is set to auto, reading distance from cmm log file..."
    echo "Distance to subparticle, length is ${length} for marker_${i}"
    echo ""
  fi

  if [[ -n $localrec_progress ]] ; then
    echo $localrec_progress
    echo "Skipping localrec subparticle extraction ${ptcldir} ${i}, already processed"
  else
    if [[ -z $maskdir ]] ; then
      #Do subparticle extraction without signal subtraction
      echo "Running subparticle extraction without signal subraction"
      echo ""
      echo "scipion run relion_localized_reconstruction.py --prepare_particles --create_subparticles --align_subparticles --extract_subparticles --sym C1 --cmm cmm_markers/marker_${i}.cmm --angpix ${apix} --particle_size ${box} --length ${length} --subparticle_size ${newbox} --output ${ptcldir}/localrec_${project}_${i} ${star}"
      scipion run relion_localized_reconstruction.py --prepare_particles --create_subparticles --align_subparticles --extract_subparticles --sym C1 --cmm cmm_markers/marker_${i}.cmm --angpix ${apix} --particle_size ${box} --length ${length} --subparticle_size ${newbox} --output ${ptcldir}/localrec_${project}_${i} ${star}

    else
      echo "Running subparticle extraction with signal subraction"
      echo ""
      #Do subparticle extraction with signal subtraction
      echo "scipion run relion_localized_reconstruction.py --prepare_particles --masked_map ${maskdir}/mask${i}_subtraction_soft.mrc  --create_subparticles --align_subparticles --extract_subparticles --sym C1 --cmm cmm_markers/marker_${i}.cmm --angpix ${apix} --particle_size ${box} --length ${length} --subparticle_size ${newbox} --output ${ptcldir}/localrec_${project}_${i} ${star}"
      scipion run relion_localized_reconstruction.py --prepare_particles --masked_map ${maskdir}/mask${i}_subtraction_soft.mrc  --create_subparticles --align_subparticles --extract_subparticles --sym C1 --cmm cmm_markers/marker_${i}.cmm --angpix ${apix} --particle_size ${box} --length ${length} --subparticle_size ${newbox} --output ${ptcldir}/localrec_${project}_${i} ${star}
    fi
    echo "${ptcldir} localrec_subparticles_${i}: completed subparticle extraction: $(timestamp)" >> .localrec_progress
  fi

  i=$(($i+1))

done

## Make a copy of the script so that there is a record
scp -r $0 $ptcldir
echo ""
echo "Copy of this script made in subparticle directory: ${ptcldir}"

## Make a copy of the star file that was used so that there is a record
scp -r ${star} $ptcldir
echo ""
echo "Copy of the star file used for subparticle extraction made in: "
echo "${ptcldir}"

## Make a copy of the cmm_markers so that there is a record
scp -r cmm_markers $ptcldir
echo ""
echo "Copy of the cmm_markers used for subparticle extraction made in: "
echo "${ptcldir}"

## Suggest command for joining star files

echo ""
echo "Done!"
echo "You may want to join all the subparticle star files for further classification and refinement in Relion"
echo ""
echo ""
cd $ptcldir
starlist=$(echo *${project}*star)
echo "relion_star_combine --i \" ${starlist} \" --o localrec_${project}_all.star" > localrec_join_subparticle_star.sh
cd ..
echo "With Relion-2.1 and greater sourced execute the localrec_join_subparticle_star.sh to create a combined subparticle star file..."
echo ""
echo "Definitely done.."
echo ""
