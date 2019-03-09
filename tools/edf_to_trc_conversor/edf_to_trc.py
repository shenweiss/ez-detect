#!/usr/bin/env python3

import mne
import trcio
import numpy as np
import json
import sys

def edf_to_trc(edf_fname, trc_fname):

    raw_edf = mne.io.read_raw_edf(edf_fname, preload=True)
    raw_edf.pick_types(eeg=True, stim=False)
    # If data comes in microvolts, this information is stored 
    # in the info dict in the unit_mul entry as -6. If it is volt, then it is stored as 1.
    #info['chs'][0]['unit'] info['chs'][0]['unit_mul']
    #to_rename = {x: x.split(' ')[1].split('-')[0] for x in raw_edf.ch_names}
    old_names = raw_edf.ch_names
    raw_edf = mapShortChanNames(raw_edf)
    new_names = raw_edf.ch_names

    confirmTranslations(old_names, new_names)
    raw_edf._data *= 1e-06 #From microvolts to volts
    trcio.write_raw_trc(raw_edf, trc_fname)

    #assertConversionIsOk(raw_edf, trc_fname)

def mapShortChanNames(raw_edf):
    
    LEN_WARNING = "TRC channel names must be 5 char length at most."
    
    with open("short_channel_names.json", 'r') as fid_r:
        short_name = json.load(fid_r)   

    update_needed = False
    to_rename = dict()
    for chan in raw_edf.ch_names:
        if len(chan) > 5:
            if chan in short_name.keys():
                to_rename[chan] = short_name[chan]
            else:
                short_name[chan] = 'RENAME' #Default must be longer than 5.
                if not update_needed: #First wrong name seen
                    print(LEN_WARNING)
                    print('Please rename the following channels...')
                while len(short_name[chan]) > 5: 
                    short_name[chan] = input(chan + ' --> ')

                to_rename[chan] = short_name[chan]
                update_needed = True

    if update_needed:                
        print('Saving short names for future convertions...')
        with open("short_channel_names.json", 'w') as fid_w:
            json.dump(short_name, fid_w)
    
    #import pdb; pdb.set_trace()
    raw_edf.rename_channels(to_rename)
    return raw_edf

def confirmTranslations(old_names, new_names):
    print('Channel name mapping: ')
    for i in range(len(old_names)):
        print('    ' + old_names[i] + ' --> ' + new_names[i])

    modify_translation = '_' 
    while modify_translation != 'Y' and modify_translation != 'N':  #ToDo improve and implement
        modify_translation = input('Do you want to change any channel translation?(Y/N)')

    if modify_translation:
        print('Not implemented yet.')
    
def assertConversionIsOk(raw_edf, trc_fname):

     #? Para saber si tras leer el edf los datos estaban en microvolts y entonces estuvo bien pasar los datos a volts 
    
    np.testing.assert_equal(abs(raw_edf._data[0][0] * 1e6) > 1, True)
    
    raw_trc = trcio.read_raw_trc(trc_fname, preload=True)
    np.testing.assert_equal(raw_edf.ch_names, raw_trc.ch_names)
    np.testing.assert_equal(raw_edf.info['sfreq'], raw_trc.info['sfreq'])
    np.testing.assert_array_almost_equal(raw_edf._data, raw_trc._data)

if __name__=='__main__':
    if len(sys.argv) < 3:
        print("Error. Usage python edf_to_trc.py edf_fname trc_fname")
    else:
        edf_to_trc(sys.argv[1], sys.argv[2])
