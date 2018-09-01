#!/bin/bash

dataset=$1
start_time=$2
stop_time=$3
cycle_duration=$4
clean_hfo_engine_afterwards=$5
dataset_path='~/EDFs/'$dataset
dataset_path="'$dataset_path'"


echo "Input configuration:"
echo "Dataset:" $dataset
echo "Dataset path:" $dataset_path
echo "Start time:" $start_time
echo "Stop time:" $stop_time
echo "Cycle duration:" $cycle_duration "(seconds)"
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
$matlab_path -nodesktop -r "tryAddPaths('$project_path');main($dataset_path,$start_time,$stop_time,$cycle_duration);quit" &

wait

if [ $clean_hfo_engine_afterwards == "--cleanOutputsAfter" ]
then
	echo "Cleaning outputs after execution..."
	cd $hfo_engine_path
	./clean.sh 
fi

echo "Input configuration:"
echo "Dataset:" $dataset
echo "Dataset path:" $dataset_path
echo "Start time:" $start_time
echo "Stop time:" $stop_time
echo "Cycle duration:" $cycle_duration "(seconds)"
echo "Clean hfo_engine afterwards: " $clean_hfo_engine_afterwards

echo "Output:"
echo "Total time:" $SECONDS "(seconds)"