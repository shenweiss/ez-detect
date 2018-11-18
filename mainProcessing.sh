#!/bin/bash
SECONDS=0

#USAGE: important. needs to be RUN FROM HOME AS WD
#./mainProcessing.sh cycletime batches trc_in xml_out

echo "cycle time" $1
echo "batches" $2
trc_in=$3
xml_out=$4

cd ./'hfo_engine_1'
./clean.sh
cd ..
echo $(pwd)

rm -f ~/dsp_*_output_*.mat

~/matlab/bin/matlab  -r "try addpath(genpath('/home/tomas-pastore/ez-detect')); times_testing($1,$2,'$3'); catch; end; quit" &

wait


for file in ~/dsp_m_output_*.mat
do
    ~/matlab/bin/matlab  -r "try addpath(genpath('/home/tomas-pastore/ez-detect')); processDSPMonopolarOutput('$file'); catch; end; quit" &
done

wait

for file in ~/dsp_bp_output_*.mat
do
    ~/matlab/bin/matlab  -r "try addpath(genpath('/home/tomas-pastore/ez-detect')); processDSPBipolarOutput('$file'); catch; end; quit" &
done

wait
ENV='LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6'
PY='/home/tomas-pastore/anaconda3/bin/python'
APP='/home/tomas-pastore/ez-detect/python/write_xml.py'
output_path='/home/tomas-pastore/'$xml_out
command=$ENV $PY $APP $output_path '/home/tomas-pastore/TRCs/'$trc_in

echo $command
$command &

wait

echo 'Elapsed time(snds):' $SECONDS

