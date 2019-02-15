#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#import pdb ;pdb.set_trace() 

import matlab.engine
import os
import platform
from datetime import timedelta


START_TIME_DEFAULT = 1
STOP_TIME_DEFAULT = 0  #If not given by user, this value is corrected once read the eeg.
CYCLE_TIME_DEFAULT = 300 #300 seconds = 5 minutes

desired_frec_hz = 2000

#Montage constants
REFERENTIAL = 1
BIPOLAR = 0
NO_BP_REF = 0
EXCLUDE_CH = 1
DONT_EXCLUDE_CH = 0

MP_ANNOTATIONS_FLAG = 0 
BP_ANNOTATIONS_FLAG = 1

#Working paths

paths = {}
#paths['matlab']= '/home/tomas-pastore/matlab/bin/matlab'
#paths['matlab']= "C:/\"Program Files\"/MATLAB/R2017a/bin/matlab.exe"
paths['project_root']= '/home/tomas-pastore/ez-detect/'
#paths['project_root']= "C:/Users/Tomas Pastore/Documents/ez-detect/"

paths['hfo_engine']= paths['project_root']+'hfo_engine_1/'

paths['temp_pythonToMatlab_dsp'] = paths['hfo_engine']+'temp_pythonToMatlab_dsp/'
paths['temp_pythonToMatlab_dsp_MATLAB'] = paths['hfo_engine']+'temp_pythonToMatlab_dsp_MATLAB/'

paths['xml_output_path']= paths['hfo_engine']+'xml_output/xml_out.evt'
paths['swap_array_file'] = "NOT_GIVEN"
paths['dsp_monopolar_out']= paths['hfo_engine']+'dsp_output/monopolar/'
paths['dsp_bipolar_out']= paths['hfo_engine']+'dsp_output/bipolar/'

paths['ez_pac_out']= paths['hfo_engine']+'ez_pac_output/'
paths['ez_top_in']= paths['hfo_engine']+'ez_top/input/'
paths['ez_top_out']= paths['hfo_engine']+'ez_top/output/'

#paths['montages']= paths['hfo_engine']+'montages/'
paths['research']= paths['hfo_engine']+'research_matfiles/'
paths['executable']= paths['hfo_engine']+'executable/'

paths['trc_out']= paths['hfo_engine']+'trc/output/'
paths['trc_tmp_monopolar']= paths['hfo_engine']+'trc/temp/monopolar/'
paths['trc_tmp_bipolar']= paths['hfo_engine']+'trc/temp/bipolar/'

paths['cudaica_dir']= paths['project_root']+'src/cudaica/'
paths['binica_sc']= paths['cudaica_dir']+'binica.sc'
paths['cudaica_bin']= paths['cudaica_dir']+'cudaica'
paths['misc_code']= paths['project_root']+'tools/misc_code/'

def resolvePaths(trc_fname, xml_output_path, project_dir_path, swap_array_path):
    paths['trc_fname']= trc_fname
    paths['project_root']= project_dir_path
    paths['xml_output_path']= xml_output_path
    paths['swap_array_file'] = swap_array_path

    return paths


#Cleans previous execution outputs
cwd = os.getcwd()
os.chdir(paths['hfo_engine']) 
running_os = platform.system()
if running_os == 'Windows':
    os.system('clean') 
elif running_os == 'Linux':
    os.system('./clean.sh') 

#Starts matlab session in current dir
os.chdir(paths['misc_code']) #to find tryAddPaths
matlab_session = matlab.engine.start_matlab() 
matlab_session.tryAddPaths(paths['project_root'], nargout=0) #for program method lookups
os.chdir(cwd)

#### XML CONFIGURATION

#MICROMED | BRAINQUICK DEFINES
HFO_CATEGORY_GUID = "27e2727f-e49d-4113-aa8c-4944ef8f2588"
HFO_SUBCATEGORY_GUID = "c142e214-826e-4dfe-965a-110246492c9e"
DEF_HFO_SPIKE_GUID = "bf513752-2cb7-43bc-93f5-370def800b93"
DEF_HFO_RIPPLE_GUID = "167b6fad-f95a-4880-a9c6-968f468a1297"
DEF_HFO_FASTRIPPLE_GUID = "e0a58c9c-b3c0-4a7d-a3c3-d3ed6a57dc3a"

#Gaps of time before and after events
spike_on_offset = - timedelta(seconds=0.02)
spike_off_offset = + timedelta(seconds=0.01)
ripple_on_offset = - timedelta(milliseconds=5)
ripple_off_offset = + timedelta(milliseconds=5)
fripple_on_offset = - timedelta(milliseconds=2.5)
fripple_off_offset = + timedelta(milliseconds=2.5)
        
    
