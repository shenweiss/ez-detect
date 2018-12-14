#!/bin/bash

#ENV='LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6'
PY='python'
APP='/home/tomas-pastore/ez-detect/src/main/hfo_annotate.py'

$PY $APP -in=/home/tomas-pastore/TRCs/449_correct.TRC -out=/home/tomas-pastore/449_correct_py_3.evt -c=600 -str_t=1 -stp_t=601
