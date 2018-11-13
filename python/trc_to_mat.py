import os
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

def trc_to_mat(trc_filename, saving_path):

    raw_trc = read_raw_trc(trc_filename, preload=True, include=None)
    
    #Convert data from volts to microvolts
    print("Converting data from volts to microvolts")
    raw_trc._data *= 1e06
    print("Now data is in microvolts")

    eeg_edf = raw_trc.get_data() #ver si esto da bien
    print("First data sig must be 9.375 microvolts")
    print(str(eeg_edf[0][0]))

    header = {'srate':int(raw_trc.info['sfreq'])}
    
    filename = os.path.basename(trc_filename)
    filename = os.path.splitext(filename)[0]
    montage_filename = os.path.expanduser("~") + '/hfo_engine_1/montages/' + filename + '_montage.mat'
    aDic = scipy.io.loadmat(montage_filename)
    chanlist = [aDic['montage'][i][0][0] for i in range(raw_trc.info['nchan']) ]
    #import pdb ;pdb.set_trace() 
    print('Channel list: ')
    print(chanlist)
    signalHeader = [{'signal_labels':chan_name} for chan_name in chanlist]
    print("Saving TRC mat") 

    scipy.io.savemat(saving_path, dict(header=header, signalHeader=signalHeader, eeg_edf=eeg_edf)) #se guardan bien los valores. OK

    #GENERATE EEG_12.TRC MONTAGE
    #montage = generateMontage(raw_trc.info['ch_names'])
    #scipy.io.savemat('/home/tpastore/hfo_engine_1/montages/EEG_12_montage.mat', dict(montage=montage))

if __name__ == "__main__":
    print("length")
    print(str(len(sys.argv)))

    if len(sys.argv) < 3:
        print("Error. Usage python trc_to_mat.py trc_filename saving_path")
    else:
        trc_to_mat(sys.argv[1], sys.argv[2])



