#!/bin/bash

if [ ! -f *.zip ]
then
  echo "No zip file found.  Exiting"
  exit 1
else
  echo "Ding!  Found zip file.  Proceeding with extraction script"
fi

if [ ! -f output.csv ]
then
    echo "Output file does not exist. Initializing..."
    echo "sample_name,total_sequences,read_length,max_per_sequence_quality_scores,average_per_base_seq,average_sequence_duplication_levels" > output.csv
else
    echo "Output file found.  Appending results to the end"
fi

if [ ! -d output_dir ]
then
  mkdir ./output_dir
  unzip '*.zip' -d ./output_dir
fi

# Extracting Sample name, Total Sequences, and average sequence read length from JSON file
file_to_read=$(find ./output_dir -maxdepth 1 -name '*.json')
echo "Reading from $file_to_read"

sample_name=$(jq '.report_data_sources.FastQC.all_sections | to_entries[] | .key' $file_to_read)
echo "Sample name for this run: $sample_name"
total_sequences=$(jq .report_general_stats_data[1].$sample_name.total_sequences $file_to_read)
read_length=$(jq .report_general_stats_data[1].$sample_name.avg_sequence_length $file_to_read)

# Highest Per sequence quality scores
echo "Extracting for Highest Per sequence quality scores"
per_sequence_quality_scores_file=$(find ./output_dir -maxdepth 1 -name '*per_sequence_quality_scores*.txt')
echo "Reading from $per_sequence_quality_scores_file"
max_per_sequence_quality_scores=$(Rscript extract_max_per_seq_quality_score.r $per_sequence_quality_scores_file)

# Average Per base sequence content after 30 cycles
echo "Extracting for Average Per base sequence content after 30 cycles"
per_base_seq_quality_file=$(find ./output_dir -maxdepth 1 -name '*per_base_sequence_quality*.txt')
echo "Reading from $per_base_seq_quality_file"
average_per_base_seq=$(Rscript extract_avg_per_base_seq_quality.r $per_base_seq_quality_file)

# Average Sequence duplication levels as percentage of duplicates
echo "Extracting for Average Sequence duplication levels as percentage of duplicates"
sequence_duplication_levels_file=$(find ./output_dir -maxdepth 1 -name '*sequence_duplication_levels*.txt')
echo "Reading from $sequence_duplication_levels_file"
average_sequence_duplication_levels=$(Rscript extract_avg_seq_duplication_level.r $sequence_duplication_levels_file)

# Appending to output.csv
echo "$sample_name,$total_sequences,$read_length,${max_per_sequence_quality_scores:4},${average_per_base_seq:4},${average_sequence_duplication_levels:4}" >> output.csv

# Removing the unzipped directory
rm -rf ./output_dir
