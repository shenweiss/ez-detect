from trcio import read_raw_trc
import sys
import io
from contextlib import redirect_stdout
def montage_names(trc_fname):

	f = io.StringIO()
	with redirect_stdout(f):
		raw = read_raw_trc(trc_fname, preload=False)
	out = f.getvalue()
	
	montage_names = raw._raw_extras[0]['montages'].keys()
	res = ",".join(montage_names)
	print(res)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error. Usage python montage_names.py trc_fname")
    else:
        montage_names(sys.argv[1])