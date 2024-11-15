#!/bin/bash

# Function to display script usage
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help         Display this help message"
 echo " -v, --verbose      Enable verbose mode"
 echo " -l, --linker       STRING Specify name of linker to prepend to extracted files (format 'RMIP_<ddd>_<alphanum>_<w>_<ddd>_<w>') - Required"
 echo "                       e.g. linker='RMIP_001_allo1_A_001_A'"
 echo "                       Note that the Vial Identifier (last letter) is optional"
 echo " -i, --input        STRING/PATH Specify name and path of either ZIP file to read OR input directory - Required"
 echo " -o, --output_dir   STRING/PATH Specify directory where to put extracted files.  Default = '.'"
 echo ""
 echo "Example usage"
 echo " Required flags (ZIP input):               ./rename_files.sh -i outs.zip -l RMIP_001_allo1_A_001_A"
 echo " Required flags (DIRECTORY input):         ./rename_files.sh -i outs -l RMIP_001_allo1_A_001_B"
 echo " Writing to output directory:              ./rename_files.sh -i outs.zip -l RMIP_001_allo1_A_001_C -o outs"
 echo " Verbose mode:                             ./rename_files.sh -v -i outs.zip -l RMIP_001_allo1_A_001_D"
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
      -l | --linker*)
        if ! has_argument $@; then
          echo "ERROR: Linker not specified." >&2
          usage
          exit 1
        fi

        LINKER=$(extract_argument $@)

        shift
        ;;
      -i | --input*)
        if ! has_argument $@; then
          echo "ERROR: Input not specified." >&2
          usage
          exit 1
        fi

        INPUT=$(extract_argument $@)

        shift
        ;;
      -o | --output_dir*)
        if ! has_argument $@; then
          echo "Warning: Output directory flag given, but not specified." >&2
          echo "Setting to current working directory." >&2
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

echo_verbose "Verbose mode turned on"
echo_verbose ""

