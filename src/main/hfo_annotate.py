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
def hfo_annotate(paths, start_time, stop_time, cycle_time, sug_montage, bp_montage):
    logger.info('Running Ez Detect')

    raw_trc = read_raw_trc(paths['trc_fname'], preload=True, include=None)
    
    logger.info("Converting data from volts to microvolts...")
    raw_trc._data *= 1e06
    sampling_rate = int(raw_trc.info['sfreq'])
    
    #Debug info
    logger.info("TRC file: "+ paths['trc_fname'])
    logger.info("XML will be written to "+ paths['xml_output_path'])
    logger.info("Number of channels {}".format(raw_trc.info['nchan']) ) 
    logger.info("First data in microvolts: {}".format(str(raw_trc._data[0][0])))
    logger.info('Sampling rate: {}'.format(str(sampling_rate)+'Hz'))

    trc_fname = splitext(basename(paths['trc_fname']))[0] 

    #Note: The resampling was beeing made after getting the data and for each channel(process_batch.m)
    #so file pointers were being calculated with old sampling rate before, this may affect performance, 
    #especially if you want just a piece of the trc. Also npad='auto' may be faster cause gets to 
    #the next power of two size with padding but may affect data quality introducing artifacts,
    #this depends on the data.
     
    if sampling_rate != config.DESIRED_FREC_HZ:
        logger.info('Resampling data to ' +  str(config.DESIRED_FREC_HZ) + 'Hz')
        raw_trc.resample(config.DESIRED_FREC_HZ, npad="auto") 
        sampling_rate = int(raw_trc.info['sfreq'])
        logger.info('Sampling rate was updated to: ' + str(sampling_rate) +'Hz')

    file_pointers = _getFilePointers(sampling_rate, start_time, stop_time, 
                                     cycle_time, samples_num=len(raw_trc._data[0]))
    
    blocks = _calculateBlockAmount(file_pointers, sampling_rate )     

    #Note need to add patch that limits second cycle if < 60 seconds. Ask what is this
    eeg_data, metadata = _computeEEGSegments(file_pointers, trc_fname, blocks, raw_trc) #TODO do this inside each thread

    #_saveResearchData(paths['research'], blocks, metadata, eeg_data, chanlist, trc_fname)
    montages = raw_trc._raw_extras[0]['montages']
    montage = _buildMontageFromTRC(montages, raw_trc.info['ch_names'], sug_montage, bp_montage)

    #chanlist = _updateChanlist(raw_trc.info['ch_names'], paths['swap_array_file']) #To ask
    chanlist = np.array(raw_trc.info['ch_names'], dtype=object) #we need the np array for matlab engine for now
    useThreads = True
    if useThreads:
        _processParallelBlocks_threads(blocks, eeg_data, chanlist, metadata, montage, paths)
    else:
        _processParallelBlocks_processes(blocks, eeg_data, chanlist, metadata, montage, paths)

    rec_start_struct = time.localtime(raw_trc.info['meas_date'][0]) #gets a struct from a timestamp
    rec_start_time = datetime(*rec_start_struct[:6]) #translates struct to datetime
    write_evt(paths['xml_output_path'], paths['trc_fname'], 
              rec_start_time, raw_trc.info['ch_names'])


############  Private Funtions  #########

def _updateChanlist(ch_names, swap_array_file):
    ch_names = np.array(ch_names ,dtype=object) #for matlab engine
    if swap_array_file != 'NOT_GIVEN':
        swap_array = MATLAB.load(swap_array_file)
        ch_names = [ch_names[i-1] for i in swap_array] 
    return ch_names

def _getFilePointers(sampling_rate, start_time, stop_time, cycle_time, samples_num):
    file_pointers = {}
    seconds_to_jump = start_time - 1 #start_time_default is 1, meaning the first second
    file_pointers['start'] = seconds_to_jump * sampling_rate
    file_pointers['end'] = samples_num if stop_time == config.STOP_TIME_DEFAULT else int((stop_time-1)*sampling_rate)
    file_pointers['block_size'] = cycle_time * sampling_rate
    return file_pointers

def _calculateBlockAmount(file_pointers, sampling_rate):
    images_number = file_pointers['end'] - file_pointers['start'] + 1
    full_blocks = int(images_number / file_pointers['block_size'])
    images_remaining = images_number % file_pointers['block_size']
    seconds_remaining = int(images_remaining / sampling_rate)
    blocks = full_blocks+1 if seconds_remaining >= 100 else full_blocks #Ask about this line later.
    logger.info("Amount of blocks {}".format(str(blocks)))
    return blocks

