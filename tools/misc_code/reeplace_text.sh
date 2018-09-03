#!/bin/bash

#Description: Reemplaces all appearances of 'old_text' within files, for 'new_text'
#recursively from the path indicated by the argument root_directory

#Usage ./reeplace_text.sh old_text new_text root_directory
#Note: It doesnt change the name of the files though

old_text=$1
new_text=$2
root_directory=$3

cd $root_directory

echo "Reeplacing in the following files..."
grep -rl --exclude-dir='.git' $old_text ./ 

grep -rl --exclude-dir='.git' $old_text ./ | xargs sed -i "s/$old_text/$new_text/g"

