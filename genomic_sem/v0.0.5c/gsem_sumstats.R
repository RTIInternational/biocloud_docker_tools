require(GenomicSEM) # nolint: object_usage_linter.
library(optparse)

split_csv <- function(x) {
  trimws(strsplit(x, ",")[[1]])
}

option_list <- list(
  make_option(
    "--sumstats_files",
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
    "--se_logit",
    type = "character",
    help = paste(
      "Comma-separated list of whether SEs are on the",
      "logit scale for each trait (required)"
    )
  ),
  make_option(
    "--ref_snp_list",
    type = "character",
    help = "File path for HM3 reference SNP list (required)"
  ),
  make_option(
    "--output_prefix",
    type = "character",
    help = "Output prefix for munged summary statistics (required)"
  ),
  make_option(
    "--ols",
    type = "character",
    default = NULL,
    help = paste(
      "Comma-separated list of whether each trait was a continuous",
      "outcome analyzed using an observed least square (optional)"
    )
  ),
  make_option(
    "--linprob",
    type = "character",
    default = NULL,
    help = paste(
      "Comma-separated list of whether each trait was a dichotomous",
      "outcome for which there are only Z-statistics in the",
      "summary statistics file -or- it was a dichotomous outcome",
      "analyzed using an OLS estimator, as is the case for certain",
      "UKB phenotypes analyzed using the Hail software (optional)"
    )
  ),
  make_option(
    "--betas",
    type = "character",
    default = NULL,
    help = paste(
      "Comma-separated list of beta column names in GWAS summary",
      "statistics for continuous traits when the GWAS was run on an",
      "already standardized phenotype (optional)"
    )
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
    "--keep_indel",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating to keep indels in summary",
      "statistics (optional)"
    )
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
  "se_logit",
  "ref_snp_list",
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

## Process arguments
sumstats_files <- split_csv(opt$sumstats_files)
trait_names <- split_csv(opt$trait_names)
sample_sizes <- as.numeric(unlist(split_csv(opt$sample_sizes)))
se_logit <- as.logical(unlist(split_csv(opt$se_logit)))
ols <- if (!is.null(opt$ols)) {
  as.logical(unlist(split_csv(opt$ols)))
} else {
  NULL
}
linprob <- if (!is.null(opt$linprob)) {
  as.logical(unlist(split_csv(opt$linprob)))
} else {
  NULL
}
betas <- if (!is.null(opt$betas)) {
  unlist(split_csv(opt$betas))
} else {
  NULL
}

## Create output directory if it doesn't exist
out_dir <- dirname(opt$output_prefix)
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

## Set working directory to output directory
setwd(out_dir)

## Prepare summary statistics using the sumstats function
cat("Preparing Summary Statistics for SEM...\n")
sumstats <- sumstats(
  files = sumstats_files,
  ref = opt$ref_snp_list,
  trait.names = trait_names,
  se.logit = se_logit,
  N = sample_sizes,
  OLS = ols,
  linprob = linprob,
  betas = betas,
  info.filter = opt$info_filter,
  maf.filter = opt$maf_filter,
  keep.indel = opt$keep_indel,
  parallel = opt$parallel,
  cores = opt$cores
)

## Save sumstats output to RDS file
rds_file <- paste0(opt$output_prefix, ".rds")
cat("Saving sumstats output to RDS file:", rds_file, "\n")
saveRDS(
  sumstats,
  file = rds_file
)
