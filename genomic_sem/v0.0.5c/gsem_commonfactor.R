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
    "--estimation_method",
    type = "character",
    default = "DWLS",
    help = "Estimation method for the user model (required)"
  ),
  make_option(
    "--output_prefix",
    type = "character",
    help = "Output prefix for usermodel results (required)"
  )
)

## Parse command-line arguments
parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)

## Check for required parameters
required_parameters <- c(
  "ldsc_rds",
  "estimation_method",
  "output_prefix"
)
for (param in required_parameters) {
  if (is.null(opt[[param]])) {
    stop(paste("Missing required parameter:", param))
  }
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

## Run common factor model
cat("Running common factor model...\n")
common_factor <- commonfactor(
  covstruc = ldsc_output,
  estimation = opt$estimation_method
)

## Save common factor output to RDS file
rds_file <- paste0(opt$output_prefix, ".rds")
cat("Saving common factor output to RDS file:", rds_file, "\n")
saveRDS(
  common_factor,
  file = rds_file
)