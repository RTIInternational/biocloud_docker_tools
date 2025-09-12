#!/bin/bash
set -e

# Function to display script usage
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help             Display this help message"
 echo " -v, --verbose          Enable verbose mode"
 echo " -p, --pilot            Enable pilot mode"
 echo " -c, --compressed_output_mode            Enable compressing output, default FALSE"
 echo " -l, --linker           STRING Specify name of linker to prepend to extracted files (format 'RMIP_<ddd>_<alphanum>_<w>_<ddd>_<w>') - Required"
 echo "                          e.g. linker='RMIP_001_allo1_A_001_A'"
 echo "                          Note that the Vial Identifier (last letter) is optional"
 echo " -i, --input_dir        STRING/PATH Specify name and path of input directory to read - one of either ZIP or Input Directory Required"
 echo " -z, --input_zip        STRING/PATH Specify name and path of ZIP file to read - one of either ZIP or Input Directory Required"
 echo " -o, --output_dir       STRING/PATH Specify directory where to put extracted files.  Default = '.'"
 echo ""
 echo "Example usage"
 echo " Required flags (ZIP input):               ./rename_files.sh -z outs.zip -l RMIP_001_allo1_A_001_A"
 echo " Required flags (DIRECTORY input):         ./rename_files.sh -i outs -l RMIP_001_allo1_A_001_B"
 echo " Required flags (BOTH - defaults to ZIP):  ./rename_files.sh -z outs.zip -i outs -l RMIP_001_allo1_A_001_C"
 echo " Writing to output directory:              ./rename_files.sh -z outs.zip -l RMIP_001_allo1_A_001_D -o outs"
 echo " Verbose mode:                             ./rename_files.sh -v -z outs.zip -l RMIP_001_allo1_A_001_E"
 echo " Pilot mode:                               ./rename_files.sh -p -z outs.zip -l RMIP_001_PL_001"
}

# Defining tool functions
has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

echo_verbose() {
  if [ "$VERBOSE_MODE" == true ]; then echo $1; fi
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
        VERBOSE_MODE=true
        ;;
      -c | --compress_output_mode)
        COMPRESSED_OUTPUT_MODE=true
        ;;
      -p | --pilot)
        PILOT_MODE=true
        ;;
      -l | --linker*)
        if ! has_argument $@; then
          echo "ERROR: Linker not specified." >&2
          usage
          exit 1
        fi

        LINKER=$(extract_argument $@)

        shift
        ;;
      -z | --input_zip*)

        INPUT_ZIP=$(extract_argument $@)

        shift
        ;;
      -i | --input_dir*)

        INPUT_DIR=$(extract_argument $@)

        shift
        ;;
      -o | --output_dir*)
        if ! has_argument $@; then
          echo "WARNING: Output directory flag given, but not specified." >&2
          echo "WARNING: Setting output directory to current working directory." >&2
          OUTPUT_DIR=""
        else
          OUTPUT_DIR=$(extract_argument $@)
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

echo_verbose "INFO: Verbose mode turned on"
echo_verbose ""

