#!/usr/bin/env python3
# -*- coding: utf-8 -*-
 
'''
Usage && INPUT arguments: type 'python3 hfo_annotate.py --help' in the shell
Example with defaults: python3 hfo_annotate.py --trc_path=449.TRC

Dependencies: 

1)In order to have support for matlab.engine module:
 1.1) Python 3.5
 1.2) In shell... 'cd matlabroot/extern/engines/python'
 1.3) Install the extern module: 'python3 setup.py install' (may require sudo) 

2) trcio python module
3) mne dev python module.

Output: xml_output gets saved in the default directory or the one given as argument.

'''
import time
start = time. time()

import config
from config import matlab_session as MATLAB

import sys
from os.path import basename, splitext, expanduser, abspath

from trcio import read_raw_trc
from mne.utils import verbose, logger
sys.path.insert(0, config.paths['project_root']+'/src/evtio')
from evtio import write_evt
sys.path.insert(0, config.paths['project_root']+'/tools/profiling')
from profiling import profile_time, profile_memory
sys.path.insert(0, config.paths['project_root']+'/src/')
from montage import build_montage_from_trc
sys.path.insert(0, config.paths['project_root']+'/src/preprocessing')
from preprocessing import ez_lfbad
import scipy.io
import hdf5storage

import numpy as np
import threading
import multiprocessing
#import time
from datetime import datetime

from memory_profiler import memory_usage
'''
Input:
    - paths: a Struct containing strings for every path is used in the project. 
      It is set in hfo_annotate and it includes paths.trc_fname which is the 
      file to work with, saving directories, etc.
    
    - start_time: a number in seconds indicating from when, relative to the file 
      duration, do you want to analize the eeg.
    
    - stop_time: a number in seconds indicating up to when, relative to the file 
      duration, do you want to analize the eeg.
      
      For example if you want to process the last 5 minutes of an eeg of 20 
      minutes you would use as input start_time = 15*60 = 900 and 
      stop_time = 20*60 = 1200.
    
    - cycle_time: a number in seconds indicating the size of the blocks to cut 
      the data in blocks. This improves time performance since it can be 
      parallelized. Example: 300 (5 minutes)

    - sug_montage: a string with the name of the suggested montage.

    - bp_montage: a string with the name of the montage with bipolar definitions
      in case ez-detect moves channels from referential to bipolar.
 
Output: xml_output gets saved in the default directory or the one given as argument.
'''
#@profile_memory
#@profile_time
#TODO modify plugin to take start_time from 0 instead of 1
#TODO stop add 1 to stop_time
def hfo_annotate(paths, start_time, stop_time, cycle_time, sug_montage, bp_montage):
    logger.info('Running Ez Detect')

    raw_trc = read_raw_trc(paths['trc_fname'], include=None)
    stop_time = stop_time if stop_time != config.STOP_TIME_DEFAULT else None
    raw_trc.crop(start_time, stop_time).load_data()  

    logger.info("Converting data from volts to microvolts...")
    raw_trc._data *= 1e06
    #Debug info
    logger.info("TRC file: "+ paths['trc_fname'])
    logger.info("XML will be written to "+ paths['xml_output_path'])
    logger.info("Number of channels {}".format(raw_trc.info['nchan']) ) 
    logger.info("First data in microvolts: {}".format(str(raw_trc._data[0][0])))
    logger.info('Sampling rate: {}'.format(str(int(raw_trc.info['sfreq']))+'Hz'))

    #this was being done after creating blocks, ask if doesnt loose precision for event detection
    #mne.filter.resample(array) is too expensive in comparison
    logger.info('Resampling data to: {} Hz'.format(str(config.DESIRED_FREC_HZ)) )
    raw_trc.resample(config.DESIRED_FREC_HZ, npad = 'auto') 
 
    n_samples = len(raw_trc._data[0])
    sampling_rate = int(raw_trc.info['sfreq'])
    montages = raw_trc._raw_extras[0]['montages']
    metadata = { #is it ok to consider ch_names and montage part of metadata? if not, extract as parameters.
        'file_id' : splitext(basename(paths['trc_fname']))[0],
        'montage' : build_montage_from_trc(montages, raw_trc.info['ch_names'],
                                           sug_montage, bp_montage), #temporary
        'old_montage': _buildMontageFromTRC(montages, raw_trc.info['ch_names'],
                                           sug_montage, bp_montage),
        'n_blocks' : _calculateBlockAmount(n_samples, sampling_rate, cycle_time),
        'block_size' : sampling_rate * cycle_time,
        'srate' : sampling_rate
    }

    _processParallelBlocks_threads(raw_trc, metadata, paths)

    rec_start_struct = time.localtime(raw_trc.info['meas_date'][0]) #gets a struct from a timestamp
    rec_start_time = datetime(*rec_start_struct[:6]) #translates struct to datetime
    write_evt(paths['xml_output_path'], paths['trc_fname'], 
              rec_start_time, raw_trc.info['ch_names'])


