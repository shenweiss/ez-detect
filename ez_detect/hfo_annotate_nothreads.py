#!/usr/bin/env python3
# -*- coding: utf-8 -*-
 
# HFO detection for Behnke-Fried microelectrodes see Matlab files for more details
'''
Usage && INPUT arguments: type 'python3 hfo_annotate.py --help' in the shell
Example with defaults: python3 hfo_annotate.py --trc_path=449.TRC

'''
import time
start = time. time()
from ez_detect import config
from ez_detect.config import ProgressNotifier
import sys
from os.path import basename, splitext, expanduser, abspath

from mne.utils import verbose, logger
from trcio import read_raw_trc
from evtio import load_events_from_matfiles, EventFile, write_evt
#sys.path.insert(0, config.paths['project_root']+'/tools/profiling')
#from profiling import profile_time, profile_memory
from ez_detect.montage import build_montage_from_trc, build_montage_mat_from_trc
from ez_detect.preprocessing import ez_lfbad_lfp

import numpy as np
import threading
import pytz
import tzlocal
#import time
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

    - sug_montage: a string with the name of the suggested montage.

    - bp_montage: a string with the name of the montage with bipolar definitions
      in case ez-detect moves channels from referential to bipolar.
 
Output: xml_output gets saved in the default directory or the one given as argument.
'''
#@profile_memory
#@profile_time
#TODO modify plugin to take start_time from 0 instead of 1
#TODO stop add 1 to stop_time
def hfo_annotate_nothreads(trc_fname, start_time, stop_time, cycle_time, sug_montage, bp_montage, evt_fname, paths, progress_notifier=None):
    logger.info('Running Ez Detect')
    raw_trc = read_raw_trc(trc_fname, include=None)     #raw_trc = read_raw_trc(paths['trc_fname'], include=None)
    if len(raw_trc.ch_names) > 128 : # required due to montage size limit deletes channels > 128
        chlistlen=len(raw_trc.ch_names)
        removelist=raw_trc.ch_names[128:chlistlen]
        raw_trc.drop_channels(removelist)
    stop_time = stop_time if stop_time != config.STOP_TIME_DEFAULT else None
    raw_trc.crop(start_time, stop_time).load_data()  
    _update_progress(progress_notifier, 10)

    logger.info("Converting data from volts to microvolts...")
    raw_trc._data *= -1e06 #polarity reversed to correct
    #Debug info
    logger.info("TRC file: "+ trc_fname) #logger.info("TRC file: "+ paths['trc_fname'])
    logger.info("XML will be written to "+ evt_fname)  #logger.info("XML will be written to "+ paths['xml_output_path'])
    logger.info("Number of channels {}".format(raw_trc.info['nchan']) ) 
    logger.info("First data in microvolts: {}".format(str(raw_trc._data[0][0])))
    logger.info('Sampling rate: {}'.format(str(int(raw_trc.info['sfreq']))+'Hz'))
    
    if not raw_trc.info['sfreq'] == 2000:
        logger.info('Resampling data to: {} Hz'.format(str(config.DESIRED_FREC_HZ)) )
        raw_trc.resample(config.DESIRED_FREC_HZ, npad = 'auto') 
 
    n_samples = len(raw_trc._data[0])
    sampling_rate = int(raw_trc.info['sfreq'])
    montages = raw_trc._raw_extras[0]['montages']
    metadata = { 
        'file_id' : splitext(basename(trc_fname))[0], #splitext(basename(paths['trc_fname']))[0],
        'montage' : build_montage_from_trc(montages, raw_trc.info['ch_names'],
                                           sug_montage, bp_montage), #temporary
        'old_montage': build_montage_mat_from_trc(montages, raw_trc.info['ch_names'],
                                           sug_montage, bp_montage),
        'n_blocks' : _calculateBlockAmount(n_samples, sampling_rate, cycle_time),
        'block_size' : sampling_rate * cycle_time,
        'srate' : sampling_rate
    }
    _update_progress(progress_notifier, 12)
    _mainDSPloop(raw_trc, metadata, paths, montages, sug_montage, bp_montage, progress_notifier)
    _update_progress(progress_notifier, 95)
    #rec_start_struct = time.localtime(raw_trc.info['meas_date'][0]) #time.localtime(raw_trc.info['meas_date'][0]) #gets a struct from a timestamp
    #rec_start_time = datetime(*rec_start_struct[:6]) #translates struct to datetime
    local_timezone = tzlocal.get_localzone()
    rec_start_time = raw_trc.info['meas_date']
    rec_start_time = rec_start_time.replace(tzinfo=pytz.utc).astimezone(local_timezone)
    events = load_events_from_matfiles('/data/downstate/ez-detect/disk_dumps/ez_top/output/', raw_trc.info['ch_names'], metadata['montage'].pair_references, rec_start_time)
    evt_file = EventFile(evt_fname, rec_start_time, events=events, username='USERNAME') #TODO bring username from execution
    write_evt(evt_file)
    _update_progress(progress_notifier, 100)

############  Private Funtions  #########
def _update_progress(notifier, val):
    if notifier is not None:
        notifier.update(val)

#Unused for now
def _updateChanlist(ch_names, swap_array_file, matsession):
    ch_names = np.array(ch_names ,dtype=object) #for matlab engine
    if swap_array_file != 'NOT_GIVEN':
        swap_array = matsession.load(swap_array_file)
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

def _mainDSPloop(raw_trc, metadata, paths, montages, sug_montage, bp_montage, progress_notifier):
     
    n_samples = len(raw_trc._data[0])
    ch_names = np.array(raw_trc.info['ch_names'], dtype=object), #we need the np array for matlab engine for now
    ch_names_python = raw_trc.info['ch_names']
    def _get_block_data(i):
        logger.info('Creating block {}'.format(i+1) )
        block_start = i * metadata['block_size']    
        block_stop = min(block_start + metadata['block_size'], n_samples)
        return raw_trc.get_data( start=block_start, stop=block_stop) 
        
    for i in range(metadata['n_blocks']-1): #This starts a thread for all but the last block
        metadata['file_block'] = str(i+1)
        block_data = _get_block_data(i)
        _DSPloop(block_data, ch_names, ch_names_python, metadata, paths, montages, sug_montage, bp_montage, progress_notifier) #process last block 

    #last block
    block_data = _get_block_data(metadata['n_blocks']-1)
    metadata['file_block'] = str(metadata['n_blocks'])
    _DSPloop(block_data, ch_names, ch_names_python, metadata, paths, montages, sug_montage, bp_montage, progress_notifier) #process last block 

def _DSPloop(eeg_data, ch_names, ch_names_python, metadata, paths, montages, sug_montage, bp_montage, progress_notifier):    
    matsession = config.get_matlab_session()
    
    metadata['montage'] = build_montage_from_trc(montages, ch_names_python, sug_montage, bp_montage)

    data, metadata = ez_lfbad_lfp(eeg_data, ch_names, metadata, matsession)
    _update_progress(progress_notifier, 15)

    data['bp_channels'], metadata, hfo_ai, fr_ai = _monopolarAnnotations(data, metadata, paths, progress_notifier, matsession)
    _update_progress(progress_notifier, 70)
    #_bipolarAnnotations(data['bp_channels'], metadata, hfo_ai, fr_ai, paths, progress_notifier, matsession)

def _monopolarAnnotations(data, metadata, paths, progress_notifier, matsession):
    
    if data['mp_channels']: #not empty

        logger.info('Monopolar block. Converting data from python to matlab (takes long).')
        dsp_monopolar_out = matsession.ez_detect_dsp_monopolar_lfp(data['mp_channels'], data['bp_channels'], metadata, paths)
        logger.info('Finished dsp monopolar block')
        _update_progress(progress_notifier, 60)

        #TODO once ez top gets translated we can avoid using the disk for saving.
        logger.info('Annotating Monopolar block')
        if dsp_monopolar_out['error_flag'] == 0: 
            output_fname = matsession.eztop_putou_e1_lfp(dsp_monopolar_out['path_to_data'], 
                                                 config.MP_ANNOTATIONS_FLAG,
                                                 '/data/downstate/ez-detect/disk_dumps/ez_top/output') 
            matsession.removeEvents_1_5_cycles(output_fname, nargout=0)
                       
            #matsession.ezpac_putou70_e1(dsp_monopolar_out['ez_mp'], 
            #                        dsp_monopolar_out['ez_fr_mp'], 
            #                        dsp_monopolar_out['ez_hfo_mp'], 
            #                        output_fname,
            #                        dsp_monopolar_out['metadata'],
            #                        config.MP_ANNOTATIONS_FLAG,
            #                        '/data/downstate/ez-detect/disk_dumps/ez_pac_output', 
            #                        nargout=0)
            
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
