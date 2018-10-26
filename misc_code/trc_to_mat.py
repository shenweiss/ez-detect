#!/usr/bin/env python3.5
import sys
import scipy.io
import mne
from trcio import read_raw_trc
import numpy as np
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

    scipy.io.savemat('/home/tomas-pastore/Escritorio/449_correct_real_TRC.mat', dict(header=header, signalHeader=signalHeader, eeg_edf=eeg_edf))

    #GENERATE EEG_12.TRC MONTAGE
    #montage = generateMontage(raw_trc.info['ch_names'])
    #scipy.io.savemat('/home/tomas-pastore/hfo_engine_1/montages/EEG_12_montage.mat', dict(montage=montage))
    #scipy.io.savemat('/home/tomas-pastore/hfo_engine_1/montages/449_montage.mat', dict(montage=montage))

if __name__ == "__main__":
    trc_to_mat(sys.argv[1])

 #!LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 python /home/tomas-pastore/Escritorio/test.py 1

'''
    % Read EDF file
    %disp('filename in ')
    %disp(file_name_in)
    %[header, signalHeader, eeg_edf] = ez_edfload_putou02(file_name_in); %Note that this version modified to read max 60 minutes of EEG due to memory constraints.
    disp('EDF file load')
    %save(['/home/tomas-pastore/Escritorio/449_correct_EDF.mat'], 'header', 'signalHeader', 'eeg_edf', '-v7.3') 
    
    %Read TRC file
    error_status_readTRC = system(['LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 /home/tomas-pastore/anaconda3/bin/python /home/tomas-pastore/Escritorio/trc_to_mat.py ' file_name_in]);
    load('/home/tomas-pastore/Escritorio/449_correct_real_TRC.mat', 'header', 'signalHeader', 'eeg_edf' );
    signalHeader = cell2mat(signalHeader);
    '''