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
    "--model_lavaan",
    type = "character",
    help = "Lavaan model file for the common factor model (required)"
  ),
  make_option(
    "--estimation_method",
    type = "character",
    help = "Estimation method for the user model (required)"
  ),
  make_option(
    "--output_prefix",
    type = "character",
    help = "Output prefix for usermodel results (required)"
  ),
  make_option(
    "--cficalc",
    action = "store_true",
    default = FALSE,
    help = "Flag indicating to calculate CFI for the user model (optional)"
  ),
  make_option(
    "--std_lv",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating to standardize latent variables using unit variance",
      "identification in the user model (optional)"
    )
  ),
  make_option(
    "--imp_cov",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating to imply model and include residual covariance matrix",
      "in the user model output (optional)"
    )
  ),
  make_option(
    "--fix_resid",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating to troubleshoot a model that does not converge by",
      "fixing residual variances to be above 0 (optional)"
    )
  ),
  make_option(
    "--toler",
    type = "float",
    default = FALSE,
    help = paste(
      "Tolerance for matrix inversion used to produce",
      "sandwich corrected standard errors (optional)"
    )
  ),
  make_option(
    "--q_factor",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating to obtain a heterogeneity statistic",
      "for factor correlations (optional)"
    )
  )
)

## Parse command-line arguments
parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)

## Check for required parameters
required_parameters <- c(
  "ldsc_rds",
  "model_lavaan",
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

## Read model from file
user_model <- paste(readLines(opt$model_lavaan), collapse = "\n")

## Read LDSC output from RDS file
ldsc_output <- readRDS(opt$ldsc_rds)

## Run usermodel
cat("Running usermodel...\n")
user_common_factor <- usermodel(
  covstruc = ldsc_output,
  model = user_model,
  estimation = opt$estimation_method,
  CFIcalc = opt$cficalc,
  std.lv = opt$std_lv,
  imp_cov = opt$imp_cov,
  fix_resid = opt$fix_resid,
  toler = opt$toler,
  Q_Factor = opt$q_factor
)

## Save usermodel output to RDS file
rds_file <- paste0(opt$output_prefix, ".rds")
cat("Saving usermodel output to RDS file:", rds_file, "\n")
saveRDS(
  user_common_factor,
  file = rds_file
)