# QC checks of input parameters
if [[ ${#LINKER} == 0 ]]; then
  echo "ERROR: Linker not supplied. Must specify linker"
  usage
  exit 1
fi

if [[ (${#INPUT_ZIP} == 0) && (${#INPUT_DIR} == 0) ]]; then
  echo "ERROR: INPUT not supplied. Must specify INPUT_ZIP file or INPUT_DIR directory"
  usage
  exit 1
fi

# Setting INPUT and COMPRESSED_INPUT based on whether INPUT_ZIP or INPUT_DIR was supplied
if [[ ${#INPUT_ZIP} == 0 ]]; then
  echo_verbose "INFO: INPUT_ZIP not found, setting INPUT to INPUT_DIR"
  INPUT=$INPUT_DIR
  COMPRESSED_INPUT=false
elif [[ (${#INPUT_ZIP} > 0) && (${#INPUT_DIR} > 0) ]]; then
  echo "WARNING: Got both INPUT_ZIP and INPUT_DIR"
  echo "WARNING: Defaulting to using INPUT_ZIP"
  INPUT=$INPUT_ZIP
  COMPRESSED_INPUT=true
else
  INPUT=$INPUT_ZIP
  COMPRESSED_INPUT=true
fi

# Verifying input type as either directory or ZIP file type
if [[ (-d ${INPUT}) && (${COMPRESSED_INPUT} == 'false') ]]; then
  # Confirming that input is a directory type
  echo_verbose "INFO: Found INPUT type 'directory'."
  INPUT_NAME=$INPUT
  echo_verbose "INFO: INPUT directory '${INPUT_NAME}'"
elif [[ (-f ${INPUT}) && (${COMPRESSED_INPUT} == 'true')]]; then
  # Extracting basename from ZIP file name for validation
  echo_verbose "INFO: Found INPUT type 'file'"
  INPUT_BASENAME=$(basename -- "$INPUT")
  INPUT_NAME="${INPUT_BASENAME%.*}"
  INPUT_EXTENSION="${INPUT_BASENAME##*.}"
  echo_verbose "INFO: INPUT name extracted '${INPUT_NAME}'"
  echo_verbose "INFO: INPUT extension extracted '${INPUT_EXTENSION}'"

  # Confirming that input is a ZIP file type
  if [[ $INPUT_EXTENSION == "zip" ]]; then
    echo_verbose "INFO: Confirmed ZIP file found as input."
  fi
else
  echo_verbose "ERROR: INPUT argument mismatch or file/directory not found."
  echo_verbose "ERROR: Confirm that argument is supplied with correct type and that file/directory exists."
  usage
  exit 1
fi

echo_verbose ""

if [[ ( ! -f ${INPUT} ) && ( ! -d ${INPUT} )]]; then
  echo "ERROR: INPUT not found.  Please ensure path is correct and/or ZIP file/directory exists"
  echo "INFO: Given INPUT '${INPUT}'"
  exit 1
fi

# Defining regex matches for each part of linker
LINKER_ARRAY[0]="RMIP" # RMIP identifier
LINKER_ARRAY[1]="[[:digit:]]{3}" # Project ID
LINKER_ARRAY[2]="^[[:alnum:]]+$" # Participant ID (alphanumeric, no length restrictions)
LINKER_ARRAY[3]="[[:alpha:]]" # Discriminator
LINKER_ARRAY[4]="[[:digit:]]{3}" # Identifier
LINKER_ARRAY[5]="[[:alpha:]]" # Vial identifier

# Defining length restrictions for each part of linker
LINKER_PIECE_LENGTH_ARRAY[0]=4 # RMIP identifier
LINKER_PIECE_LENGTH_ARRAY[1]=3 # Project ID
LINKER_PIECE_LENGTH_ARRAY[2]=0 # Participant ID (alphanumeric, no length restrictions)
LINKER_PIECE_LENGTH_ARRAY[3]=1 # Discriminator
LINKER_PIECE_LENGTH_ARRAY[4]=3 # Identifier
LINKER_PIECE_LENGTH_ARRAY[5]=1 # Vial identifier


# Creating, splitting, and validating input linker

if [ "$PILOT_MODE" == true ]; then
  echo "INFO: PILOT_MODE activated, skipping linker check"
else
  IFS="_" read -ra LINKER_SPLIT <<< "$LINKER"

  echo_verbose "Checking validity of linker format..."

  j=0
  for i in "${LINKER_SPLIT[@]}"; do
      echo_verbose "INFO: Linker part $j: $i"
      echo_verbose "INFO: Linker regexp: ${LINKER_ARRAY[$j]}"
      if [[ "$i" =~ ${LINKER_ARRAY[$j]} && (${#i} == ${LINKER_PIECE_LENGTH_ARRAY[$j]} || ${LINKER_PIECE_LENGTH_ARRAY[$j]} == 0) ]]; then
          echo_verbose "INFO: Regexp match!"
      else
          echo_verbose "ERROR: Regexp not match"
          echo_verbose ""
          echo "ERROR: Invalid linker format, exiting"
          usage
          exit 1
      fi
      ((j+=1))
      echo_verbose ""
  done

  if [[ $j -gt ${#LINKER_ARRAY[@]} || $j -lt 5 ]]; then
      echo "ERROR: Input linker not long enough, got length $j"
      echo "ERROR: Expected linker length 5 or 6"
      usage
      exit 1
  fi
fi

# If there is no OUTPUT_DIR supplied, then set to directory named by linker and input within current working directory
if [[ ${#OUTPUT_DIR} == 0 ]]; then
  echo_verbose "WARNING: OUTPUT_DIR not specified!"
  OUTPUT_DIR="./${LINKER}_outs"
fi

echo_verbose "INFO: Writing files to ${OUTPUT_DIR}"

if [[ ! -d ${OUTPUT_DIR} ]]; then
  echo_verbose "WARNING: Output directory '$OUTPUT_DIR' not found, creating..."
  mkdir -p $OUTPUT_DIR
fi

echo_verbose ""

FILE_LIST=($INPUT_NAME/web_summary.html $INPUT_NAME/metrics_summary.csv $INPUT_NAME/raw_feature_bc_matrix.h5 $INPUT_NAME/possorted_genome_bam.bam $INPUT_NAME/possorted_genome_bam.bam.bai $INPUT_NAME/filtered_feature_bc_matrix.h5)
# unzip outs folder if in compressed mode.
if [[ ${COMPRESSED_INPUT} == true ]]; then
     echo_verbose "INFO: Extracting all files from '${INPUT}'"
     bsdtar --strip-components=1 -xvf $INPUT -C ${OUTPUT_DIR}
fi
if [[ ${COMPRESSED_INPUT} == false ]]; then
     echo_verbose "INFO: Extracting all files from '${INPUT}'"
     cp -r $INPUT/* ${OUTPUT_DIR}
fi

#rename all files with linker prefix
prefix="${LINKER}"  # Replace with the desired prefix

find ${OUTPUT_DIR} -type f -print0 | while IFS= read -r -d $'\0' file; do
  dir_path=$(dirname "$file")
  file_name=$(basename "$file")

  echo_verbose "Checking for linker prefix of '$file_name'"

  PREFIX_STRING=${file_name::20}
  IFS="_" read -ra LINKER_SPLIT <<< "$PREFIX_STRING"

  echo_verbose "INFO: Checking ${PREFIX_STRING} for linker match"
  j=0
  REGEX_MATCH=true
  for i in "${LINKER_SPLIT[@]}"; do
      echo_verbose "INFO: part $j: $i"
      echo_verbose "INFO: regexp to match: ${LINKER_ARRAY[$j]}"
      if [[ "$i" =~ ${LINKER_ARRAY[$j]} && (${#i} == ${LINKER_PIECE_LENGTH_ARRAY[$j]} || ${LINKER_PIECE_LENGTH_ARRAY[$j]} == 0) ]]; then
          echo_verbose "INFO: Regexp match found"
      else
          echo_verbose "INFO: Regexp not matched"
          REGEX_MATCH=false
      fi
      ((j+=1))
      echo_verbose ""
  done

  if [[ ${REGEX_MATCH} == true ]]; then
    echo "ERROR: Linker found in prefix of '${file}'"
    echo "ERROR: Please remove linker prefixes from in front of files and rerun."
    exit 1
  fi

  mv "$file" "$dir_path/${prefix}_${file_name}"
  echo_verbose "Renamed file '$file' to '${prefix}_${file_name}'"
done

#compress all files but file list if in compressed mode.
[[ (${COMPRESSED_OUTPUT_MODE} == true) ]] && zip -r ${OUTPUT_DIR}/${LINKER}_outs.zip ${OUTPUT_DIR} -x "${FILE_LIST[@]}"

echo_verbose "INFO: Reached end of script"
