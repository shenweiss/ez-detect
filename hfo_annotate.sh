#!/bin/bash

#ENV='LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6'
PY='python'
APP='/home/tpastore/Documents/ez-detect/src/hfo_annotate.py'

$PY $APP -in=/home/tpastore/TRCs/EEG_2080.TRC -out=/home/tpastore/sprint_4_2.evt -c=600 -str_t=0 -stp_t=600 -sug=Suggested -bp=Bipolar