def _computeEEGSegments(file_pointers, trc_fname, blocks, raw_trc):
    base_pointer = file_pointers['start']
    stop_pointer = file_pointers['end']
    block_size = file_pointers['block_size']
    eeg_data = []
    metadata = []
    
    for i in range(blocks):
        blocks_done = i
        block_start_ptr = base_pointer + blocks_done * block_size
        block_stop_ptr = min(block_start_ptr + block_size, stop_pointer)
        block_data = raw_trc.get_data( start=block_start_ptr, stop=block_stop_ptr) 
        metadata_i = {'file_id':trc_fname, 'file_block':str(i+1)}
        
        eeg_data.append(block_data)
        metadata.append(metadata_i)

    return eeg_data, metadata

def _saveResearchData(contest_path, metadata, eeg_data, chanlist):
    MATLAB.workspace['chanlist'] = chanlist
    for i in range(len(metadata)):
        MATLAB.workspace['eeg_data_i'] = eeg_data[i]
        MATLAB.workspace['metadata_i'] = metadata[i]
        trc_fname = metadata.file_id
        full_path = contest_path+trc_fname+'_'+str(i)+'.mat' 
        MATLAB.save(full_path, 'metadata_i', 'eeg_data_i', 'chanlist')
        #ask if it is worthy to save the blocks or not

def _buildMontageFromTRC(montages, chanlist, sug_montage_name, bp_montage_name):

    sug_lines = montages[sug_montage_name]['lines']
    bp_lines = montages[bp_montage_name]['lines']
    sug_defs = [def_pair for def_pair in montages[sug_montage_name]['inputs'][:sug_lines] ]
    bp_defs = [def_pair for def_pair in montages[bp_montage_name]['inputs'][:bp_lines]]
    def_ch_names_sug = [pair[1] for pair in sug_defs ] 
    def_ch_names_bp = [pair[1] for pair in bp_defs ] 
    
    try:
        assert(set(chanlist) == set(def_ch_names_sug))
    except AssertionError:
        logger.info("The 'Suggested montage' is badly formed, you must provide a definition" +
              " for each channel name that appears in the 'Ref.'' montage.")
        assert(False)

    montage = []
    for ch_name in chanlist: #First col of montage.mat
        sug_idx = def_ch_names_sug.index(ch_name)
        suggestion = config.REFERENTIAL if sug_defs[sug_idx][0] == 'AVG' else config.BIPOLAR #Second col of montage.mat  

        if suggestion == config.BIPOLAR: #Third col of montage .mat
            if sug_defs[sug_idx][0] == ch_name: #For now we mean exclusion in this way
                bp_ref = config.NO_BP_REF
                exclude = config.EXCLUDE_CH
            else: 
                #Note that we know by the previous conditions that the index exists.
                #That string is defined inside BQ and its value is 'AVG' or another
                #ch_name that we have asserted that is in chanlist.
                bp_ref = chanlist.index(sug_defs[sug_idx][0]) + 1 
                exclude = config.DONT_EXCLUDE_CH

        else: #suggestion == config.REFERENTIAL
            exclude = 0
            try: 
                bp_idx = def_ch_names_bp.index(ch_name)
                bp_ref = chanlist.index(bp_defs[bp_idx][0]) + 1
            except ValueError: #user didn't defined a bp pair for this channel
                bp_ref = config.NO_BP_REF

        chan_montage_info = tuple([ch_name, suggestion, bp_ref, exclude])
        montage.append(chan_montage_info)

    return np.array(montage, dtype=object)

def _processParallelBlocks_threads(blocks, eeg_data, chanlist, metadata, montage, paths):
    threads = []
    def startBlockThread(i):
        thread = threading.Thread(target= _processParallelBlock, name='DSP_block_'+str(i),
                 args=(eeg_data[i], chanlist, metadata[i], montage, paths))
        thread.start()
        threads.append(thread)
        return
    for i in range(blocks-1): #This launches a thread for all but the last block
        logger.info('Starting a thread for block ' + str(i+1) )
        startBlockThread(i)

    #For the last one we use current thread.
    logger.info('Starting a thread for block ' + str(blocks))
    startBlockThread(blocks-1)

    for t in threads:
        t.join()

