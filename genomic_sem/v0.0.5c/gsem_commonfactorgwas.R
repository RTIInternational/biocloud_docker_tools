require(GenomicSEM) # nolint: object_usage_linter.
library(optparse)

split_csv <- function(x) {
  trimws(strsplit(x, ",")[[1]])
}

option_list <- list(
  make_option(
    "--ldsc_rds",
    type = "character",
    help = "RDS file containing LDSC output (required)"
  ),
  make_option(
    "--sumstats_rds",
    type = "character",
    help = "RDS file containing sumstats function output (required)"
  ),
  make_option(
    "--estimation_method",
    type = "character",
    default = "DWLS",
    help = "Estimation method for the user model (required)"
  ),
  make_option(
    "--output_prefix",
    type = "character",
    help = "Output prefix for usermodel results (required)"
  ),
  make_option(
    "--toler",
    type = "float",
    default = FALSE,
    help = "Tolerance level to use for matrix inversion (optional)"
  ),
  make_option(
    "--snpse",
    type = "float",
    default = FALSE,
    help = "Standard error for SNPs (optional)"
  ),
  make_option(
    "--gc",
    type = "character",
    default = "standard",
    help = paste("Genomic control method to apply (standard, conserv,",
      "none) (optional)"
    )
  ),
  make_option(
    "--mpi",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating to use multi-node processing",
      "(Rmpi must be installed) (optional)"
    )
  ),
  make_option(
    "--smooth_check",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating to save the largest Z-statistic difference between",
      "pre- and post-smoothed genetic covariance matrices.",
      "Recommended to set to TRUE to ensure that SNPs that",
      "require a high degree of smoothing (e.g., Z > 1.96) are",
      "removed from results (optional)"
    )
  ),
  make_option(
    "--twas",
    action = "store_true",
    default = FALSE,
    help = "Flag indicating to perform TWAS analysis (optional)"
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
  )
)

## Parse command-line arguments
parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)

## Check for required parameters
required_parameters <- c(
  "ldsc_rds",
  "sumstats_rds",
  "estimation_method",
  "output_prefix"
)
for (param in required_parameters) {
  if (is.null(opt[[param]])) {
    stop(paste("Missing required parameter:", param))
  }
}

## Check whether GC (genomic control) method is valid
valid_gcs <- c("standard", "conserv", "none")
if (!opt$gc %in% valid_gcs) {
  stop(paste(
    "Invalid value for --gc. Must be one of:",
    paste(valid_gcs, collapse = ", ")
  ))
}

## Output the parsed arguments for verification
cat("Arguments:\n")
str(opt)

## Create output directory if it doesn't exist
output_dir <- dirname(opt$output_prefix)
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

## Set working directory to output directory
setwd(output_dir)

## Read LDSC output from RDS file
ldsc_output <- readRDS(opt$ldsc_rds)

## Read summary statistics from files
sumstats <- read.table(
  opt$sumstats_rds,
  header = TRUE,
  stringsAsFactors = FALSE
)

## Run common factor GWAS
cat("Running common factor GWAS...\n")
common_factor_gwas <- userGWAS(
  covstruc = ldsc_output,
  SNPs = sumstats,
  estimation = opt$estimation_method,
  toler = opt$toler,
  SNPSE = opt$snpse,
  GC = opt$gc,
  MPI = opt$mpi,
  smooth_check = opt$smooth_check,
  TWAS = opt$twas,
  parallel = opt$parallel,
  cores = opt$cores
)

## Save common factor GWAS output to RDS file
rds_file <- paste0(opt$output_prefix, ".rds")
cat("Saving common factor GWAS output to RDS file:", rds_file, "\n")
saveRDS(
  common_factor_gwas,
  file = rds_file
)