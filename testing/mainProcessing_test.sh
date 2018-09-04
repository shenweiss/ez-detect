#!/bin/bash
#Usage ./mainProcessing_test.sh dataset_filename cycle_duration batches_number
# [--cleanOutputsAfterRun]

dataset=$1
cycle_duration=$2
batches_number=$3
clean_hfo_engine_afterwards=$4
dataset_path='~/EDFs/'$dataset
dataset_path="'$dataset_path'"

echo "Input configuration:"
echo "Dataset:" $dataset
echo "Dataset path: "$dataset_path
echo "Cycle duration:" $cycle_duration "(seconds)"
echo "Number of batches:" $batches_number
echo "Clean hfo_engine afterwards: " $clean_hfo_engine_afterwards

matlab_path=~/matlab/bin/matlab
project_path=~/ez-detect #may be added as argument
hfo_engine_path=~/ez-detect/hfo_engine_1
tryAddPaths_path=~/ez-detect/tools/misc_code

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

$matlab_path -nodesktop -r "tryAddPaths('$project_path');ez_detect_test($dataset_path,$cycle_duration,$batches_number);quit" &

wait

if [ $clean_hfo_engine_afterwards == "--cleanOutputsAfterRun" ]
then
	echo "Cleaning outputs after execution..."
	cd $hfo_engine_path
	./clean.sh 
fi

echo "Input configuration:"
echo "Dataset:" $dataset
echo "Dataset path: "$dataset_path
echo "Cycle duration:" $cycle_duration "(seconds)"
echo "Number of batches:" $batches_number
echo "Clean hfo_engine afterwards: " $clean_hfo_engine_afterwards

echo "Total time:" $SECONDS "(seconds)"