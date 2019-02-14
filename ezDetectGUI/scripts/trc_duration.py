from trcio import read_raw_trc
import sys
import io
from contextlib import redirect_stdout
def montage_names(trc_fname):

	f = io.StringIO()
	with redirect_stdout(f):
		raw = read_raw_trc(trc_fname, preload=False)
	out = f.getvalue()
	duration = raw._raw_extras[0]['n_samples'] // raw._raw_extras[0]['sfreq'] 
	print(duration)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error. Usage python trc_duration.py trc_fname")
    else:
        montage_names(sys.argv[1])
