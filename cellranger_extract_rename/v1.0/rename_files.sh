#!/bin/bash

# Function to display script usage
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help         Display this help message"
 echo " -v, --verbose      Enable verbose mode"
 echo " -l, --linker       STRING Specify name of linker to prepend to extracted files (format 'RMIP_<ddd>_<ddd>_<w>_<ddd>_<w>') - Required"
 echo "                       e.g. linker='RMIP_001_001_A_001_A'"
 echo "                       Note that the Vial Identifier (last letter) is optional"
 echo " -z, --zip_file     STRING/PATH Specify name and path of ZIP file to read, decompress, and rename - Required"
 echo " -o, --output_dir   STRING/PATH Specify directory where to put extracted files.  Default = '.'"
 echo ""
 echo "Example usage"
 echo " Required flags:               ./rename_files.sh -z input_zip.zip -l RMIP_001_001_A_001_A"
 echo " Verbose mode:                 ./rename_files.sh -v -z input_zip.zip -l RMIP_001_001_A_246"
 echo " Writing to output directory:  ./rename_files.sh -z input_zip.zip -l RMIP_001_001_A_246 -o test_output"
}

# Defining tool functions
has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

echo_verbose() {
  if [ "$verbose_mode" == true ]; then echo $1; fi
}

# Function to handle options and arguments
handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in
      -h | --help)
        usage
        exit 0
        ;;
      -v | --verbose)
        verbose_mode=true
        ;;
      -l | --linker*)
        if ! has_argument $@; then
          echo "ERROR: Linker not specified." >&2
          usage
          exit 1
        fi

        linker=$(extract_argument $@)

        shift
        ;;
      -z | --zip_file*)
        if ! has_argument $@; then
          echo "ERROR: Input ZIP file not specified." >&2
          usage
          exit 1
        fi

        zip_file=$(extract_argument $@)

        shift
        ;;
      -o | --output_dir*)
        if ! has_argument $@; then
          echo "Warning: Output directory flag given, but not specified." >&2
          echo "Setting to current working directory." >&2
          output_dir=""
        else
          output_dir=$(extract_argument $@)
        fi

        shift
        ;;
      *)
        echo "Invalid option: $1" >&2
        usage
        exit 1
        ;;
    esac
    shift
  done
}

# Main script execution
handle_options "$@"

echo_verbose "Verbose mode turned on"
echo_verbose ""

# QC checks of input parameters
if [[ ${#linker} == 0 ]]; then
  echo "ERROR: Linker not supplied. Must specify linker"
  usage
  exit 1
fi

if [[ ${#zip_file} == 0 ]]; then
  echo "ERROR: ZIP file not supplied. Must specify ZIP file"
  usage
  exit 1
fi

if [[ ! -f ${zip_file} ]]; then
  echo "ERROR: ZIP file not found.  Please ensure path is correct and/or file exists"
  echo "Given zip_file: $zip_file"
  exit 1
fi

# Extracting basename from ZIP file name
zip_file_name=$(basename -- "$zip_file")
zip_file_name="${zip_file_name%.*}"
echo_verbose "ZIP file name extracted: $zip_file_name"

# If there is no output_dir supplied, then set to current working directory
if [[ ${#output_dir} == 0 ]]; then
  output_dir="./${linker}_${zip_file_name}"
fi

echo_verbose "Here is the directory to write to: ${output_dir}"

if [[ ! -d ${output_dir} ]]; then
  echo_verbose "Output directory '$output_dir' not found, creating..."
  mkdir -p $output_dir
fi

# Defining regex matches for each part of linker
linker_array[0]="RMIP"
linker_array[1]="[[:digit:]]{3}"
linker_array[2]="[[:digit:]]{3}"
linker_array[3]="[[:alpha:]]"
linker_array[4]="[[:digit:]]{3}"
linker_array[5]="[[:alpha:]]"

# Defining length restrictions for each part of linker
linker_piece_length_array[0]=4
linker_piece_length_array[1]=3
linker_piece_length_array[2]=3
linker_piece_length_array[3]=1
linker_piece_length_array[4]=3
linker_piece_length_array[5]=1


# Creating, splitting, and validating input linker
IFS="_" read -ra linker_split <<< "$linker"

echo_verbose ""
echo_verbose "Checking validity of linker format..."

j=0
for i in "${linker_split[@]}"; do
    echo_verbose "Linker part $j: $i"
    echo_verbose "Linker regexp: ${linker_array[$j]}"
    if [[ "$i" =~ ${linker_array[$j]} && ${#i} == ${linker_piece_length_array[$j]} ]]; then
        echo_verbose "Regexp match!"
    else
        echo_verbose "Regexp not match"
        echo_verbose ""
        echo "ERROR: Invalid linker format, exiting"
        usage
        exit 1
    fi
    ((j+=1))
    echo_verbose ""
done

if [[ $j -gt ${#linker_array[@]} || $j -lt 5 ]]; then
    echo "ERROR: Input linker not long enough, got length $j"
    echo "Expected length 5 or 6"
    usage
    exit 1
fi

file_list=(outs/web_summary.html outs/metrics_summary.csv outs/raw_feature_bc_matrix.h5 outs/possorted_genome_bam.bam outs/possorted_genome_bam.bam.bai outs/filtered_feature_bc_matrix.h5)
# file_list=(web_summary.html metrics_summary.csv raw_feature_bc_matrix.h5 possorted_genome_bam.bam possorted_genome_bam.bam.bai filtered_feature_bc_matrix.h5)
# file_list=(web_summary.html metrics_summary.csv raw_feature_bc_matrix.h5 possorted_genome_bam.bam possorted_genome_bam.bam.bai raw_feature_bc_matrix/matrix.mtx.gz raw_feature_bc_matrix/features.tsv.gz raw_feature_bc_matrix/barcodes.tsv.gz filtered_feature_bc_matrix/matrix.mtx.gz filtered_feature_bc_matrix/barcodes.tsv.gz filtered_feature_bc_matrix/features.tsv.gz)

# Extracting and renaming files
for file in ${file_list[@]}; do
  echo_verbose $file;

  # Extracting basename from ZIP file name
  file_name=$(basename -- "$file")
  file_name="${file_name%.*}"
  file_name_extension="${file##*.}"
  echo_verbose "File name extracted: $file_name"
  echo_verbose "File name extension extracted: $file_name_extension"
  file_name_comb=$file_name\.$file_name_extension

  unzip -j $zip_file $file -d $output_dir/$file_name_comb;
  
  # Removing "_bam" from filename
  if [[ $file_name_comb == *"_bam"* ]]; then
    echo_verbose "Found '_bam' in $file_name_comb"
    new_file=${file_name_comb//"_bam"/}
    echo_verbose "Removed '_bam': $new_file"
    echo_verbose "Moving '$output_dir/${file_name_comb}' to '$output_dir/${linker}_${new_file}'";
    echo_verbose ""
    mv $output_dir/${file_name_comb} $output_dir/${linker}_${new_file};
  else
    echo_verbose "Moving '$output_dir/${file_name_comb}' to '$output_dir/${linker}_${file_name_comb}'";
    echo_verbose ""
    mv $output_dir/${file_name_comb} $output_dir/${linker}_${file_name_comb};
  fi
  
done

echo_verbose "Copying ZIP file to output directory: $zip_file -> ${output_dir}/${linker}_${zip_file}"
cp $zip_file ${output_dir}/${linker}_${zip_file_name}.zip

echo_verbose "Reached end of script"
