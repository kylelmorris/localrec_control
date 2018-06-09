# Localised reconstruction control framework

## Description

Python and shell scripts for initial stages and control of relion_localized_reconstruction.py for sub-particle extraction in single particle cryo electron microscopy.

These scripts provide a framework for the initial stages of running [relion_localized_reconstruction.py](https://github.com/OPIC-Oxford/localrec).

## Motivation

These scripts are designed to control Localised Reconstruction (LocalRec, as described in Ilca 2015). They were developed with a view to extract subparticles from C1 reconstructions of truly pseudo-symmetric complexes. Certain pseudo-symmetric complexes approximately follow the symmetry groups used in cryo-EM refinement. In these cases the repeating unit of the complex that is to be refined lies on a symmetry axis, and so can be refined using standard symmetry imposed refinements or using LocalRec and the symmetry group that describes the subparticle locations fully. Other methods exist that also deal with these cases (Relion symmetry expansion). However, certain truly pseudo-symmetric complexes may have possess some of the repeating subparticles lying off-symmetry-axis, and thus do not obey any symmetry group. In these cases it was found that a C1 refinement of the truly pseudo-symmetric complex could be obtained and LocalRec used to localise and extract repeating subparticles. These are then combined into a single refinement to determine the structure of the pseudo-symmetric subparticle.

## Prerequisites

A single particle data set already refined in Relion in C1.

[relion_localized_reconstruction.py](https://github.com/OPIC-Oxford/localrec) should first be installed, with its dependancies including:

```
Relion-1.4
Scipion
Associated python libraries
```

## Brief protocol

1) Determine your structure in C1 using Relion
2) Fit a PDB into every repeating subparticle that you wish to extract
3) Get organised, set up the following directory structure:

```
./map/run_class001.mrc
./PDB/substructure1.pdb
./PDB/substructure2.pdb
./PDB/substructure3.pdb
```

4) Run localrec_create_cmm.sh, this will create a new directory (cmm_markers) using UCSF Chimera.
	These vectors describe the location of each subparticle in the C1 map
5) Get more organised, add the following directories:
```
./star/run_data.star	# This is the star file from the C1 refinement (relion1.4 format required)
./Extract		# Symbolic link to the Extract directory containing the particles that were used in the C1 refinement
```

6) Edit localrec_create_subpartices.sh header to suit your refinement.
7) Source Relion-1.4
8) Run localrec_create_subparticles.sh	# This will use LocalRec to localise the subparticle of interest in each image and extract it
9) Run localrec_create_substructures.sh	# This will use the LocalRec particles from (8) to reconstruct the subparticle volume
10) Combine the subparticle star files and perform image processing in the latest version of Relion

## Notes for signal subtraction

Coming soon!

## Versioning

## Authors

* #### Kyle Morris, UC Berkeley

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Juha Huiskonen (OPIC-Oxford) and Daniel Asarnow (UCSF) for helpful discussion