def _processParallelBlocks_processes(blocks, eeg_data, chanlist, metadata, montage, paths):
    #Ask pool vs independent processes
    def multi_run_wrapper(args):
      return _processParallelBlock(*args)

    pool = Pool(blocks)
    arg_list = [(eeg_data[i], chanlist, metadata[i], montage, paths) for i in range(blocks)]
    pool.map(multi_run_wrapper, arg_list)
    pool.close()
    pool.join()

def _processParallelBlock(eeg_data, chanlist, metadata, ez_montage, paths):    
    #This is needed just cause matlab.engine doesnt support np arrays...
    #TODO translate lfbad to avoid disk usage.
    args_fname = paths['temp_pythonToMatlab_dsp']+'lfbad_args_'+metadata['file_block']+'.mat' 
    scipy.io.savemat(args_fname, dict(eeg_data=eeg_data, chanlist=chanlist, metadata=metadata, ez_montage=ez_montage))
    eeg_mp, eeg_bp, metadata = MATLAB.ez_lfbad(args_fname, nargout=3)
    
    #metadata.montage is a cell array of 1 * n 
    eeg_bp, metadata, hfo_ai, fr_ai = _monopolarAnnotations(eeg_mp, eeg_bp, metadata, paths)
    _bipolarAnnotations(eeg_bp, metadata, hfo_ai, fr_ai, paths)

def _monopolarAnnotations(eeg_mp, eeg_bp, metadata, paths):
        
    if eeg_mp: #not empty

        logger.info('Monopolar block. Converting data from python to matlab (takes long).')
        dsp_monopolar_out = MATLAB.ez_detect_dsp_monopolar(eeg_mp, eeg_bp, metadata, paths)
        logger.info('Finished dsp monopolar block')

        #TODO once ez top gets translated we can avoid using the disk for saving.
        logger.info('Annotating Monopolar block')
        if dsp_monopolar_out['error_flag'] == 0: 
            output_fname = MATLAB.eztop_putou_e1(dsp_monopolar_out['path_to_data'], 
                                                 config.MP_ANNOTATIONS_FLAG,
                                                 paths) 
            MATLAB.removeEvents_1_5_cycles(output_fname, nargout=0)

            #This doesn't annotate anything in the evts. comment for now.
            MATLAB.ezpac_putou70_e1(dsp_monopolar_out['ez_mp'], 
                                    dsp_monopolar_out['ez_fr_mp'], 
                                    dsp_monopolar_out['ez_hfo_mp'], 
                                    output_fname,
                                    dsp_monopolar_out['metadata'],
                                    config.MP_ANNOTATIONS_FLAG,
                                    paths, 
                                    nargout=0)
        else:
            logger.info('Error in process_dsp_output, error_flag != 0')
        
        eeg_bp = dsp_monopolar_out['ez_bp']
        metadata = dsp_monopolar_out['metadata']
        hfo_ai = dsp_monopolar_out['hfo_ai']
        fr_ai = dsp_monopolar_out['fr_ai']
 
    else:  #eeg_mp is empty
        hfo_ai = np.zeros(len(eeg_bp[0])).tolist()
        fr_ai = hfo_ai

    return eeg_bp, metadata, hfo_ai, fr_ai 

def _bipolarAnnotations(eeg_bp, metadata, hfo_ai, fr_ai, paths):

    if eeg_bp:
        logger.info('Bipolar Block. Converting data from python to matlab (takes long).')
        dsp_bipolar_out = MATLAB.ez_detect_dsp_bipolar(eeg_bp, metadata, hfo_ai, fr_ai, paths)
        logger.info('Finished bipolar dsp block')

        logger.info('Annotating bipolar block')
        output_fname = MATLAB.eztop_putou_e1(dsp_bipolar_out['path_to_data'], 
                                             config.BP_ANNOTATIONS_FLAG, 
                                             paths)
        
        MATLAB.removeEvents_1_5_cycles(output_fname, nargout=0)
        

        MATLAB.ezpac_putou70_e1(dsp_bipolar_out['ez_bp'], 
                                dsp_bipolar_out['ez_fr_bp'], 
                                dsp_bipolar_out['ez_hfo_bp'], 
                                output_fname, 
                                dsp_bipolar_out['metadata'], 
                                config.BP_ANNOTATIONS_FLAG, 
                                paths, nargout=0)

    else:
        logger.info("Didn't enter dsp bipolar, eeg_bp was empty.")

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
    print("Execution time in seconds...")
    print(end - start)
    
    #def test_mem()
    #mem = max(memory_usage(proc=test_mem))
    #print("Maximum memory used: {0} MiB".format(str(mem)))
    #test_mem()
