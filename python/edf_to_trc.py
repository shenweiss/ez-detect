import sys
from os.path import basename, splitext
import mne
import numpy as np
import trcio

def main(edf_filename):

    raw_edf = mne.io.read_raw_edf(edf_filename, preload=True)
    raw_edf.pick_types(eeg=True, stim=False)

    to_rename = {x: x.split(' ')[1].split('-')[0] for x in raw_edf.ch_names}
    raw_edf.rename_channels(to_rename)
 
    raw_edf._data *= 1e-06
    
    trc_fname = splitext(basename(edf_filename))[0] + ".TRC" 
    trcio.write_raw_trc(raw_edf, trc_fname)

    raw_trc = trcio.read_raw_trc(trc_fname, preload=True)

    # Same channels
    np.testing.assert_equal(raw_edf.ch_names, raw_trc.ch_names)

    # Same sample frequency
    np.testing.assert_equal(raw_edf.info['sfreq'], raw_trc.info['sfreq'])

    # Same data
    np.testing.assert_array_almost_equal(raw_edf._data, raw_trc._data)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error. Usage python edf_to_trc.py edf_filename")
    else:
        main(sys.argv[1])

    
 