#!/usr/bin/env python3
# -*- coding: utf-8 -*-
 
'''
Note: For first use please see and set the paths in getPaths()

Usage && INPUT arguments: type 'python3 hfo_annotate.py --help' in the shell
Example with defaults: python3 hfo_annotate.py --edf_dataset_path=test.edf

Dependencies: In order to have support for matlab.engine module:
 1) 'cd matlabroot/extern/engines/python'
 2) 'python3 setup.py install' (may require sudo) 

Output: DSP monopolar/bipolar outputs as matfiles get saved in the corresponding 
directory indicated by paths.dsp_mono/bipolar_output, which gets setted in 
getPaths() local function. xml_output gets saved in the default directory or the
one given as argument.

 
 This work is protected by US patent applications US20150099962A1,
 UC-2016-158-2-PCT, US provisional #62429461

 Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
 Philadelphia, PA USA. 2017
'''
import argparse
import os
from config import matlab_session as matlab
from process_batch import process_batch

def hfo_annotate(paths, start_time, stop_time, cycle_time, swapping_data):
    
    os.chdir(paths['misc_code'])
    matlab.tryAddPaths(paths['project_root'], nargout=0) #for program method lookups
    
    os.chdir(paths['hfo_matlab']) 
    os.system('./clean.sh') #cleans previous execution outputs
    
    #This is currently not working because of the parfor inside ez_detect_batch.m 
    #I will translate ez_detect_batch_to python
    #Generate dsp outputs 
    process_batch(paths,start_time,stop_time,cycle_time, swapping_data, nargout=0)

    print('Starting to process dsp monopolar/bipolar outputs...')
    
    #Process dsp outputs
    matlab.process_dsp_outputs(paths['dsp_monopolar_out'],monopolarLabels(),paths, nargout=0);
    matlab.process_dsp_outputs(paths['dsp_bipolar_out'],bipolarLabels(),paths, nargout=0);

    matlab.quit()

def getPaths(edf_dataset_path, project_dir_path, xml_output_path):
    paths = {}
    paths['edf_dataset']= edf_dataset_path
    paths['xml_output_path']= xml_output_path
    paths['project_root']= project_dir_path
        
    paths['hfo_engine']= paths['project_root']+'hfo_engine_1/'
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

    paths['cudaica_dir']= paths['project_root']+'/src/cudaica/'
    paths['binica_sc']= paths['cudaica_dir']+'binica.sc'
    paths['cudaica_bin']= paths['cudaica_dir']+'cudaica'
    paths['misc_code']= paths['project_root']+'tools/misc_code'

    return paths

def monopolarLabels():
    return {
        'dsp_data':'DSP_data_m',
        'metadata': 'metad:ta',
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

    
if __name__ == "__main__":
    
    parser = argparse.ArgumentParser()
    
    #Agregar types y argument validation
    parser.add_argument("-in", "--edf_dataset_path", 
                        help="The directory path to the file with the data to analize.", 
                        required=True)
    
    parser.add_argument("-out", "--xml_output_path", 
                        help="Path where the .xml output will be created.",
                        required=False, default= '/home/tomas-pastore/ez-detect/hfo_engine_1/xml_output')
    
    parser.add_argument("-pdir", "--project_dir_path", 
                        help="Path to the root directory of the project. This is"+
                        " used to set relative paths of saving directories.",
                        required=False, default= '/home/tomas-pastore/ez-detect/')

    #Improve later to support taking minutes in the 3 following args
    parser.add_argument("-str_t", "--start_time", 
                        help="An integer in seconds indicating from when, "+ 
                        "relative to the file duration, do you want to analize the eeg.",
                        required=False, default=1, type=int)
    
    parser.add_argument("-stp_t", "--stop_time", 
                        help="An integer number in seconds indicating up to when, relative"+
                        "to the file duration, do you want to analize the eeg.",
                        required=False, default=0, type=int) #fix later to take file length

    parser.add_argument("-c", "--cycle_time", 
                        help="A number in seconds indicating the size of the blocks"+ 
                        "for the data to be cut. This improves time performance.",
                        required=False, default=300, type=int)

    parser.add_argument("-saf", "--swap_array_file_path", 
                        help="This optional file should contain a swap_array"+
                        " variable, which can be used to correct the channel"+
                        " assignments in case that channels were incorrectly"+
                        " assigned in the original EDF file as can be the case"+
                        " for intraop", required=False, default="default") 

    args = parser.parse_args()
    
    chan_swap = False if args.swap_array_file_path == "default" else True
        
    swapping_data = {'chan_swap':chan_swap,'swap_array_file':args.swap_array_file_path}
  
    paths = getPaths(args.edf_dataset_path, args.project_dir_path, args.xml_output_path)
    hfo_annotate(paths, args.start_time, args.stop_time, args.cycle_time, swapping_data)

