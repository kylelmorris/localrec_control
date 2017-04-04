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
radius = 20      # Radius around selection to extract density
#origin = 'originIndex 150'    # Insert a volume origin command here if desired
origin = ''    # Insert a volume origin command here if desired
residuesel = '@ca'              # restrict residues mask extraction

#####################################################################################
# Open map into #0
#####################################################################################

# Open map back into #0
rc('open #0 '+str(dir)+'/map/'+str(map))
rc('volume #0 '+str(origin))

#####################################################################################
# Create and save masks by sequential PDB model opening
#####################################################################################

os.mkdir(str(dir)+'/masks')
os.mkdir(str(dir)+'/images')
os.mkdir(str(dir)+'/cmm_markers')

# Loop through the PDB models to create the masks for subtraction
for i in range(1,fileno+1):
  # Load PDB
  PDB = filelist[i-1]
  rc('open #1 '+str(dir)+'/PDB/'+str(PDB))
  # Hide dashed pseudo bonds connecting PDBs
  rc('select #1')
  rc('setattr g display false')
  # scolor and split map, expect subtracted map in #2 and hub in #3
  rc('scolor #0 zone #1'+str(residuesel)+' range '+str(radius)+' autoUpdate true; ac sm')
  rc('~select #1')
  rc('~modeldisplay #1')

  # Make cmm markers based on centre of mass
  rc('measure center #0 mark true radius 10 color red model 2')
  rc('measure center #3 mark true radius 10 color blue model 2')
  rc('savemarkers #2 '+str(dir)+'/cmm_markers/marker'+str(i)+'.cmm')

  # save new volumes and image for diagnostic
  rc('focus')
  rc('volume # hide')
  rc('volume #2 show')
  rc('volume #2 save '+str(dir)+'/masks/mask'+str(i)+'_subtraction.mrc')
  rc('copy file '+str(dir)+'/images/mask'+str(i)+'_subtraction.png png')

  rc('set bgTransparency')
  rc('volume # hide')
  rc('volume #3 show')
  rc('volume #3 save '+str(dir)+'/masks/mask'+str(i)+'_subtracted.mrc')
  rc('copy file '+str(dir)+'/images/mask'+str(i)+'_subtract.png png')

  rc('volume # hide')
  rc('modeldisplay #1')
  rc('copy file '+str(dir)+'/images/mask'+str(i)+'_PDB.png png')

  rc('close #1-3')
