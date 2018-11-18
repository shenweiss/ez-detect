import os
import sys
import scipy.io
import hdf5storage
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

def loadChansFromMontage(trc_filename, chans_num):

    filename = os.path.basename(trc_filename)
    filename = os.path.splitext(filename)[0]
    montage_filename = os.path.expanduser("~") + '/hfo_engine_1/montages/' + filename + '_montage.mat'
    aDic = scipy.io.loadmat(montage_filename)
    chanlist = [aDic['montage'][i][0][0] for i in range(chans_num) ]
    return chanlist

def trc_to_mat(trc_filename, saving_path):

    raw_trc = read_raw_trc(trc_filename, preload=True, include=None)
    
    print("Converting data from volts to microvolts")
    raw_trc._data *= 1e06
    print("Now data is in microvolts")

    eeg_edf = raw_trc.get_data() #ver si esto da bien
    print("First data in microvolts")
    print(str(eeg_edf[0][0]))

    header = {'srate':int(raw_trc.info['sfreq'])}
    
    chanlist = loadChansFromMontage(trc_filename, raw_trc.info['nchan'])
    #import pdb ;pdb.set_trace() 
    print('Channel list in trc')
    print(raw_trc.ch_names)
    print('Channel list in montage: ')
    print(chanlist)
    signalHeader = [{'signal_labels':chan_name} for chan_name in chanlist]
    print("Saving TRC mat") 

    #scipy.io.savemat(saving_path, dict(header=header, signalHeader=signalHeader, eeg_edf=eeg_edf)) #se guardan bien los valores. OK
    hdf5storage.savemat(saving_path, dict(header=header, signalHeader=signalHeader, eeg_edf=eeg_edf), format='7.3') #se guardan bien los valores. OK

    #GENERATE EEG_12.TRC MONTAGE
    #montage = generateMontage(raw_trc.info['ch_names'])
    #scipy.io.savemat('/home/tomas-pastore/hfo_engine_1/montages/EEG_12_montage.mat', dict(montage=montage))

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Error. Usage python trc_to_mat.py trc_filename saving_path")
    else:
        trc_to_mat(sys.argv[1], sys.argv[2])



