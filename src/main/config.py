#!/usr/bin/env python3.5
# -*- coding: utf-8 -*-
import matlab.engine
import os

#Global variables

START_TIME_DEFAULT = 1
STOP_TIME_DEFAULT = 0 #fix later to take file length
CYCLE_TIME_DEFAULT = 300 #5 minutes

def getPaths():
    paths = {}
    paths['matlab']= '/home/tomas-pastore/matlab/bin/matlab'
    paths['project_root']= '/home/tomas-pastore/ez-detect/'
    paths['hfo_engine']= paths['project_root']+'hfo_engine_1/'
    
    paths['temp_pythonToMatlab_dsp'] = paths['hfo_engine']+'temp_pythonToMatlab_dsp/'

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
        'ez_tall': 'ez_tall_m',
        'ez_tall_fr': 'ez_tall_fr_m',
        'ez_tall_hfo': 'ez_tall_hfo_m',
        'error_flag': 'error_flag'
    }

def bipolarLabels():
    return {
        'dsp_data': 'DSP_data_bp',
        'metadata': 'metadata',
        'num_trc_blocks': 'num_trc_blocks',
        'ez_tall': 'ez_tall_bp',
        'ez_tall_fr': 'ez_tall_fr_bp',
        'ez_tall_hfo': 'ez_tall_hfo_bp'
    }

os.chdir(paths['hfo_engine']) 
os.system('./clean.sh') #cleans previous execution outputs

os.chdir(paths['misc_code'])
#starts matlab session in current dir
matlab_session = matlab.engine.start_matlab() 
matlab_session.tryAddPaths(paths['project_root'], nargout=0) #for program method lookups