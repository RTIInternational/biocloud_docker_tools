require(GenomicSEM) # nolint: object_usage_linter.
library(optparse)

split_csv <- function(x) {
  trimws(strsplit(x, ",")[[1]])
}

option_list <- list(
  make_option(
    "--s_ldsc_rds",
    type = "character",
    help = "RDS file containing stratified LDSC output (required)"
  ),
  make_option(
    "--model_lavaan",
    type = "character",
    help = "Lavaan model file for the common factor model (required)"
  ),
  make_option(
    "--params",
    type = "character",
    help = paste(
      "The parameter(s) being estimated for enrichment, specified",
      "using lavaan syntax (required)"
    )
  ),
  make_option(
    "--output_prefix",
    type = "character",
    help = "Output prefix for usermodel results (required)"
  ),
  make_option(
    "--fix",
    type = "character",
    default = "regressions",
    help = paste(
      "Types of parameters you want to be fixed from the",
      "model estimated in the genome-wide annotation",
      "(choices: regressions, variances, covariances)",
      "(optional)"
    )
  ),
  make_option(
    "--std_lv",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating to use unit variance identification for any",
      "latent factors in the overall model (optional)"
    )
  ),
  make_option(
    "--not_rm_flank",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating not to automatically remove flanking window",
      "and continuous annotations from the output (optional)"
    )
  ),
  make_option(
    "--tau",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating whether to use the tau matrices instead of",
      "zero-order matrices for enrichment estimates (optional)"
    )
  ),
  make_option(
    "--not_base",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating not to include the full estimates from the",
      "baseline model in a separate list object included",
      "in the output (optional)"
    )
  ),
  make_option(
    "--toler",
    type = "float",
    default = NULL,
    help = paste(
      "Tolerance for matrix inversion (optional)"
    )
  ),
  make_option(
    "--fixparam",
    type = "character",
    default = NULL,
    help = paste(
      "The parameter(s) to fix when estimating the model within",
      "annotations (optional)"
    )
  )
)

## Parse command-line arguments
parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)

## Check for required parameters
required_parameters <- c(
  "s_ldsc_rds",
  "model_lavaan",
  "params",
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
ldsc_output <- readRDS(opt$s_ldsc_rds)

## Read model from file
user_model <- paste(readLines(opt$model_lavaan), collapse = "\n")

## Read params
params <- readLines(opt$params)

## Read fixed params
fixed_params <- if (!is.null(opt$fixparam)) readLines(opt$fixparam) else NULL

## Run enrich
cat("Running enrich...\n")
enrich <- enrich(
  covstruc = ldsc_output,
  model = user_model,
  params = params,
  fix = opt$fix,
  std.lv = opt$std_lv,
  rm.flank = !opt$not_rm_flank,
  tau = opt$tau,
  base = !opt$not_base,
  toler = opt$toler,
  fixparam = fixed_params
)

## Save enrich output to RDS file
rds_file <- paste0(opt$output_prefix, ".rds")
cat("Saving enrich output to RDS file:", rds_file, "\n")
saveRDS(
  enrich,
  file = rds_file
)