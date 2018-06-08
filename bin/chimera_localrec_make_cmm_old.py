#!/usr/bin/env python
#

# This script assumes you are in the working directory of the files to process
#
# Launch script by:
# $ chimera localrec_make_masks.py
#
# Directory structure is as follows:
#
# /
# /map      # Contains map in .mrc format, origin will be set to 0
# /PDB      # Contains fitted PDB's in the map
#

# Python modules for option import

#import argparse

#parser = argparse.ArgumentParser()
#parser.add_argument("r", type=int, help="Density selection radius from C-alpha (A)")
#parser.add_argument("--e", "--extend", help="--e Extend mask by n pixels",
#                    type=int)
#parser.add_argument("--s", "--soften", help="--s Soften mask by n pixels",
#                    type=int)
#args = parser.parse_args()

#import argparse
#parser = argparse.ArgumentParser()
#parser.add_argument("square", type=int,
                    #help="display a square of a given number")
#parser.add_argument("-v", "--verbosity", type=int,
#                    help="increase output verbosity")
#args = parser.parse_args()

#####################################################################################
# Python module import, chimera command and variable setup
#####################################################################################

# Python modules to load
import chimera
import os          # For running OS commands
import subprocess     # For invoking bash scripts inside this python script
import fnmatch

from chimera import runCommand as rc # use 'rc' as shorthand for rc
from chimera import replyobj # for emitting status messages
from chimera.tkgui import saveReplyLog, clearReplyLog

# Current working directory is set
dir = os.getcwd()
print 'Current working diretory set:'
print dir

# Gather name of map found in the /map folder
os.chdir("map")
for file in os.listdir("."):
    if file.endswith(".mrc"):
        map=file
os.chdir("..")

# Gather the number of and names of .pdb files in the /PDB folder
# Makes sure that the directory list is sorted correctly (ntoe use of sorted)
os.chdir("PDB")
filelist = [fn for fn in sorted(os.listdir(".")) if fn.endswith(".pdb")]
# No of PDB's to sub-volume average the fitted density of
fileno = len(fnmatch.filter(os.listdir('.'), '*.pdb'))
os.chdir("..")

#####################################################################################
# savemarkers definition
#####################################################################################

def save_markers(marker_models, path):
    marker_sets = [m.marker_set for m in marker_models if hasattr(m, 'marker_set')]
    if len(marker_sets) == 0:
        from Commands import CommandError
        raise CommandError('No marker sets specified.')
    from os.path import expanduser
    f = open(expanduser(path), 'w')
    from VolumePath.markerset import save_marker_sets
    save_marker_sets(marker_sets, f)
    f.close()

def save_markers_command(cmdname, args):
    from Commands import parse_arguments, models_arg, string_arg
    req_args = (('marker_models', models_arg),
                ('path', string_arg))
    opt_args = ()
    kw_args = ()
    kw = parse_arguments(cmdname, args, req_args, opt_args, kw_args)
    save_markers(**kw)


from Midas.midas_text import addCommand
addCommand('savemarkers', save_markers_command)

#####################################################################################
# REQUIRED VARIABLES - edit these to make point the script to PDB's
#####################################################################################

# Required variables
radius = 25            # Radius around selection to extract density
#origin = 'originIndex 150'     # Insert a volume origin command here if desired
origin = ''                     # Insert a volume origin command here if desired
residuesel = '@ca'              # restrict residues mask extraction

os.mkdir(str(dir)+'/cmm_markers')

#####################################################################################
# Open map into #0
#####################################################################################

# Open map back into #0
rc('open #0 '+str(dir)+'/map/'+str(map))
rc('volume #0 step 1 '+str(origin))

#####################################################################################
# Create cmm markers based on center of mass in PDBs
#####################################################################################

#rc('close #')

# Loop through the PDB models to create the center of mass markers for subparticl location
for i in range(1,fileno+1):
  # Load PDBs
  PDB = filelist[i-1]
  rc('open #'+str(i)+' '+str(dir)+'/PDB/'+str(PDB))

for i in range(1,fileno+1):
  #measure cmm markers
  rc('measure center #0 mark true radius 10 color red model 500')
  rc('measure center #'+str(i)+' mark true radius 10 color blue model 500')
  rc('savemarkers #500 "'+str(dir)+'/cmm_markers/marker'+str(i)+'.cmm"')
  rc('close #500')

rc('close #')

#close chimera
rc('stop')
