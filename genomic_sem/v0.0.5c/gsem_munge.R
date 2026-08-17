require(GenomicSEM) # nolint: object_usage_linter.
require(Matrix)
require(stats)
library(R.utils)
library(optparse)

option_list <- list(
  make_option(
    "--input_files",
    type = "character",
    help = "Comma-separated list of input files (required)"
  ),
  make_option(
    "--trait_names",
    type = "character",
    help = "Comma-separated list of trait names (required)"
  ),
  make_option(
    "--sample_sizes",
    type = "character",
    help = "Comma-separated list of sample sizes (required)"
  ),
  make_option(
    "--hm3_ref_snp_list",
    type = "character",
    help = "File path for HM3 reference SNP list (required)"
  ),
  make_option(
    "--out_dir",
    type = "character",
    help = "Output directory for munged summary statistics (required)"
  ),
  make_option(
    "--info_filter",
    type = "double",
    default = 0.9,
    help = "R^2 filter for summary statistics (optional)"
  ),
  make_option(
    "--maf_filter",
    type = "double",
    default = 0.01,
    help = "MAF filter for summary statistics (optional)"
  ),
  make_option(
    "--parallel",
    action = "store_true",
    default = FALSE,
    help = "Flag indicating whether to perform parallel computing (optional)"
  ),
  make_option(
    "--cores",
    type = "integer",
    default = 1,
    help = "Number of cores for parallel computing (optional)"
  ),
  make_option(
    "--no_overwrite",
    action = "store_true",
    default = FALSE,
    help = "Flag indicating whether to prevent overwriting existing files (optional)" # nolint: line_length_linter.
  )
)

parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)
required_parameters <- c(
  "input_files",
  "trait_names",
  "sample_sizes",
  "hm3_ref_snp_list",
  "out_dir"
)

cat("Arguments:\n")
str(opt)

split_csv <- function(x) {
  trimws(strsplit(x, ",")[[1]])
}

## Parse arguments
out_dir <- ifelse(endsWith(opt$out_dir, "/"), opt$out_dir, paste0(opt$out_dir, "/")) # nolint: line_length_linter.
input_files <- split_csv(opt$input_files)
trait_names <- split_csv(opt$trait_names)
sample_sizes <- split_csv(opt$sample_sizes)
traits <- as.vector(sapply(trait_names, function(x) paste0(x, ".sumstats.gz")))

## Create output directory if it doesn't exist
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

## Set working directory to output directory
setwd(out_dir)

## Munge the Summary Statistic files ##
cat("Munging Summary Statistics...\n")
munge(
  files = input_files,
  hm3 = opt$hm3_ref_snp_list,
  trait_names = trait_names,
  N = sample_sizes,
  info.filter = opt$info_filter,
  maf.filter = opt$maf_filter,
  parallel = opt$parallel,
  cores = opt$cores,
  overwrite = !opt$no_overwrite
)
