#!/bin/bash
source ezDetectEnv/source/activate
python ez-detect/src/main/hfo_annotate.py -in=/home/tpastore/TRCs/MULAC.TRC -out=/home/tpastore/xml_out.evt -c=300 -str_t=1 -stp_t=300