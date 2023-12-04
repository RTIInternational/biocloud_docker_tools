# Load required libraries
library(MungeSumstats)
library(argparse)

# Create an argument parser
parser <- ArgumentParser(description = "Convert summary statistics to a different reference genome")

# Define command-line arguments
parser$add_argument("--file_name", help = "Input file name")
parser$add_argument("--output_name", help = "Output file name")
parser$add_argument("--sep", help = "Field separator: 'Tab', 'Comma', or 'Space'.")
parser$add_argument("--snp_name", help = "Name of SNP column")
parser$add_argument("--chrom_name", help = "Name of chromosome column")
parser$add_argument("--pos_name", help = "Name of position column")
parser$add_argument("--ref_genome", help = "Reference genome (e.g., GRCh37 or GRCh38)")
parser$add_argument("--convert_ref_genome", help = "Target reference genome (e.g., GRCh37 or GRCh38)")
parser$add_argument("--chain_source", help = "Source for chain files (ensembl or ucsc)")

# Parse the command-line arguments
args <- parser$parse_args()

# Convert the user-friendly input to the actual separator
if (tolower(args$sep) == "tab") {
    separator <- "\t"
} else if (tolower(args$sep) == "comma") {
    separator <- ","
} else if (tolower(args$sep) == "space") {
    separator <- " "
} else {
    cat("Unsupported field separator. Please specify Tab, Comma, or Space.")
    separator <- ""  # Use a default separator or exit the script.
}

# Read the input data
sumstats_dt <- read.table(args$file_name, sep = separator, header = TRUE)

# Rename columns to standard/expected format
colnames(sumstats_dt)[colnames(sumstats_dt) %in% c(args$snp_name, args$chrom_name, args$pos_name)] <- c("SNP", "CHR", "BP")

# Perform liftover
sumstats_dt_liftover <- liftover(sumstats_dt = sumstats_dt,
                                 ref_genome = args$ref_genome,
                                 convert_ref_genome = args$convert_ref_genome,
                                 imputation_ind = FALSE)

# Write the output data
write.table(sumstats_dt_liftover, args$output_name, sep = separator, quote = FALSE, row.names = FALSE)
