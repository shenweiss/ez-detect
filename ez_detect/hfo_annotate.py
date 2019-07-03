import time
import threading
from datetime import datetime
from pathlib import Path

import numpy as np
from evtio import load_events_from_matfiles, EventFile, write_evt
from ez_detect import config

from ez_detect.montage import build_montage_from_trc, build_montage_mat_from_trc
from ez_detect.preprocessing import ez_lfbad
from mne.utils import logger
from trcio import read_raw_trc

# PROFILING = str(Path(config.PROJECT_ROOT,'tools/profiling'))
# sys.path.insert(0, PROFILING)
# from profiling import profile_time, profile_memory

'''
Input:
    - trc_fname: The path to the TRC file to analyze, supports relative unresolved path.    
        
    - bipolar_montage: a string with the name of the montage with bipolar definitions
      in case ez-detect moves channels from referential to bipolar.
    
    - suggested_montage: a string with the name of the suggested montage default is to take
      all channels as ref, from the default montage builtin by trcio package.
    
    - start_time: an integer indicating from which second, relative to the file 
      duration, do you want to analyze the eeg.
    
    - stop_time: an integer indicating up to which second, relative to the file 
      duration, do you want to analyze the eeg.
      
      For example if you want to process the last 5 minutes of an eeg of 20 
      minutes you would use as input start_time = 15*60 = 900 and 
      stop_time = 20*60 = 1200.
    
    - cycle_time: an integer indicating the size in seconds of the parrallel blocks.
    
    - evt_fname: Path for where the generated .evt file with the detected events, will be saved. 
    
    - saf_fname: Path for an optional file, this should contain a swap_array
                 variable, which can be used to correct the channel assignments 
                 in case that channels were incorrectly assigned in the original 
                 EDF file as can be the case for intraop

 
Output: The events are writen in xml format writing an .evt file in the path indicated by
the input parameter 'evt_fname'

'''


# @profile_memory
# @profile_time
def hfo_annotate(trc_fname, bipolar_montage, suggested_montage = 'Ref.',
                 start_time = 0, stop_time = None, cycle_time = 600,
                 evt_fname = None, saf_fname = None, progress_notifier=None):

    logger.info('Running Ez Detect')

    #Parameters validation and needed path building

    paths = config.get_working_paths(trc_fname, evt_fname, saf_fname)
    raw_trc = read_raw_trc(paths['trc_fname'], include=None)

    montage_namelist = _montage_names(raw_trc)
    if bipolar_montage not in montage_namelist :
        raise ValueError('The provided bipolar montage is not an option of this trc file.')
    elif suggested_montage not in montage_namelist:
        raise ValueError('The provided suggested montage is not an option of this trc file.')

    if start_time < 0:
        raise ValueError('Start time must be >= 0.')

    if stop_time is not None and (stop_time <= start_time or stop_time > _duration_snds(raw_trc)):
        raise ValueError('Stop time must be greater than start time and can not exceed file duration.')

    #Todo validate cycle time with min block size for valid cudaica analysis

    #End of validations
    logger.info("Cropping data...")
    raw_trc.crop(start_time, stop_time).load_data()
    _update_progress(progress_notifier, 10)

    logger.info("Converting data from volts to microvolts...")
    #This is probably needed because of bad edfs lead to a bad trc format,
    #because data is in microvolts and mne uses volts
    raw_trc._data *= 1e06

    #Debug info
    logger.info("TRC file: {0}".format(paths['trc_fname']))
    logger.info("XML will be written to {0}".format(paths['evt_fname']))
    logger.info("Number of channels {}".format(raw_trc.info['nchan']))
    logger.info("First data in microvolts: {}".format( raw_trc._data[0][0]) )
    logger.info('Sampling rate: {value}{unit}'.format( value= int(raw_trc.info['sfreq']) ,
                                                       unit='Hz'))
    #Resampling data
    logger.info('Resampling data to: {} Hz'.format(2000))
    raw_trc.resample(2000, npad='auto')

    #Build metadata
    n_samples = len(raw_trc._data[0]) - 1
    sampling_rate = int(raw_trc.info['sfreq'])
    montages = raw_trc._raw_extras[0]['montages']
    metadata = {
        'file_id': Path(paths['trc_fname']).stem,
        'montage': build_montage_from_trc(montages, raw_trc.info['ch_names'],
                                          suggested_montage, bipolar_montage),
        'old_montage': build_montage_mat_from_trc(montages, raw_trc.info['ch_names'],
                                                  suggested_montage, bipolar_montage), # temporary
        'srate': sampling_rate,
        'n_blocks': _calculate_block_amount(sampling_rate, cycle_time, n_samples),
        'block_size': sampling_rate * cycle_time,
    }
    _update_progress(progress_notifier, 12)

    #Run in parallel
    _process_with_threads(raw_trc, metadata, paths, progress_notifier)
    _update_progress(progress_notifier, 95)

    #Write evt parsing shennan matfiles and txts
    rec_start_struct = time.localtime(raw_trc.info['meas_date'][0])  # gets a struct from a timestamp
    rec_start_time = datetime(*rec_start_struct[:6])  # translates struct to datetime
    events = load_events_from_matfiles(paths['ez_top_out'],
                                       raw_trc.info['ch_names'],
                                       rec_start_time)

    #TODO get username in runtime
    evt_file = EventFile(paths['evt_fname'], rec_start_time,
                         events=events, username='USERNAME')
    write_evt(evt_file)
    _update_progress(progress_notifier, 100)


