#!/usr/bin/env bash

# Die immediately on error
set -e

#####################################
# Check command line input
#####################################
show_usage () {

    # Print error message if one provided
    if [ -n "$1" ]; then
        echo "$1"
    fi

    echo
    echo "Tool preprocessing gene-by-gene (gxg) meta-analysis output for use with MetaXcan"
    echo "usage: prepare_metaxcan_input.sh <gxg_variant_file> <gtex_variant_file> <legend_file> <chr> <output_base>"
    echo "Arguments:"
    echo $'\t' "gxg_variant_file:   Path to gene-by-gene meta-analysis output"
    echo $'\t' "gtex_variant_file:  Path to GTeX varaint file"
    echo $'\t' "legend_file:        Path to legend file for converting to 1000g ids"
    echo $'\t' "chr:                target chromosome of gxg, legend files (must be the same)"
    echo $'\t' "output_base:        basename to use for creating final output file to be used with metaxcan"
    echo $'\t' "output_dir:         output directory where files will be written"
    echo

    # Exit with error status
    exit 1
}

# Check to see if someone wants to see the help menus
if [ "$1" == "-h" ]; then
    show_usage
elif [ "$1" == "--help" ]; then
    show_usage
# Check number of arguments
elif [ $# -ne 6 ]; then
    show_usage "Incorrect number of arguments!"
fi

#####################################
# INPUTS
#####################################
###### Directories
WRK_DIR=$6

###### Executables
convert_to_1000g="/opt/code_docker_lib/convert_to_1000g_ids.pl"
extract_by_id="/opt/code_docker_lib/extract_by_id.pl"
merge_gxg_gtex_by_id="/opt/code_docker_lib/merge_gxg_gtex_variants.R"

###### Parse args from command line input
# GWAS meta-analysis output file to be used as input for MetaXcan
gxg_meta_variant_file=$1

# GTeX variant file with dbSNP ids
gtex_variant_file=$2

# 1000g legend file for converting variant ids to 1000g ids
legend_file_1000g=$3

# Chromosome
chr=$4

# Output file basename
output_base=$5

#####################################
# Check input files exist
#####################################
echo_error(){
    # Echo error message to terminal and exit with status
    # $1: Error message, $2: Exit code
    echo "prepare_metaxcan_input error: $1"
    exit $2
}

# Check that input files and R-script specific actually exist
test -f $gxg_meta_variant_file || echo_error "GXG metadata analysis file does not exist: $gxg_meta_variant_file" 1
test -f $gtex_variant_file || echo_error "gtex variant file does not exist: $gtex_variant_file" 1
test -f $legend_file_1000g || echo_error "legend file does not exist: $legend_file_1000g" 1

#####################################
# DECLARE OUTPUTS
#####################################
gtex_variant_chr_file="$WRK_DIR/gtex_var.chr.txt"
gtex_1000g_file="$WRK_DIR/gtex_1000g.chr.txt"
gtex_unique_variant_id_file="$WRK_DIR/gtex_unique_var_ids.txt"
gxg_1000g_file="$WRK_DIR/gxg_1000g.txt"
gxg_1000g_subset_file="$WRK_DIR/gxg_1000g.subset.txt"
gxg_1000g_subset_refactor_file="$WRK_DIR/gxg_1000g.subset.refactor.txt"
final_output_file="$WRK_DIR/$output_base.txt"
gzipped_final_output_file="$final_output_file.gz"

#####################################
# DECOMPRESS INPUT FILES
#####################################

log_info(){
    # Log pretty info message
    echo "[INFO]    $1"
}

# Unzip gxg file if necessary
if file --mime-type "$gxg_meta_variant_file" | grep -q gzip$; then
  log_info "$gxg_meta_variant_file is gzipped. Unzipping..."
  gxg_unzipped_file="$WRK_DIR/gxg_unzipped_variants.txt"
  gunzip -c $gxg_meta_variant_file > $gxg_unzipped_file
  gxg_meta_variant_file=$gxg_unzipped_file
  log_info "New GXG input file: $gxg_meta_variant_file"
fi

# Unzip GTeX file if necessary
if file --mime-type "$gtex_variant_file" | grep -q gzip$; then
  log_info "$gtex_variant_file is gzipped. Unzipping..."
  gtex_unzipped_file="$WRK_DIR/gtex_unzipped_variants.txt"
  gunzip -c $gtex_variant_file > $gtex_unzipped_file
  gtex_variant_file=$gtex_unzipped_file
  log_info "New GTeX input file: $gtex_variant_file"
fi


#####################################
# Reformat GTeX variant file
#####################################
    # 1. Subset gtex variant input to include only variants from the desired chromosome
    # 2. Convert chr-subsetted gtex variants to 1000g ids
    # 3. Get list of unique 1000g ids

# 1. Subset file to include only variants from chromosome of interest
log_info "Subsetting GTeX variants for chr: $chr"
grep "chromosome" $gtex_variant_file > $gtex_variant_chr_file
perl -lane 'if ($F[0] == '$chr') { print; }' $gtex_variant_file >> $gtex_variant_chr_file

# 2. Convert to 1000g id
log_info "Converting GTeX file to 1000g ids"
perl $convert_to_1000g --file_in $gtex_variant_chr_file \
    --file_out $gtex_1000g_file \
    --legend $legend_file_1000g \
    --file_in_header 1 \
	--file_in_id_col 7 \
	--file_in_chr_col 0 \
	--file_in_pos_col 1 \
	--file_in_a1_col 3 \
	--file_in_a2_col 4 \
	--chr $chr

# 3. Get unique variants
log_info "Getting unique 1000g ids from GTeX file..."
echo "variant_id" > $gtex_unique_variant_id_file
cat $gtex_1000g_file | grep -v chromosome | cut -d$'\t' -f 8 | sort | uniq >> $gtex_unique_variant_id_file

#####################################
# Reformat GXG Meta-analysis file
#####################################
    # 1. Convert GXG meta-analysis variants to 1000g ids
    # 2. Subset to include only variants that are contained in GTEX produced above
    # 3. Remove unnecessary columns and re-name columns for input into metaxcan
    # 4. Merge with GTex variants to annotate each GXG variant with it's dbSNP150 id for metaxcan

# 1. Convert to 1000g ids
log_info "Converting GXG meta-analysis variants to 1000g ids..."
perl $convert_to_1000g --file_in $gxg_meta_variant_file \
    --file_out $gxg_1000g_file\
    --legend $legend_file_1000g \
	--file_in_header 1 \
	--file_in_id_col 0 \
	--file_in_chr_col 1 \
	--file_in_pos_col 2 \
	--file_in_a1_col 3 \
	--file_in_a2_col 4 \
	--chr $chr

# 2. Extract rows that appear in gtex file
log_info "Subsetting GXG variants by ids that appear in GTeX..."
perl $extract_by_id --source $gxg_1000g_file \
    --id_list $gtex_unique_variant_id_file \
    --out $gxg_1000g_subset_file \
    --header 1 \
    --id_column 0

# 3. Subset columns and reformat column names
log_info "Re-factoring GXG file columns and column names"
cat $gxg_1000g_subset_file \
    | cut -d$'\t' -f 1,4,5,6,7,8 \
    | sed 's/Allele1/A1/g'  \
	| sed 's/Allele2/A2/g'  \
	| sed 's/Effect/BETA/g' \
	| sed 's/P.value/P/g' > $gxg_1000g_subset_refactor_file

# 4. Run r-script to produce final output file
log_info "Merging GXG, GTeX variants to produce final output..."
Rscript $merge_gxg_gtex_by_id $gxg_1000g_subset_refactor_file $gtex_1000g_file $final_output_file

# 5. Gzip
log_info "Gzipping final output..."
gzip $final_output_file
