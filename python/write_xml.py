#!/usr/bin/env python3.5
import sys
from xml_writer import write_xml

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error. Usage python write_xml.py output_path")
    else:
        write_xml(sys.argv[1])

