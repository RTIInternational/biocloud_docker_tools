#!/bin/bash

sample_results_dir=""
output_result_file=""
output_control_file=""

while [ "$1" != "" ]; 
do
	case $1 in
		--sample_results_dir )		shift
									sample_results_dir=$1
									;;
		--output_result_file )		shift
									output_result_file=$1
									;;
		--output_control_file )		shift
									output_control_file=$1
									;;
	esac
	shift
done

sample_results_dir=$(echo $sample_results_dir | perl -ne 'chomp; if (substr($_, -1) eq "/") { print $_; } else { print $_."/"; }')
mkdir -p $sample_results_dir

first_file=true
for file in $(ls $sample_results_dir*/*_for_export.tsv | grep -v qc ); do
    if [ "$first_file" = true ] ; then
        head -n 1 $file
        first_file=false
    fi
    tail -n +2 $file
done > $output_result_file

first_file=true
for file in $(ls $sample_results_dir*/*_for_export.tsv | grep qc ); do
    if [ "$first_file" = true ] ; then
        head -n 1 $file
        first_file=false
    fi
    tail -n +2 $file
done > $output_control_file
