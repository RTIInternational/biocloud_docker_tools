require(GenomicSEM) # nolint: object_usage_linter.
library(optparse)

split_csv <- function(x) {
  trimws(strsplit(x, ",")[[1]])
}

option_list <- list(
  make_option(
    "--sumstats_files",
    type = "character",
    help = paste(
      "Comma-separated list of input GWAS summary statistic",
      "files (required)"
    )
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
    "--ref_snp_list",
    type = "character",
    help = "File path for reference SNP list (required)"
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
    help = "Flag indicating to perform parallel computing (optional)"
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
    help = paste(
      "Flag indicating to prevent overwriting",
      "existing files (optional)"
    )
  )
)

## Parse command-line arguments
parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)

## Check for required parameters
required_parameters <- c(
  "sumstats_files",
  "trait_names",
  "sample_sizes",
  "ref_snp_list",
  "out_dir"
)
for (param in required_parameters) {
  if (is.null(opt[[param]])) {
    stop(paste("Missing required parameter:", param))
  }
}

## Output the parsed arguments for verification
cat("Arguments:\n")
str(opt)

## Process arguments
out_dir <- ifelse(endsWith(opt$out_dir, "/"), opt$out_dir, paste0(opt$out_dir, "/")) # nolint: line_length_linter.
sumstats_files <- split_csv(opt$sumstats_files)
trait_names <- split_csv(opt$trait_names)
sample_sizes <- as.numeric(unlist(split_csv(opt$sample_sizes)))

## Create output directory if it doesn't exist
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

## Set working directory to output directory
setwd(out_dir)

## Munge the Summary Statistic files
cat("Munging Summary Statistics...\n")
munge(
  files = sumstats_files,
  hm3 = opt$ref_snp_list,
  trait.names = trait_names,
  N = sample_sizes,
  info.filter = opt$info_filter,
  maf.filter = opt$maf_filter,
  parallel = opt$parallel,
  cores = opt$cores,
  overwrite = !opt$no_overwrite
)
