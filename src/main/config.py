#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#import pdb ;pdb.set_trace() 

import matlab.engine
import os
import platform

START_TIME_DEFAULT = 1
#Once read the input trc, if Stop_time is == STOP_TIME_DEFAULT, it will be 
#updated to take all the eeg.
STOP_TIME_DEFAULT = 0  
CYCLE_TIME_DEFAULT = 300 #300 seconds = 5 minutes

def getPaths():
    paths = {}
    paths['matlab']= '/home/tomas-pastore/matlab/bin/matlab'
    paths['project_root']= '/home/tomas-pastore/ez-detect/'
    #paths['matlab']= "C:/\"Program Files\"/MATLAB/R2017a/bin/matlab.exe"
    #paths['project_root']= "C:/Users/Tomas Pastore/Documents/ez-detect/"

    paths['hfo_engine']= paths['project_root']+'hfo_engine_1/'
    
    paths['temp_pythonToMatlab_dsp'] = paths['hfo_engine']+'temp_pythonToMatlab_dsp/'
    paths['temp_pythonToMatlab_dsp_MATLAB'] = paths['hfo_engine']+'temp_pythonToMatlab_dsp_MATLAB/'

    paths['xml_output_path']= paths['hfo_engine']+'xml_output'
    paths['swap_array_file'] = "NOT_GIVEN"
    paths['dsp_monopolar_out']= paths['hfo_engine']+'dsp_output/monopolar/'
    paths['dsp_bipolar_out']= paths['hfo_engine']+'dsp_output/bipolar/'

    paths['ez_pac_out']= paths['hfo_engine']+'ez_pac_output/'
    paths['ez_top_in']= paths['hfo_engine']+'ez_top/input/'
    paths['ez_top_out']= paths['hfo_engine']+'ez_top/output/'

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

#Starts matlab session in current dir
os.chdir(paths['misc_code']) #to find tryAddPaths
matlab_session = matlab.engine.start_matlab() 
matlab_session.tryAddPaths(paths['project_root'], nargout=0) #for program method lookups

runMatlabProcessBatch = False