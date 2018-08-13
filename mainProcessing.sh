#!/bin/bash

cycle_duration=$1
batches_number=$2
dataset="'$3'"
clean_hfo_engine_afterwards="'$4'"

echo "Input configuration:"
echo "Cycle duration:" $cycle_duration "(seconds)"
echo "Number of batches:" $batches_number
echo "Dataset:" $dataset
echo "Clean hfo_engine afterwards: " $clean_hfo_engine_afterwards

matlab_path=~/matlab/bin/matlab
project_path=~/ez-detect #may be added as argument
hfo_engine_path=~/ez-detect/hfo_engine_1
tryAddPaths_path=~/ez-detect/misc_code

echo "Paths to be used:"
echo "Matlab path:" $matlab_path
echo "Project source:" $project_path
echo "Saving outputs directory:" $hfo_engine_path 

#Cleans outputs from previous executions.
cd $hfo_engine_path
./clean.sh 

#For matlab to find the method
cd $tryAddPaths_path 

SECONDS=0 #timestamp

#Instead of adding path for every session you can use savepath and then rmpath(genpath('$project_path'))
$matlab_path -nodesktop -r "tryAddPaths('$project_path');times_testing($cycle_duration,$batches_number,$dataset);quit" &

wait

echo "Processing dsp monopolar outputs..."

for file in $hfo_engine_path/matfiles/dsp_m_output_*.mat
do
	$matlab_path -nodesktop -r "tryAddPaths('$project_path');processDSPMonopolarOutput('$file');quit" &
done

wait

echo "Processing dsp bipolar outputs..."

for file in $hfo_engine_path/matfiles/dsp_bp_output_*.mat
do
	$matlab_path -nodesktop -r "tryAddPaths('$project_path');processDSPBipolarOutput('$file');quit" &
done

wait

#if [ $clean_hfo_engine_afterwards -eq '--clean' ]
#then
#	cd $hfo_engine_path
#	./clean.sh 
#fi

echo "Input configuration:"
echo "Cycle duration:" $cycle_duration "(seconds)"
echo "Number of batches:" $batches_number
echo "Dataset:" $dataset
echo "Clean hfo_engine afterwards: " $clean_hfo_engine_afterwards

echo "Output:"
echo "Total time:" $SECONDS "(seconds)"