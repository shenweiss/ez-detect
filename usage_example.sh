#!/bin/bash

#ENV='LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6'
PY='python'
#Main module
APP='/home/tpastore/Code/ez-detect/ez_detect/hfo_annotate.py'

$PY $APP -in=/home/tpastore/Documentos/TRCs/EEG_2080.TRC -out=/home/tpastore/Documentos/sprint_3.evt -c=600 -str_t=0 -stp_t=600 -sug=Suggested -bp=Bipolar
