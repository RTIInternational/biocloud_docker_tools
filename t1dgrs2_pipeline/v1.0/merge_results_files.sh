#!/bin/bash

sample_results_dir=""
output_file=""

while [ "$1" != "" ]; 
do
	case $1 in
		--sample_results_dir )		shift
									sample_results_dir=$1
									;;
		--output_file )			    shift
									output_file=$1
									;;
	esac
	shift
done

sample_results_dir=$(echo $sample_results_dir | perl -ne 'chomp; if (substr($_, -1) eq "/") { print $_; } else { print $_."/"; }')
mkdir -p $sample_results_dir

first_file=true
for file in $(ls $sample_results_dir*/*_for_export.tsv ); do
    if [ "$first_file" = true ] ; then
        head -n 1 $file
        first_file=false
    fi
    tail -n +2 $file
done > $output_file