############  Private Funtions  #########

#Unused for now
def _updateChanlist(ch_names, swap_array_file):
    ch_names = np.array(ch_names ,dtype=object) #for matlab engine
    if swap_array_file != 'NOT_GIVEN':
        swap_array = MATLAB.load(swap_array_file)
        ch_names = [ch_names[i-1] for i in swap_array] 
    return ch_names

def _calculateBlockAmount(n_samples, sampling_rate, cycle_time):
    block_size = sampling_rate * cycle_time
    full_blocks = int(n_samples / block_size)
    images_remaining = n_samples % block_size
    seconds_remaining = images_remaining / sampling_rate
    n_blocks = full_blocks+1 if seconds_remaining >= config.BLOCK_MIN_DUR else full_blocks #Ask about this line later.
    logger.info("Amount of blocks {}".format(str(n_blocks)))
    return n_blocks

#Unused for now
def _saveResearchData(contest_path, metadata, eeg_data, ch_names):
    MATLAB.workspace['ch_names'] = ch_names
    for i in range(len(metadata)):
        MATLAB.workspace['eeg_data_i'] = eeg_data[i]
        MATLAB.workspace['metadata_i'] = metadata[i]
        trc_fname = metadata.file_id
        full_path = contest_path+trc_fname+'_'+str(i)+'.mat' 
        MATLAB.save(full_path, 'metadata_i', 'eeg_data_i', 'ch_names')
        #ask if it is worthy to save the blocks or not

#temporary
def _buildMontageFromTRC(montages, ch_names, sug_montage_name, bp_montage_name):

    sug_lines = montages[sug_montage_name]['lines']
    bp_lines = montages[bp_montage_name]['lines']
    sug_defs = [def_pair for def_pair in montages[sug_montage_name]['inputs'][:sug_lines] ]
    bp_defs = [def_pair for def_pair in montages[bp_montage_name]['inputs'][:bp_lines]]
    def_ch_names_sug = [pair[1] for pair in sug_defs ] 
    def_ch_names_bp = [pair[1] for pair in bp_defs ] 
    
    try:
        assert(set(ch_names) == set(def_ch_names_sug))
    except AssertionError:
        logger.info("The 'Suggested montage' is badly formed, you must provide a definition" +
                    " for each channel name that appears in the 'Ref.'' montage.")
        assert(False)

    montage = []
    for ch_name in ch_names: #First col of montage.mat
        sug_idx = def_ch_names_sug.index(ch_name)
        suggestion = config.REFERENTIAL if sug_defs[sug_idx][0] == 'AVG' else config.BIPOLAR #Second col of montage.mat  

        if suggestion == config.BIPOLAR: #Third col of montage .mat
            if sug_defs[sug_idx][0] == ch_name: #For now we mean exclusion in this way
                bp_ref = config.NO_BP_REF
                exclude = config.EXCLUDE_CH
            else: 
                #Note that we know by the previous conditions that the index exists.
                #That string is defined inside BQ and its value is 'AVG' or another
                #ch_name that we have asserted that is in ch_names.
                bp_ref = ch_names.index(sug_defs[sug_idx][0]) + 1 
                exclude = config.DONT_EXCLUDE_CH

        else: #suggestion == config.REFERENTIAL
            exclude = 0
            try: 
                bp_idx = def_ch_names_bp.index(ch_name)
                bp_ref = ch_names.index(bp_defs[bp_idx][0]) + 1
            except ValueError: #user didn't defined a bp pair for this channel
                bp_ref = config.NO_BP_REF

        chan_montage_info = tuple([ch_name, suggestion, bp_ref, exclude])
        montage.append(chan_montage_info)

    return np.array(montage, dtype=object)

