#!/usr/bin/env python
#

from pyrelion import *
md = MetaData("run_data.star")
md.removeLabels('rlnAutopickFigureOfMerit')
md.removeLabels('rlnCtfBfactor')
md.removeLabels('rlnCtfScalefactor')
md.removeLabels('rlnPhaseShift')
md.removeLabels('rlnCtfMaxResolution')
md.removeLabels('rlnCtfFigureOfMerit')
md.write("run_data_rln1.4.star")
