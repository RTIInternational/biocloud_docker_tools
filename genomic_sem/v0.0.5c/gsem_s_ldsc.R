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
      "Comma-separated list of input munged summary statistics",
      "files (required)"
    )
  ),
  make_option(
    "--trait_names",
    type = "character",
    help = "Comma-separated list of trait names (required)"
  ),
  make_option(
    "--sample_prevs",
    type = "character",
    help = "Comma-separated list of sample prevalences (required)"
  ),
  make_option(
    "--population_prevs",
    type = "character",
    help = "Comma-separated list of population prevalences (required)"
  ),
  make_option(
    "--ld_dir",
    type = "character",
    help = "Directory containing partitioned LD scores (required)"
  ),
  make_option(
    "--wld_dir",
    type = "character",
    help = paste(
      "Directory containing non-partitioned LD scores used as",
      "weights (required)"
    )
  ),
  make_option(
    "--frq_dir",
    type = "character",
    help = paste(
      "Directory containing allele frequency files used to restrict",
      "to MAF > 5% (required)"
    )
  ),
  make_option(
    "--output_prefix",
    type = "character",
    help = "Output prefix for LDSC results (required)"
  ),
  make_option(
    "--n_blocks",
    type = "integer",
    default = 200,
    help = paste(
      "Number of blocks used for the jackknife resampling procedure used",
      "to obtain standard errors (optional)"
    )
  ),
  make_option(
    "--ldsc_log",
    type = "character",
    help = "Name the .log file (optional)"
  ),
  make_option(
    "--include_cont",
    action = "store_true",
    default = FALSE,
    help = paste(
      "Flag indicating to include continuous annotations when",
      "estimating S-LDSC (optional)"
    )
  )
)

## Parse command-line arguments
parser <- optparse::OptionParser(option_list = option_list)
opt <- optparse::parse_args(parser)

## Check for required parameters
required_parameters <- c(
  "sumstats_files",
  "trait_names",
  "sample_prevs",
  "population_prevs",
  "ld_dir",
  "wld_dir",
  "frq_dir",
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
sample_prevs <- as.numeric(unlist(split_csv(opt$sample_prevs)))
population_prevs <- as.numeric(unlist(split_csv(opt$population_prevs)))

## Create output directory if it doesn't exist
output_dir <- dirname(opt$output_prefix)
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

## Set working directory to output directory
setwd(output_dir)

## Run stratified LDSC
cat("Running stratified LDSC...\n")
ldsc_output <- s_ldsc(
  traits = sumstats_files,
  sample.prev = sample_prevs,
  population.prev = population_prevs,
  ld = opt$ld_dir,
  wld = opt$wld_dir,
  frq = opt$frq_dir,
  trait.names = trait_names,
  n.blocks = opt$n_blocks,
  ldsc.log = paste0(opt$output_prefix, ".log"),
  exclude_cont = !opt$include_cont
)

## Save LDSC output to RDS file
rds_file <- paste0(opt$output_prefix, ".rds")
cat("Saving stratified LDSC output to RDS file:", rds_file, "\n")
saveRDS(
  ldsc_output,
  file = rds_file
)
