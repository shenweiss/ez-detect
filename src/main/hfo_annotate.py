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
import config
from config import matlab_session as MATLAB

import sys
from os.path import basename, splitext, expanduser, abspath

from trcio import read_raw_trc
from mne.utils import verbose, logger
sys.path.insert(0, abspath(config.paths['project_root']+'src/evtio'))
from evtio import write_evt

import scipy.io
import hdf5storage

import numpy as np
import threading
import multiprocessing
import time
from datetime import datetime

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
 
Output: xml_output gets saved in the default directory or the one given as argument.
'''
def hfo_annotate(paths, start_time, stop_time, cycle_time, sug_montage, bp_montage):
    logger.info('Running EZ Detect\n')

    raw_trc = read_raw_trc(paths['trc_fname'], preload=True, include=None)
    
    logger.info("Converting data from volts to microvolts...")
    raw_trc._data *= 1e06
    
    #Debug info
    logger.info("Number of channels {}".format(raw_trc.info['nchan']) ) 
    logger.info("First data in microvolts: {}".format(str(raw_trc._data[0][0])))
    sampling_rate = int(raw_trc.info['sfreq'])
    logger.info('Sampling rate: {}'.format(str(sampling_rate)+'Hz'))

    #chanlist = _updateChanlist(raw_trc.info['ch_names'], paths['swap_array_file']) #this will be removed. Ask later.
    chanlist = np.array(raw_trc.info['ch_names'] ,dtype=object) 
    trc_fname = splitext(basename(paths['trc_fname']))[0] 

    #Note: The resampling was beeing made after getting the data and for each channel(process_batch.m)
    #so file pointers were being calculated with old sampling rate before, this may affect performance, 
    #especially if you want just a piece of the trc. Also npad='auto' may be faster cause gets to 
    #the next power of two size with padding but may affect data quality introducing artifacts,
    #this depends on the data.
    desired_hz = 2000  #Why? Generate name to add to config.py 
    if sampling_rate != desired_hz:
        logger.info('Resampling data to ' +  str(desired_hz) + 'Hz')
        raw_trc.resample(desired_hz, npad="auto") 
        sampling_rate = int(raw_trc.info['sfreq'])
        logger.info('Sampling rate was updated to: ' + str(sampling_rate) +'Hz')

    file_pointers = _getFilePointers(sampling_rate, start_time, stop_time, cycle_time, samples_num = len(raw_trc._data[0]) )
    blocks = _calculateBlockAmount(file_pointers, sampling_rate )     

    #Note need to add patch that limits second cycle if < 60 seconds. Ask what is this
    eeg_data, metadata = _computeEEGSegments(file_pointers, trc_fname, blocks, raw_trc) #TODO do this inside each thread

    #_saveResearchData(paths['research'], blocks, metadata, eeg_data, chanlist, trc_fname)
    header = raw_trc._raw_extras[0]
    montage = _buildMontageFromTRC(header['montages'], sug_montage_name=sug_montage, bp_montage_name=bp_montage)

    useThreads = True
    if useThreads:
        _processParallelBlocks_threads(blocks, eeg_data, chanlist, metadata, montage, paths)
    else:
        _processParallelBlocks_processes(blocks, eeg_data, chanlist, metadata, montage, paths)

    rec_start_struct = time.localtime(raw_trc.info['meas_date'][0]) #gets a struct from a timestamp
    rec_start_time = datetime(*rec_start_struct[:6]) #translates struct to datetime
    write_evt(paths['xml_output_path'], paths['trc_fname'], rec_start_time, raw_trc.info['ch_names'])


############  Private Funtions  #########

def _updateChanlist(chan_names, swap_array_file):
    chan_names = np.array(chan_names ,dtype=object) #because of matlab engine limitations
    if swap_array_file != 'NOT_GIVEN':
        swap_array = MATLAB.load(swap_array_file)
        chan_names = [chan_names[i-1] for i in swap_array] 
    return chan_names

#despues chequear que el start y stop esten en rango y que sea un bloque valido para ica
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

def _buildMontageFromTRC(montages, sug_montage_name='Suggested', bp_montage_name='Bipolar'):

    #TODO check that set(chanlist) == set(suggested_chanlist)
    REFERENTIAL = 1
    BIPOLAR = 0
    NO_BP_REF = 0
    sug_lines = montages[sug_montage_name]['lines']
    bp_lines = montages[bp_montage_name]['lines']
    chanlist = [pair[1] for pair in montages[bp_montage_name]['inputs'][:sug_lines] ] 
    bp_defined_channels = [pair[1] for pair in montages[bp_montage_name]['inputs'][:bp_lines]] 
    montage = []
    for i in range(sug_lines):
        suggestion = montages[sug_montage_name]['inputs'][i]       
        chan_name = suggestion[1] #first col of montage.mat
        suggested_mark = REFERENTIAL if suggestion[0] == 'AVG' else BIPOLAR #second col of montage.mat  
        if suggested_mark == BIPOLAR: #third col of montage .mat
            if suggestion[0] == chan_name: #for now I use this to exclude channels, substract with themselves
                bp_ref = 0
                exclude = 1
            else: 
                bp_ref  = chanlist.index(suggestion[0]) + 1
                exclude = 0
        else: ##el usuario sugirio que sea ref
            try: 
                chan_bp_idx = bp_defined_channels.index(chan_name)
                bp_ref = chanlist.index(montages[bp_montage_name]['inputs'][chan_bp_idx][0]) + 1
            except ValueError: #user didn't defined a bp pair for this channel
                bp_ref = NO_BP_REF
            exclude = 0

        chan_montage_info = tuple([chan_name, suggested_mark, bp_ref, exclude])
        montage.append(chan_montage_info)

    return np.array(montage, dtype=object)

def _processParallelBlocks_threads(blocks, eeg_data, chanlist, metadata, montage, paths):
    threads = []
    def startBlockThread(i):
        thread = threading.Thread(target=_processParallelBlock, name='DSP_block_'+str(i),
                 args=(eeg_data[i], chanlist, metadata[i], montage, paths))
        thread.start()
        threads.append(thread)
        return
    for i in range(blocks-1): #this launches a thread for all but the last block
        logger.info('Starting a thread')
        startBlockThread(i)
    logger.info('Starting last thread')
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
    args_fname = paths['temp_pythonToMatlab_dsp']+'lfbad_args_'+metadata['file_block']+'.mat' 
    scipy.io.savemat(args_fname, dict(eeg_data=eeg_data, chanlist=chanlist, metadata=metadata, ez_montage=ez_montage))

    eeg_mp, eeg_bp, metadata = MATLAB.ez_lfbad(args_fname, paths['montages'], nargout=3)
    #metadata.montage is a cell array of 1 * n 
    eeg_bp, metadata, hfo_ai, fr_ai = _monopolarAnnotations(eeg_mp, eeg_bp, metadata, paths)
    _bipolarAnnotations(eeg_bp, metadata, hfo_ai, fr_ai, paths)

def _monopolarAnnotations(eeg_mp, eeg_bp, metadata, paths):
        
    if eeg_mp: #not empty

        logger.info('Starting dsp monopolar block')
        logger.info('Converting data from python to matlab (takes long).')
        dsp_monopolar_out = MATLAB.ez_detect_dsp_monopolar(eeg_mp, eeg_bp, metadata, paths)
        logger.info('Finished dsp monopolar block')

        if dsp_monopolar_out['error_flag'] == 0: 
            montage_type = 0
            output_fname = MATLAB.eztop_putou_e1(dsp_monopolar_out['path_to_data'], montage_type, #the other ones are loaded inside because of matlab engine limitations
                                                 paths) #dsp_monopolar_out['DSP_data_m'], 
                                                        #dsp_monopolar_out['metadata'],
            MATLAB.removeEvents_1_5_cycles(output_fname, nargout=0)

            #MATLAB.ezpac_putou70_e1(dsp_monopolar_out['ez_mp'], 
            #                        dsp_monopolar_out['ez_fr_mp'], 
            #                        dsp_monopolar_out['ez_hfo_mp'], 
            #                        output_fname,
            #                        dsp_monopolar_out['metadata'],
            #                        montage,
            #                        paths, 
            #                        nargout=0)
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
        logger.info('Starting bipolar dsp block')
        logger.info('Converting data from python to matlab (takes long).')
        dsp_bipolar_out = MATLAB.ez_detect_dsp_bipolar(eeg_bp, metadata, hfo_ai, fr_ai, paths)
        logger.info('Finished bipolar dsp block')
        logger.info('Annotating bipolar block')

        montage_type = 1; 
        #dsp_bipolar_out['DSP_data_bp'], were parameters of ez_top before
        #dsp_bipolar_out['metadata'],
        output_fname = MATLAB.eztop_putou_e1(dsp_bipolar_out['path_to_data'], 
                                             montage_type, 
                                             paths)
        
        MATLAB.removeEvents_1_5_cycles(output_fname, nargout=0)
        

        #MATLAB.ezpac_putou70_e1(dsp_bipolar_out['ez_bp'], 
        #                        dsp_bipolar_out['ez_fr_bp'], 
        #                        dsp_bipolar_out['ez_hfo_bp'], 
        #                        output_fname, 
        #                        dsp_bipolar_out['metadata'], 
        #                        montage, 
        #                        paths, nargout=0)

        logger.info('Finished annotating bipolar block')
    else:
        logger.info("Didn't enter dsp bipolar, eeg_bp was empty.")


#TODO ADD RESTRICTIONS TO PARAMETERS EJ STARTIME >0 

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

    #Will this be kept?
    parser.add_argument("-saf", "--swap_array_file_path", 
                        help="This optional file should contain a swap_array"+
                        " variable, which can be used to correct the channel"+
                        " assignments in case that channels were incorrectly"+
                        " assigned in the original EDF file as can be the case"+
                        " for intraop", required=False, default= config.paths['swap_array_file']) 

    args = parser.parse_args()
    
    paths = config.updatePaths(config.paths, args.trc_path, args.project_dir_path, 
                               args.xml_output_path, args.swap_array_file_path)

    logger.info("XML will be written to "+ paths['xml_output_path'])
    hfo_annotate(paths, args.start_time, args.stop_time, args.cycle_time, 
                 args.suggested_montage, args.bipolar_montage)
