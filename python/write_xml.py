#!/usr/bin/env python3.5
import sys
from evtio import write_evt

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Error. Usage python write_xml.py output_path trc_path")
    else:
        write_evt(sys.argv[1], sys.argv[2])