def _processParallelBlocks_threads(raw_trc, metadata, paths):
     
    threads = []
    n_samples = len(raw_trc._data[0])
    ch_names = np.array(raw_trc.info['ch_names'], dtype=object), #we need the np array for matlab engine for now

    def _get_block_data(i):
        logger.info('Creating thread {}'.format(i+1) )
        block_start = i * metadata['block_size']    
        block_stop = min(block_start + metadata['block_size'], n_samples)
        return raw_trc.get_data( start=block_start, stop=block_stop) 
        
    for i in range(metadata['n_blocks']-1): #This starts a thread for all but the last block
        metadata['file_block'] = str(i+1)
        thread = threading.Thread(target= _processParallelBlock, 
                                  name='DSP_block_{}'.format(i+1),
                                  args=(_get_block_data(i), ch_names, metadata, paths))
        threads.append(thread)

    #For the last block we will use current thread.
    block_data = _get_block_data(metadata['n_blocks']-1)
    metadata['file_block'] = str(metadata['n_blocks'])
    
    for t in threads:
        t.start() 

    _processParallelBlock(block_data, ch_names, metadata, paths) #process last block 

    for t in threads:
        t.join()

'''
def _processParallelBlocks_processes(blocks, eeg_data, ch_names, metadata, montage, paths):
    #Ask pool vs independent processes
    def multi_run_wrapper(args):
      return _processParallelBlock(*args)

    pool = Pool(blocks)
    arg_list = [(eeg_data[i], ch_names, metadata[i], montage, paths) for i in range(blocks)]
    pool.map(multi_run_wrapper, arg_list)
    pool.close()
    pool.join()
'''
def _processParallelBlock(eeg_data, ch_names, metadata, paths):    
    data, metadata = ez_lfbad(eeg_data, ch_names, metadata)
    data['bp_channels'], metadata, hfo_ai, fr_ai = _monopolarAnnotations(data, metadata, paths)
    _bipolarAnnotations(data['bp_channels'], metadata, hfo_ai, fr_ai, paths)

def _monopolarAnnotations(data, metadata, paths):
    
    if data['mp_channels']: #not empty

        logger.info('Monopolar block. Converting data from python to matlab (takes long).')
        dsp_monopolar_out = MATLAB.ez_detect_dsp_monopolar(data['mp_channels'], data['bp_channels'], metadata, paths)
        logger.info('Finished dsp monopolar block')

        #TODO once ez top gets translated we can avoid using the disk for saving.
        logger.info('Annotating Monopolar block')
        if dsp_monopolar_out['error_flag'] == 0: 
            output_fname = MATLAB.eztop_putou_e1(dsp_monopolar_out['path_to_data'], 
                                                 config.MP_ANNOTATIONS_FLAG,
                                                 paths) 
            MATLAB.removeEvents_1_5_cycles(output_fname, nargout=0)

            #This doesn't annotate anything in the evts. comment for now.
            '''
            MATLAB.ezpac_putou70_e1(dsp_monopolar_out['ez_mp'], 
                                    dsp_monopolar_out['ez_fr_mp'], 
                                    dsp_monopolar_out['ez_hfo_mp'], 
                                    output_fname,
                                    dsp_monopolar_out['metadata'],
                                    config.MP_ANNOTATIONS_FLAG,
                                    paths, 
                                    nargout=0)
            '''
        else:
            logger.info('Error in process_dsp_output, error_flag != 0')
        
        data['bp_channels'] = dsp_monopolar_out['ez_bp']
        metadata = dsp_monopolar_out['metadata']
        hfo_ai = dsp_monopolar_out['hfo_ai']
        fr_ai = dsp_monopolar_out['fr_ai']
 
    else:  #data['mp_channels'] is empty
        hfo_ai = np.zeros(len(data['bp_channels'][0])).tolist()
        fr_ai = hfo_ai

    return data['bp_channels'], metadata, hfo_ai, fr_ai 

