#!/bin/bash

if [ ! -f *.zip ]
then
  echo "No input zip file found.  Exiting"
  exit 1
else
  echo "Found input zip file.  Proceeding with extraction script"
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

output_file_name="${sample_name:1:-1}_output.csv"
if [ ! -f $output_file_name ]
then
    echo "Output file does not exist. Initializing..."
    echo "sample_name,total_sequences,read_length,max_per_sequence_quality_scores,per_base_seq,sd_per_base_seq,sequence_duplication_levels,sd_sequence_duplication_levels,average_per_base_n_content,sd_per_base_n_content" > $output_file_name
else
    echo "Output file found for ${sample_name}.  Appending results to the end"
fi

# Highest Per sequence quality scores
echo "Extracting for Highest Per sequence quality scores"
per_sequence_quality_scores_file=$(find ./output_dir -maxdepth 1 -name '*per_sequence_quality_scores*.txt')
echo "Reading from $per_sequence_quality_scores_file"
max_per_sequence_quality_scores=$(Rscript extract_max_per_seq_quality_score.r $per_sequence_quality_scores_file)

# Average Per base sequence content after 30 cycles
echo "Extracting for Average Per base sequence content after 30 cycles"
per_base_seq_quality_file=$(find ./output_dir -maxdepth 1 -name '*per_base_sequence_quality*.txt')
echo "Reading from $per_base_seq_quality_file"
per_base_seq=$(Rscript extract_per_base_seq_quality.r $per_base_seq_quality_file)

# Average Sequence duplication levels as percentage of duplicates
echo "Extracting for Average Sequence duplication levels as percentage of duplicates"
sequence_duplication_levels_file=$(find ./output_dir -maxdepth 1 -name '*sequence_duplication_levels*.txt')
echo "Reading from $sequence_duplication_levels_file"
sequence_duplication_levels=$(Rscript extract_seq_duplication_level.r $sequence_duplication_levels_file)

# Average Sequence duplication levels as percentage of duplicates
echo "Extracting for Average Sequence duplication levels as percentage of duplicates"
per_base_n_content_file=$(find ./output_dir -maxdepth 1 -name '*per_base_n_content*.txt')
echo "Reading from $per_base_n_content_file"
per_base_n_content=$(Rscript extract_per_base_n_content.r $per_base_n_content_file)

# Appending to output CSV file
echo "$sample_name,$total_sequences,$read_length,${max_per_sequence_quality_scores:4},${per_base_seq:5:-1},${sequence_duplication_levels:5:-1},${per_base_n_content:5:-1}" >> $output_file_name

# Removing the unzipped directory
# rm -rf ./output_dir
