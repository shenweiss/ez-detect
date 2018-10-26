SECONDS=0

echo "cycle time" $1
echo "batches" $2

#cd ./'hfo_engine_1'
#./clean.sh
#cd ..
echo $(pwd)

#rm -f ~/dsp_*_output_*.mat

#~/matlab/bin/matlab  -r "try addpath(genpath('/home/tomas-pastore/ez-detect')); times_testing($1,$2,'$3'); catch; end; quit" &

#wait


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

echo $SECONDS