def _bipolarAnnotations(bp_data, metadata, hfo_ai, fr_ai, paths):

    if bp_data:
        logger.info('Bipolar Block. Converting data from python to matlab (takes long).')
        dsp_bipolar_out = MATLAB.ez_detect_dsp_bipolar(bp_data, metadata, hfo_ai, fr_ai, paths)
        logger.info('Finished bipolar dsp block')

        logger.info('Annotating bipolar block')
        output_fname = MATLAB.eztop_putou_e1(dsp_bipolar_out['path_to_data'], 
                                             config.BP_ANNOTATIONS_FLAG, 
                                             paths)
        
        MATLAB.removeEvents_1_5_cycles(output_fname, nargout=0)
        
        '''
        MATLAB.ezpac_putou70_e1(dsp_bipolar_out['ez_bp'], 
                                dsp_bipolar_out['ez_fr_bp'], 
                                dsp_bipolar_out['ez_hfo_bp'], 
                                output_fname, 
                                dsp_bipolar_out['metadata'], 
                                config.BP_ANNOTATIONS_FLAG, 
                                paths, nargout=0)
        '''
    else:
        logger.info("Didn't enter dsp bipolar, bp_data was empty.")

#TODO ADD RESTRICTIONS TO PARAMETERS 
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser()
    
    parser.add_argument("-in", "--trc_path", 
                        help="The directory path to the file with the data to analize.", 
                        required=True)
    
    parser.add_argument("-out", "--xml_output_path", 
                        help="Path where the .evt output will be created.",
                        required=False, default= config.paths['xml_output_path'])
    
    parser.add_argument("-pdir", "--project_dir_path", 
                        help="Path to the root directory of the project. This is"+
                        " used to set relative paths of saving directories.",
                        required=False, default= config.paths['project_root'])

    #Is it worthy to support taking minutes in the 3 following args instead of just seconds?
    #I think Brain Quick will just call the program to analize the whole eeg.

    parser.add_argument("-str_t", "--start_time", 
                        help="An integer in seconds indicating from when, "+ 
                        "relative to the file duration, do you want to analize the eeg.",
                        required=False, default= config.START_TIME_DEFAULT, type=int) #TODO add restriction >0 
    
    parser.add_argument("-stp_t", "--stop_time", 
                        help="An integer number in seconds indicating up to when, relative"+
                        "to the file duration, do you want to analize the eeg.",
                        required=False, default= config.STOP_TIME_DEFAULT, type=int) 

    parser.add_argument("-c", "--cycle_time", 
                        help="A number in seconds indicating the size of the blocks"+ 
                        "for the data to be cut. This improves time performance.",
                        required=False, default= config.CYCLE_TIME_DEFAULT, type=int)

    parser.add_argument("-sug", "--suggested_montage", 
                        help="The name of one of the montages included in the TRC that should "+
                        "be considered as base montage.",
                        required=False, default= 'Ref.')

    parser.add_argument("-bp", "--bipolar_montage", 
                        help="The name of one of the montages included in the TRC with a definition "+
                        "of a pair electrode for every channel that we "+
                        "want to allow to move from referential to bipolar montage .",
                        required=False, default= 'Bipolar')

    parser.add_argument("-saf", "--swap_array_file_path", 
                        help="This optional file should contain a swap_array"+
                        " variable, which can be used to correct the channel"+
                        " assignments in case that channels were incorrectly"+
                        " assigned in the original EDF file as can be the case"+
                        " for intraop", required=False, default= config.paths['swap_array_file']) 

    args = parser.parse_args()
    
    paths = config.resolvePaths(args.trc_path, args.xml_output_path,  
                               args.project_dir_path, args.swap_array_file_path)

    hfo_annotate(paths, args.start_time, args.stop_time, args.cycle_time, 
                 args.suggested_montage, args.bipolar_montage)
    end = time. time()
    print("Whole execution time in seconds...")
    print(end - start)
    
    #def test_mem()
    #mem = max(memory_usage(proc=test_mem))
    #print("Maximum memory used: {0} MiB".format(str(mem)))
    #test_mem()
