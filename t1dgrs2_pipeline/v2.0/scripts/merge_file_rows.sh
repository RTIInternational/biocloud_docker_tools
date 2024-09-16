#!/bin/bash

merge_list=""
out_file=""
header_row_count=1

while [ "$1" != "" ]; 
do
	case $1 in
		--merge_list )		        shift
									merge_list=$1
									;;
		--out_file )			    shift
									out_file=$1
									;;
		--header_row_count )		shift
									header_row_count=$1
									;;
	esac
	shift
done

write_header=1
first_data_row=$(($header_row_count + 1))
for file in $(cat $merge_list); do
    if [ "$write_header" == "1" ]; then
        cat $file > $out_file
        write_header=0
    else
        tail -n +$first_data_row $file >> $out_file
    fi
done