############  Private Funtions  #########

def _update_progress(notifier, val):
    if notifier is not None:
        notifier.update(val)

def _montage_names(raw_trc):
    return list(raw_trc._raw_extras[0]['montages'].keys())

def _duration_snds(raw_trc):
    return raw_trc._raw_extras[0]['n_samples'] // raw_trc._raw_extras[0]['sfreq']


# Unused for now
def _updateChanlist(ch_names, swap_array_file, matlab_session):
    ch_names = np.array(ch_names, dtype=object)  # for matlab engine
    if swap_array_file == 'NOT_GIVEN':
        swap_array = matlab_session.load(swap_array_file)
        ch_names = [ch_names[i - 1] for i in swap_array]
    return ch_names


# Given n_samples returns how many blocks are formed by a given sampling_rate,
# separating in time blocks of size block_size_snds
def _calculate_block_amount(sampling_rate, block_size_snds, n_samples):
    block_size = sampling_rate * block_size_snds
    full_blocks = int(n_samples / block_size)
    images_remaining = n_samples % block_size
    seconds_remaining = images_remaining / sampling_rate
    n_blocks = full_blocks + 1 if seconds_remaining >= config.MIN_BLOCK_SNDS else full_blocks  # Ask about this line later.
    logger.info("Amount of blocks {}".format(str(n_blocks)))
    return n_blocks


# Unused for now
def _saveResearchData(contest_path, metadata, eeg_data, ch_names, matlab_session):
    matlab_session.workspace['ch_names'] = ch_names
    for i in range(len(metadata)):
        matlab_session.workspace['eeg_data_i'] = eeg_data[i]
        matlab_session.workspace['metadata_i'] = metadata[i]
        trc_fname = metadata.file_id
        full_path = contest_path + trc_fname + '_' + str(i) + '.mat'
        matlab_session.save(full_path, 'metadata_i', 'eeg_data_i', 'ch_names')
        # ask if it is worthy to save the blocks or not


def _process_with_threads(raw_trc, metadata, paths, progress_notifier):
    threads = []
    n_samples = len(raw_trc._data[0]) - 1
    ch_names = np.array(raw_trc.info['ch_names'], dtype=object),  # we need the np array for matlab engine for now

    def _get_block_data(i):
        logger.info('Creating thread {}'.format(i + 1))
        block_start = i * metadata['block_size']
        block_stop = min(block_start + metadata['block_size'], n_samples)
        return raw_trc.get_data(start=block_start, stop=block_stop)

    for i in range(metadata['n_blocks'] - 1):  # This starts a thread for all but the last block
        metadata['file_block'] = str(i + 1)
        thread = threading.Thread(target=_process_block,
                                  name='DSP_block_{}'.format(i + 1),
                                  args=(_get_block_data(i), ch_names, metadata, paths, progress_notifier))
        threads.append(thread)

    # For the last block we will use current thread.
    block_data = _get_block_data(metadata['n_blocks'] - 1)
    metadata['file_block'] = str(metadata['n_blocks'])

    for t in threads:
        t.start()

    _process_block(block_data, ch_names, metadata, paths, progress_notifier)  # process last block

    for t in threads:
        t.join()




