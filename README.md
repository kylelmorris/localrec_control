# localrec_control

Python and shell scripts for initial stages and control of relion_localized_reconstruction.py for sub-particle extraction in single particle cryo electron microscopy.

These scripts provide a framework for the initial stages of running [relion_localized_reconstruction.py](https://github.com/OPIC-Oxford/localrec).

#### localrec_create_masks.sh
Uses UCSF Chimera to create masks for partial signal subtraction and the vectors required for sub-particle location and extraction.

#### localrec_run.sh
Controls relion_localized_reconstruction.py to create partial signal subtracted images of your original particles and then extract the sub-particles of choice, as defined by localrec_create_masks.sh. This script will iterate over n number of subunits as present in your system and as defined by localrec_create_masks.sh.

## Prerequisites

A single particle data set already refined in Relion in C1.

[relion_localized_reconstruction.py](https://github.com/OPIC-Oxford/localrec) should first be installed, with its dependancies including:

```
Relion-1.4
Scipion
Associated python libraries
```

localrec_create_masks.sh: Adjust lines 4 and 5 to suit your system.

localrec_run.sh: Adjust line 17 to suit your system.

### Setup and execution

* Currently it is best to copy the scripts to your Relion working directory which might look like this:

```
./Class2D/
./Class3D/
./CtfFind/
./default_pipeline.star
./Extract/
./Import/
./ManualPick/
./micrographs_all_gctf.star
./MTF-K2-300kV.star
./PostProcess/
./Refine3D/
./Select/
./Trash/
```

* Make a new directory structure inside this Relion project as follows:

```
./localrec/map
./localrec/map/run_class001.mrc	# Symbolic link to the C1 reconstruction from the C1 run_data.star
./localrec/run_data.star	# Symbolic link to the C1 refinement star file with reference to extracted particles
				# Note that this file must be Relion-1.4 formatted, see ./bin/relion_star_2_to_1.4.py
./localrec/PDB
./localrec/Extract		# Symbolic link to the Extract directory containing your particles
```

* Fit PDB's into each sub-structure of the C1 reconstruction

You may find it helpful to use a symmetrised map to guide you. Check the map origin is 0 in UCSF Chimera and save each fitted PDB into the ./PDB directory.

Currently this is how the map is segmented but there's no reason why you couldn't use segger or some other segmentation method.

* Run localrec_create_masks.sh from the terminal

New directories should automatically be created as below:

```
./localrec/cmm_markers	# cmm markers describing the vector to the location of your sub-structure in the C1 volume
./localrec/images	# Sanity check images showing how the volumes, markers and PDB placement looks
./localrec/masks	# Masks that can be used for partial signal subtraction within relion_localized_reconstruction.py
```

* Run localrec_run.sh

Adjust lines 4 to 12 to suit your particular project

Using relion_localized_reocnstruction.py this script will extract the sub-particles for each sub-structure and once finished then make a reconstruction for each sub-structure. You should inspect these for correctness and subsequently they can be used as a reference for refinements.

* Combine star files

If you have extracted multiple sub-structures then you may want to combine the star files associated with each sub-particle image stack. The following provided script will join all star files in the current working directory preserving their header information.

Suggestion: create a new directory and symbolic link all localrec sub-particle star files into it (either subtracted.star or .star), then run the join script.

```
relion_star_join_batch.sh
```

* Continue refinement in Relion with localrec sub-particles

In your Relion project directory symbolic link to the sub-particle directory you created in ./localrec and import the appropriate star file for continuing classification and refinement of localrec sub-particles.

## Versioning

v1 - initial commit

## Authors

* #### Kyle Morris, UC Berkeley

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Juha Huiskonen (OPIC-Oxford) and Daniel Asarnow (UCSF) for helpful discussion
