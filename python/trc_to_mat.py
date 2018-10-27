#!/usr/bin/env python3.5
import sys
import scipy.io
import mne
from trcio import read_raw_trc
import numpy as np
from datetime import datetime

#import matlab.engine

def generateMontage(chanlist):
    montage = []
    #Temp solution
    for chan in chanlist:
        #ref = int(chan_index+1) if chan_index % 10 == 1 else 0
        referential = int(1)
        no_matter = int(0)
        dont_exclude = int(0)
        chan_montage_info = tuple([chan, referential, no_matter, dont_exclude])
        montage.append(chan_montage_info)

    return np.array(montage,dtype=object)


def trc_to_mat(trc_filename):

    raw_trc = read_raw_trc(trc_filename, preload=True, include=None)
    print('TRC file loaded')
    
    trc_header = raw_trc._raw_extras[0]


    header = {'srate':int(raw_trc.info['sfreq'])}

    #print(raw_trc.info['ch_names'])
    signalHeader = [{'signal_labels':chan_name} for chan_name in raw_trc.info['ch_names']]

    eeg_edf = raw_trc.get_data() #ver si esto da bien


    scipy.io.savemat('/home/tomas-pastore/hfo_engine_1/TRC_in_mat/449_correct_real_TRC.mat', dict(header=header, signalHeader=signalHeader, 
                                                                                     eeg_edf=eeg_edf))

    #GENERATE EEG_12.TRC MONTAGE
    #montage = generateMontage(raw_trc.info['ch_names'])
    #scipy.io.savemat('/home/tomas-pastore/hfo_engine_1/montages/EEG_12_montage.mat', dict(montage=montage))
    #scipy.io.savemat('/home/tomas-pastore/hfo_engine_1/montages/449_montage.mat', dict(montage=montage))

if __name__ == "__main__":
    trc_to_mat(sys.argv[1])

