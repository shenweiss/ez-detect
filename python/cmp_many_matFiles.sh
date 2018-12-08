#!/bin/bash

#Usage ./compare_many_results.sh '.mat_expected_dir' '.mat_obtained_dir' 'compare_results.py dir'
#If asks for execution permission: chmod +x compare_many_results.sh

initial_dir=$(pwd)
expected_dir=$1
obtained_dir=$2
compare_script_path=$3

#Ensuring they are full paths
cd $expected_dir
expected_dir=$(pwd) 

cd $initial_dir && cd $obtained_dir
obtained_dir=$(pwd)

cd $initial_dir && cd $compare_script_path
compare_script_path=$(pwd)

echo "Input:"
echo "Expected files:" $expected_dir 
echo "Obtained files:" $obtained_dir
echo "compare_results.py path:" $compare_script_path

echo "Comparing corresponding matfiles recursively..."

cd $expected_dir
files_expected="$(find -follow -name "*.mat")"

SECONDS=0 #timestamp
echo
echo

for file_relative_path in $files_expected
do
	fr_path=${file_relative_path:1} #Cut the first character '.' 
	cd $compare_script_path
	python3 cmp_matFiles.py --original=$expected_dir$fr_path --obtained=$obtained_dir$fr_path --delta=0.0000001

	echo "Done with file:" $file_relative_path 
	echo
	echo "######################################################################"
	echo
	
done

echo
echo "Total time:" $SECONDS "(seconds)"