# QC checks of input parameters
if [[ ${#LINKER} == 0 ]]; then
  echo "ERROR: Linker not supplied. Must specify linker"
  usage
  exit 1
fi

if [[ ${#INPUT} == 0 ]]; then
  echo "ERROR: INPUT not supplied. Must specify INPUT ZIP file or directory"
  usage
  exit 1
fi

if [[ ( ! -f ${INPUT} ) && ( ! -d ${INPUT} )]]; then
  echo "ERROR: INPUT not found.  Please ensure path is correct and/or ZIP file/directory exists"
  echo "Given INPUT: $INPUT"
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
IFS="_" read -ra LINKER_SPLIT <<< "$LINKER"

echo_verbose "Checking validity of linker format..."

j=0
for i in "${LINKER_SPLIT[@]}"; do
    echo_verbose "Linker part $j: $i"
    echo_verbose "Linker regexp: ${LINKER_ARRAY[$j]}"
    if [[ "$i" =~ ${LINKER_ARRAY[$j]} && (${#i} == ${LINKER_PIECE_LENGTH_ARRAY[$j]} || ${LINKER_PIECE_LENGTH_ARRAY[$j]} == 0) ]]; then
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

if [[ $j -gt ${#LINKER_ARRAY[@]} || $j -lt 5 ]]; then
    echo "ERROR: Input linker not long enough, got length $j"
    echo "Expected length 5 or 6"
    usage
    exit 1
fi

# Testing if INPUT is 'file' or 'directory' type
if [[ -f ${INPUT} ]]; then
  # Extracting basename from ZIP file name
  echo_verbose "Found INPUT type 'file'"
  INPUT_BASENAME=$(basename -- "$INPUT")
  INPUT_NAME="${INPUT_BASENAME%.*}"
  INPUT_EXTENSION="${INPUT_BASENAME##*.}"
  echo_verbose "INPUT name extracted: $INPUT_NAME"
  echo_verbose "INPUT extension extracted: $INPUT_EXTENSION"

  if [[ $INPUT_EXTENSION == "zip" ]]; then
    echo_verbose "ZIP file found.  Setting COMPRESSED_INPUT to 'true'"
    COMPRESSED_INPUT=true
  fi
elif [[ -d ${INPUT} ]]; then
  echo_verbose "Found INPUT type 'directory'.  Setting COMPRESSED_INPUT to 'false'"
  COMPRESSED_INPUT=false
  INPUT_NAME=$INPUT
  echo_verbose "INPUT directory: $INPUT_NAME"
else
  echo_verbose "Unknown error with INPUT type.  Please ensure it is file or directory"
  exit 1
fi

# If there is no OUTPUT_DIR supplied, then set to current working directory
if [[ ${#OUTPUT_DIR} == 0 ]]; then
  echo_verbose "WARNING: OUTPUT_DIR not specified!"
  OUTPUT_DIR="./${LINKER}_${INPUT_NAME}"
fi

echo_verbose "Writing files to ${OUTPUT_DIR}"

if [[ ! -d ${OUTPUT_DIR} ]]; then
  echo_verbose "Output directory '$OUTPUT_DIR' not found, creating..."
  mkdir -p $OUTPUT_DIR
fi

echo_verbose ""

FILE_LIST=($INPUT_NAME/web_summary.html $INPUT_NAME/metrics_summary.csv $INPUT_NAME/raw_feature_bc_matrix.h5 $INPUT_NAME/possorted_genome_bam.bam $INPUT_NAME/possorted_genome_bam.bam.bai $INPUT_NAME/filtered_feature_bc_matrix.h5)
# FILE_LIST=(web_summary.html metrics_summary.csv raw_feature_bc_matrix.h5 possorted_genome_bam.bam possorted_genome_bam.bam.bai filtered_feature_bc_matrix.h5)
# FILE_LIST=(web_summary.html metrics_summary.csv raw_feature_bc_matrix.h5 possorted_genome_bam.bam possorted_genome_bam.bam.bai raw_feature_bc_matrix/matrix.mtx.gz raw_feature_bc_matrix/features.tsv.gz raw_feature_bc_matrix/barcodes.tsv.gz filtered_feature_bc_matrix/matrix.mtx.gz filtered_feature_bc_matrix/barcodes.tsv.gz filtered_feature_bc_matrix/features.tsv.gz)

# Extracting and renaming files
for FILE in ${FILE_LIST[@]}; do
  echo_verbose $FILE;

  if [[ ${COMPRESSED_INPUT} == true ]]; then
    echo_verbose "Running in COMPRESSED mode"
    # Extracting basename from ZIP file name
    FILE_NAME=$(basename -- "$FILE")
    FILE_NAME="${FILE_NAME%.*}"
    FILE_NAME_EXTENSION="${FILE##*.}"
    echo_verbose "File name extracted: $FILE_NAME"
    echo_verbose "File name extension extracted: $FILE_NAME_EXTENSION"
    FILE_NAME_COMB=$FILE_NAME\.$FILE_NAME_EXTENSION

    unzip -l $INPUT | grep -q $FILE;
    if [[ "$?" == "0" ]]; then
      unzip -p $INPUT $FILE >$OUTPUT_DIR/$FILE_NAME_COMB;
      
      # Removing "_bam" from filename
      if [[ $FILE_NAME_COMB == *"_bam"* ]]; then
        echo_verbose "Found '_bam' in $FILE_NAME_COMB"
        NEW_FILE=${FILE_NAME_COMB//"_bam"/}
        echo_verbose "Removed '_bam': $NEW_FILE"
        echo_verbose "Moving '$OUTPUT_DIR/${FILE_NAME_COMB}' to '$OUTPUT_DIR/${LINKER}_${NEW_FILE}'";
        echo_verbose ""
        mv $OUTPUT_DIR/${FILE_NAME_COMB} $OUTPUT_DIR/${LINKER}_${NEW_FILE};
      else
        echo_verbose "Moving '$OUTPUT_DIR/${FILE_NAME_COMB}' to '$OUTPUT_DIR/${LINKER}_${FILE_NAME_COMB}'";
        echo_verbose ""
        mv $OUTPUT_DIR/${FILE_NAME_COMB} $OUTPUT_DIR/${LINKER}_${FILE_NAME_COMB};
      fi
    else
      echo "File $FILE not found in ZIP file. Skipping"
    fi
  elif [[ ${COMPRESSED_INPUT} == false ]]; then
    echo_verbose "Running in UNCOMPRESSED mode"

    FILE=${FILE#${INPUT_NAME}/}

    if [[ $FILE == *"_bam"* ]]; then
      echo_verbose "Found '_bam' in $FILE"
      NEW_FILE=${FILE//"_bam"/}
      echo_verbose "Removed '_bam': $NEW_FILE"
      echo_verbose ""
      cp ${INPUT_NAME}/${FILE} "${OUTPUT_DIR}/${LINKER}_${NEW_FILE}"
      echo_verbose "Copying '${FILE}' to '${OUTPUT_DIR}/${LINKER}_${NEW_FILE}'"
      echo_verbose ""
    else
      echo_verbose "Copying '${FILE}' to '${OUTPUT_DIR}/${LINKER}_${FILE}'"
      echo_verbose ""
      cp ${INPUT_NAME}/${FILE} "${OUTPUT_DIR}/${LINKER}_${FILE}"
    fi
  fi
done

[[ ${COMPRESSED_INPUT} == true ]] && echo_verbose "Copying ZIP file to output directory: $INPUT -> ${OUTPUT_DIR}/${LINKER}_${INPUT}"
[[ ${COMPRESSED_INPUT} == true ]] && cp $INPUT ${OUTPUT_DIR}/${LINKER}_${INPUT_NAME}.zip

echo_verbose "Reached end of script"
