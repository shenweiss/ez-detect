import sys
import mne
from os.path import basename, splitext
from trcio import read_raw_trc, write_raw_trc

def main(edf_filename):

    filename = splitext(basename(edf_filename))[0] 
    filename = filename+".TRC"

    rawEDF = mne.io.read_raw_edf(edf_filename, stim_channel='auto', preload=True)

    #Rename channels to avoid cutting in write_raw_trc
    new_names = {}
    for chan in rawEDF.info['ch_names']:
        new_names[chan] = chan[4:-4]
        if chan[4:-4] == 'Annotat': #nice, for 449_correct.edf
            new_names[chan] = 'Annot'

    rawEDF.rename_channels(new_names)
    
    #Resampling, BQ only supports powers of 2
    #print('Resampling data to 128 Hz')
    #rawEDF.resample(128, npad="auto") 

    write_raw_trc(rawEDF, filename)
    
    

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error. Usage python edfToTrc.py edf_filename")
    else:
        main(sys.argv[1])

    
 