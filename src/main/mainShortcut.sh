#!/bin/bash
#Description: This is just a shortcut for calling main while testing when you run constantly.
#Usage ./mainShortcut.sh dataset_filename xml_output_path cycle_duration blocks
#[--cleanOutputsAfterRun]

# dataset_filename is the name of the input TRC to analize, for example 449_correct.TRC
# xml_output_path is the path to the directory where output will be saved (not configured yet)
# cycle_duration the length in seconds for the data chunks to parallelize
# blocks the amount of cycles we want to process, along with cycle_duration will determine start
# and end pointers for reading the edf file.

#Read input
dataset=$1
xml_output_path=$2
cycle_duration=$3
blocks=$4
clean_hfo_engine_afterwards=$5

#Configure these if you change working directory
dataset_path='/home/tomas-pastore/TRCs/'$dataset
hfo_engine_path='/home/tomas-pastore/hfo_engine_1/'

echo "Input configuration:"

echo "Dataset: "$dataset_path
echo "Xml filename:" $xml_output_path
echo "Cycle duration:" $cycle_duration "(seconds)"
echo "Number of blocks:" $blocks
echo "Clean hfo_engine afterwards:" $clean_hfo_engine_afterwards

start_time=1
stop_time=$(($cycle_duration * $blocks))
echo "Calling hfo_annotate.py"
SECONDS=0 #timestamp
python hfo_annotate.py -in=$dataset_path -out=$xml_output_path -str_t=$start_time -stp_t=$stop_time -c=$cycle_duration
wait

if [ $clean_hfo_engine_afterwards == "--cleanAfter=yes" ]
then
	echo "Cleaning outputs after execution..."
	rm -r -f __pycache__
	cd $hfo_engine_path
	./clean.sh 
fi

echo "Total time:" $SECONDS "(seconds)"