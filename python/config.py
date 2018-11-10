#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#import pdb ;pdb.set_trace() 

import os
import platform
from datetime import timedelta

START_TIME_DEFAULT = 1
#Once read the input trc, if Stop_time is == STOP_TIME_DEFAULT, it will be 
#updated to take all the eeg.
STOP_TIME_DEFAULT = 0  
CYCLE_TIME_DEFAULT = 300 #300 seconds = 5 minutes

def getPaths():
    paths = {}
    paths['matlab']= '/home/tpastore/matlab/bin/matlab'
    paths['project_root']= '/home/tpastore/ez-detect/'
    #paths['matlab']= "C:/\"Program Files\"/MATLAB/R2017a/bin/matlab.exe"
    #paths['project_root']= "C:/Users/Tomas Pastore/Documents/ez-detect/"

    paths['hfo_engine']= '/home/tpastore/hfo_engine_1/'
    
    paths['temp_pythonToMatlab_dsp'] = paths['hfo_engine']+'temp_pythonToMatlab_dsp/'
    paths['temp_pythonToMatlab_dsp_MATLAB'] = paths['hfo_engine']+'temp_pythonToMatlab_dsp_MATLAB/'

    paths['xml_output_path']= paths['hfo_engine']+'xml_output/xml_out.evt'
    paths['swap_array_file'] = "NOT_GIVEN"
    paths['dsp_monopolar_out']= paths['hfo_engine']+'dsp_output/monopolar/'
    paths['dsp_bipolar_out']= paths['hfo_engine']+'dsp_output/bipolar/'

    paths['ez_pac_out']= paths['hfo_engine']+'ez_pac_output/'
    paths['ez_top_in']= paths['hfo_engine']+'ez_top/input/'
    paths['ez_top_out']= paths['hfo_engine']+'ez_top_out/'

    paths['montages']= paths['hfo_engine']+'montages/'
    paths['research']= paths['hfo_engine']+'research_matfiles/'
    paths['executable']= paths['hfo_engine']+'executable/'

    paths['trc_out']= paths['hfo_engine']+'trc/output/'
    paths['trc_tmp_monopolar']= paths['hfo_engine']+'trc/temp/monopolar/'
    paths['trc_tmp_bipolar']= paths['hfo_engine']+'trc/temp/bipolar/'

    paths['cudaica_dir']= paths['project_root']+'src/cudaica/'
    paths['binica_sc']= paths['cudaica_dir']+'binica.sc'
    paths['cudaica_bin']= paths['cudaica_dir']+'cudaica'
    paths['misc_code']= paths['project_root']+'tools/misc_code/'

    return paths

def updatePaths(paths, trc_fname, project_dir_path, xml_output_path, swap_array_path):
    paths['trc_fname']= trc_fname
    paths['project_root']= project_dir_path
    paths['xml_output_path']= xml_output_path
    paths['swap_array_file'] = swap_array_path

    return paths

paths = getPaths()


def monopolarLabels():
    return {
        'dsp_data':'DSP_data_m',
        'metadata': 'metadata',
        'num_trc_blocks': 'num_trc_blocks',
        'ez_mp': 'ez_mp',
        'ez_fr_mp': 'ez_fr_mp',
        'ez_hfo_mp': 'ez_hfo_mp',
        'error_flag': 'error_flag'
    }

def bipolarLabels():
    return {
        'dsp_data': 'DSP_data_bp',
        'metadata': 'metadata',
        'num_trc_blocks': 'num_trc_blocks',
        'ez_bp': 'ez_bp',
        'ez_fr_bp': 'ez_fr_bp',
        'ez_hfo_bp': 'ez_hfo_bp'
    }


#Cleans previous execution outputs
#os.chdir(paths['hfo_engine']) 
#running_os = platform.system()
#if running_os == 'Windows':
#    os.system('clean') 
#elif running_os == 'Linux':
#    os.system('./clean.sh') 

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
        
    