def _process_block(eeg_data, ch_names, metadata, paths, progress_notifier):
    matlab_session = config.get_matlab_session()

    data, metadata = ez_lfbad(eeg_data, ch_names, metadata, matlab_session, paths['ez_bad_nn_in'])
    _update_progress(progress_notifier, 15)

    data['bp_channels'], metadata, hfo_ai, fr_ai = _referential_annotations(data, metadata, paths, progress_notifier,
                                                                            matlab_session)
    _update_progress(progress_notifier, 70)
    _bipolar_annotations(data['bp_channels'], metadata, hfo_ai, fr_ai, paths, progress_notifier, matlab_session)


def _referential_annotations(data, metadata, paths, progress_notifier, matlab_session):
    if data['mp_channels']:  # not empty

        logger.info('Monopolar block. Converting data from python to matlab (takes long).')
        dsp_monopolar_out = matlab_session.ez_detect_dsp_monopolar(data['mp_channels'], data['bp_channels'], metadata,
                                                                   paths)
        logger.info('Finished dsp monopolar block')
        _update_progress(progress_notifier, 60)

        # TODO once ez top gets translated we can avoid using the disk for saving.
        logger.info('Annotating Monopolar block')
        if dsp_monopolar_out['error_flag'] == 0:
            MP_ANNOTATIONS_FLAG = 0
            output_fname = matlab_session.eztop_putou_e1(dsp_monopolar_out['path_to_data'],
                                                         MP_ANNOTATIONS_FLAG,
                                                         paths['ez_top_out'])
            matlab_session.removeEvents_1_5_cycles(output_fname, nargout=0)

            # This doesn't annotate anything in the evts. comment for now.
            '''
            matlab_session.ezpac_putou70_e1(dsp_monopolar_out['ez_mp'], 
                                    dsp_monopolar_out['ez_fr_mp'], 
                                    dsp_monopolar_out['ez_hfo_mp'], 
                                    output_fname,
                                    dsp_monopolar_out['metadata'],
                                    config.MP_ANNOTATIONS_FLAG,
                                    paths['ez_pac_out'], 
                                    nargout=0)
            '''
        else:
            logger.info('Error in process_dsp_output, error_flag != 0')

        data['bp_channels'] = dsp_monopolar_out['ez_bp']
        metadata = dsp_monopolar_out['metadata']
        hfo_ai = dsp_monopolar_out['hfo_ai']
        fr_ai = dsp_monopolar_out['fr_ai']

    else:  # data['mp_channels'] is empty
        hfo_ai = np.zeros(len(data['bp_channels'][0])).tolist()
        fr_ai = hfo_ai

    return data['bp_channels'], metadata, hfo_ai, fr_ai


def _bipolar_annotations(bp_data, metadata, hfo_ai, fr_ai, paths, progress_notifier, matlab_session):
    if bp_data:
        logger.info('Bipolar Block. Converting data from python to matlab (takes long).')
        dsp_bipolar_out = matlab_session.ez_detect_dsp_bipolar(bp_data, metadata, hfo_ai, fr_ai, paths['ez_top_in'])
        logger.info('Finished bipolar dsp block')
        _update_progress(progress_notifier, 90)
        logger.info('Annotating bipolar block')
        BP_ANNOTATIONS_FLAG = 1
        output_fname = matlab_session.eztop_putou_e1(dsp_bipolar_out['path_to_data'],
                                                     BP_ANNOTATIONS_FLAG,
                                                     paths['ez_top_out'])

        matlab_session.removeEvents_1_5_cycles(output_fname, nargout=0)

        '''
        matlab_session.ezpac_putou70_e1(dsp_bipolar_out['ez_bp'], 
                                dsp_bipolar_out['ez_fr_bp'], 
                                dsp_bipolar_out['ez_hfo_bp'], 
                                output_fname, 
                                dsp_bipolar_out['metadata'], 
                                config.BP_ANNOTATIONS_FLAG, 
                                paths['ez_pac_out'], 
                                nargout=0)
        '''
    else:
        logger.info("Didn't enter dsp bipolar, bp_data was empty.")
