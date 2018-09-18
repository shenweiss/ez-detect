
#Resamples edf sampling rate to the one given by parameter, default is 128 hz

import argparse
import os
import mne
import numpy as np
from scipy import signal
import pyedflib

def resample_edf_to(new_sampling_rate, input_edf_path, out_edf_path):
    
    raw_eeg = mne.io.read_raw_edf(input_edf_path, montage=None, eog=None, misc=None, 
                                  stim_channel='auto', annot=None, annotmap=None, 
                                  exclude=(), preload=True, verbose=None)
    
    eeg_picks = mne.pick_types(raw_eeg.info, meg=False, eeg=True, stim=False)
    raw_eeg = raw_eeg.copy().resample(new_sampling_rate, npad='auto')
    
    file_out = out_edf_path+'resampled_'+ str(new_sampling_rate)+'.edf'
    #raw_eeg.save(filename, picks=eeg_picks) this saves a .fif not edf

    #IDK if this below is right... trying to imitate https://github.com/holgern/pyedflib/blob/master/demo/writeEDFFile.py

    f = pyedflib.EdfWriter(file_out, len(raw_eeg.ch_names),
                           file_type=pyedflib.FILETYPE_EDF)

    channel_info = []
    channel_names = raw_eeg.ch_names

    for ch in range(len(raw_eeg.ch_names)):
        ch_dict = {'label': channel_names[ch], 'dimension': 'uV', 'sample_rate': raw_eeg.info['sfreq'], 'physical_max': 100, 'physical_min': -100, 'digital_max': 32767, 'digital_min': -32768, 'transducer': '', 'prefilter':''}
        channel_info.append(ch_dict)

    f.setSignalHeaders(channel_info)
    f.writeSamples(raw_eeg.get_data())
    f.close()
    
if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    
    parser.add_argument("-in", "--edf_input_path", 
                        help="The directory path to the input edf file.", 
                        required=True)
    
    parser.add_argument("-out", "--edf_output_path", 
                        help="Path where the resampled edf will be created.",
                        required=False, default= './')

    parser.add_argument("-sr", "--new_sampling_rate", 
                        help="The sampling rate you want for the output.",
                        required=False, default= 128, type= int)

    args = parser.parse_args()

    resample_edf_to(args.new_sampling_rate, args.edf_input_path, args.edf_output_path)