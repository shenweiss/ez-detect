#!/usr/bin/env python3.5
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
getPaths() local function inside config.py file. 
xml_output gets saved in the default directory or the one given as argument.

 
 This work is protected by US patent applications US20150099962A1,
 UC-2016-158-2-PCT, US provisional #62429461

 Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
 Philadelphia, PA USA. 2017
'''
import matlab.engine
import config
from process_batch import *
import argparse
import os
#import json #temporal until process_batch gets fully translated to python, 

def hfo_annotate(paths, start_time, stop_time, cycle_time):
    
    
    #Generate dsp outputs
    '''
    batch_input = [paths, start_time, stop_time, cycle_time]
    with open('batch_input.json', 'w') as outfile:
        json.dump(batch_input, outfile)
    print('Wrote json input for process_batch.m')
    
    m_commands = '\"tryAddPaths(\'{}\');process_batch_json();quit\"'.format(paths['project_root'])  
    m_flags =' -nodesktop -nosplash -r '
    os.system(paths['matlab'] + m_flags + m_commands)
    '''
    process_batch(paths, start_time, stop_time, cycle_time)

    print('Starting to process dsp monopolar/bipolar outputs...')
    
    engine = config.matlab_session
    #Process dsp outputs
    engine.process_dsp_outputs(paths['dsp_monopolar_out'],config.monopolarLabels(),paths, nargout=0);
    engine.process_dsp_outputs(paths['dsp_bipolar_out'],config.bipolarLabels(),paths, nargout=0);

    engine.quit()
    
if __name__ == "__main__":
    
    parser = argparse.ArgumentParser()
    
    #Agregar types y argument validation
    parser.add_argument("-in", "--trc_path", 
                        help="The directory path to the file with the data to analize.", 
                        required=True)
    
    parser.add_argument("-out", "--xml_output_path", 
                        help="Path where the .xml output will be created.",
                        required=False, default= config.paths['xml_output_path'])
    
    parser.add_argument("-pdir", "--project_dir_path", 
                        help="Path to the root directory of the project. This is"+
                        " used to set relative paths of saving directories.",
                        required=False, default= config.paths['project_root'])

    #Improve later to support taking minutes in the 3 following args
    parser.add_argument("-str_t", "--start_time", 
                        help="An integer in seconds indicating from when, "+ 
                        "relative to the file duration, do you want to analize the eeg.",
                        required=False, default= config.START_TIME_DEFAULT, type=int)
    
    parser.add_argument("-stp_t", "--stop_time", 
                        help="An integer number in seconds indicating up to when, relative"+
                        "to the file duration, do you want to analize the eeg.",
                        required=False, default= config.STOP_TIME_DEFAULT, type=int) 

    parser.add_argument("-c", "--cycle_time", 
                        help="A number in seconds indicating the size of the blocks"+ 
                        "for the data to be cut. This improves time performance.",
                        required=False, default= config.CYCLE_TIME_DEFAULT, type=int)

    parser.add_argument("-saf", "--swap_array_file_path", #TODO add this argument to config.paths
                        help="This optional file should contain a swap_array"+
                        " variable, which can be used to correct the channel"+
                        " assignments in case that channels were incorrectly"+
                        " assigned in the original EDF file as can be the case"+
                        " for intraop", required=False, default= config.paths['swap_array_file']) 

    args = parser.parse_args()
    
    paths = config.updatePaths(config.paths, args.trc_path, args.project_dir_path, 
                                          args.xml_output_path, args.swap_array_file_path)

    hfo_annotate(paths, args.start_time, args.stop_time, args.cycle_time)

