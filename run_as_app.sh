#!/bin/bash

TRC_DIR='~/Documentos/TRCs/withMontages/'

#Project dependencies

#tpastore env
export PYENV_VERSION=3.5.3/envs/shennan

#Grito env
#source home/tpastore/hfo_engine/web_server/venv/bin/activate


#ENV='LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6'
PY='python'
APP='/home/tpastore/Code/ez-detect/ez_detect/run_as_app.py'

$PY $APP -in=$TRC_DIR/EEG_2080.TRC -stp_t=600 -sug=Suggested -bp=Bipolar

unset PYENV_VERSION