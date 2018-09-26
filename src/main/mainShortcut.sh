#!/bin/bash
#Description: This is just a shortcut for calling main while testing when you run constantly.
#Usage ./mainShortcut.sh dataset_filename xml_output_path cycle_duration blocks
#[--cleanOutputsAfterRun]
# COMMENTED OPTION: -py/-m, write -py for executing new python3 main. -m to call old matlab main instead
# dataset_filename is the name of the input edf to analize, for example 449_correct.edf
# xml_output_path is the path to the directory where output will be saved (not configured yet)
# cycle_duration the length in seconds for the data chunks to parallelize
# blocks the amount of cycles we want to process, along with cycle_duration will determine start
# and end pointers for reading the edf file.
#

#callMain=$1
dataset=$1
xml_output_path=$2
cycle_duration=$3
blocks=$4
clean_hfo_engine_afterwards=$5

dataset_path='/home/tomas-pastore/EDFs/'$dataset

echo "Input configuration:"
echo "Dataset:" $dataset
echo "Dataset path: "$dataset_path
echo "Cycle duration:" $cycle_duration "(seconds)"
echo "Number of blocks:" $blocks
echo "Clean hfo_engine afterwards:" $clean_hfo_engine_afterwards

project_path=~/ez-detect
matlab_path=~/matlab/bin/matlab
main_path=$project_path/src/main
hfo_engine_path=$project_path/hfo_engine_1/

echo "Paths to be used:"
echo "Matlab path:" $matlab_path
echo "Main path:" $main_path
echo "Saving outputs directory:" $hfo_engine_path 

start_time=1
stop_time=$(($cycle_duration * $blocks))
#For matlab to find main
cd $main_path 

SECONDS=0 #timestamp

#if [ $callMain == "-m" ]
#then
#	echo "Calling old matlab main..."
#	dataset_path="'$dataset_path'"
#	$matlab_path -nodesktop -r "hfo_annotate($dataset_path, $start_time, $stop_time, $cycle_duration);quit" &

#elif [ $callMain == "-py" ]
#then
#	echo "Calling python3.5 hfo_annotate..."
#	xml_output_path="'$xml_output_path'"
#	python hfo_annotate.py -in=$dataset_path -out=$xml_output_path -str_t=$start_time -stp_t=$stop_time -c=$cycle_duration
#fi

echo "Calling python3.5 hfo_annotate..."
	xml_output_path="'$xml_output_path'"
	python hfo_annotate.py -in=$dataset_path -out=$xml_output_path -str_t=$start_time -stp_t=$stop_time -c=$cycle_duration

wait

if [ $clean_hfo_engine_afterwards == "--cleanAfter=yes" ]
then
	echo "Cleaning outputs after execution..."
	cd $hfo_engine_path
	./clean.sh 
fi
rm -r -f $main_path/__pycache__


echo "Input configuration:"
echo "Dataset:" $dataset
echo "Dataset path: "$dataset_path
echo "Cycle duration:" $cycle_duration "(seconds)"
echo "Number of blocks:" $blocks
echo "Clean hfo_engine afterwards: " $clean_hfo_engine_afterwards

echo "Total time:" $SECONDS "(seconds)"