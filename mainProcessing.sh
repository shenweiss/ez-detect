SECONDS=0

#RUN FROM HOME AS WD!

echo "cycle time" $1
echo "batches" $2

#cd ./'hfo_engine_1'
#./clean.sh
#cd ..
#echo $(pwd)

#rm -f ~/dsp_*_output_*.mat

#~/matlab/bin/matlab  -r "try addpath(genpath('/home/tomas-pastore/ez-detect')); times_testing($1,$2,'$3'); catch; end; quit" &

#wait
'''
for file in ~/dsp_m_output_*.mat
do
    ~/matlab/bin/matlab  -r "try addpath(genpath('/home/tomas-pastore/ez-detect')); processDSPMonopolarOutput('$file'); catch; end; quit" &
done

#wait

for file in ~/dsp_bp_output_*.mat
do
    ~/matlab/bin/matlab  -r "try addpath(genpath('/home/tomas-pastore/ez-detect')); processDSPBipolarOutput('$file'); catch; end; quit" &
done

wait
'''
#WRITE XML, otra opcion es agarrar los txt

ENV='LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6'
PY='/home/tomas-pastore/anaconda3/bin/python'
APP='/home/tomas-pastore/ez-detect/python/write_xml.py'
output_path='/home/tomas-pastore/Escritorio/xml_449_correct.evt'

command=$ENV $PY $APP $output_path

echo $command
$command &

wait

echo $SECONDS

