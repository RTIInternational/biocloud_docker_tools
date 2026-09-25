library(optparse)

option_list <- list(
  make_option(
    "--rds_files",
    type = "character",
    default = NULL,
    help = paste(
      "Comma-separated RDS files, each containing a list of data frames",
      "(optional if --rds_file_list is provided)"
    )
  ),
  make_option(
    "--rds_file_list",
    type = "character",
    default = NULL,
    help = paste(
      "Text file containing one RDS path per line",
      "(optional if --rds_files is provided)"
    )
  ),
  make_option(
    "--output_prefix",
    type = "character",
    help = "Output prefix for SNP results (required)"
  )
)

parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)

required_parameters <- c("output_prefix")
for (param in required_parameters) {
  if (is.null(opt[[param]])) {
    stop(paste("Missing required parameter:", param))
  }
}

if (!is.null(opt$rds_files)) {
  rds_files <- trimws(strsplit(opt$rds_files, ",", fixed = TRUE)[[1]])
  rds_files <- rds_files[nzchar(rds_files)]
} else {
  rds_files <- character(0)
}

if (!is.null(opt$rds_file_list)) {
  if (!file.exists(opt$rds_file_list)) {
    stop("RDS file list does not exist: ", opt$rds_file_list)
  }
  listed_files <- trimws(readLines(opt$rds_file_list, warn = FALSE))
  listed_files <- listed_files[nzchar(listed_files)]
  rds_files <- c(rds_files, listed_files)
}

if (length(rds_files) == 0) {
  stop("Provide at least one RDS path using --rds_files or --rds_file_list.")
}

missing_files <- rds_files[!file.exists(rds_files)]
if (length(missing_files) > 0) {
  stop(
    "The following RDS file(s) do not exist: ",
    paste(missing_files, collapse = ", ")
  )
}

input_lists <- lapply(rds_files, function(rds_file) {
  object <- readRDS(rds_file)
  if (!is.list(object)) {
    stop("RDS file does not contain a list: ", rds_file)
  }
  if (!all(vapply(object, is.data.frame, logical(1)))) {
    stop("RDS list contains a non-data-frame element: ", rds_file)
  }
  object
})

merged_results <- unname(do.call(c, input_lists))
if (length(merged_results) == 0) {
  stop("The input RDS files contain no data frames.")
}

output_dir <- dirname(opt$output_prefix)
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

output_rds <- paste0(opt$output_prefix, ".rds")
saveRDS(merged_results, output_rds)

cat(
  "Merged ", length(rds_files), " RDS file(s) containing ",
  length(merged_results), " data frame(s) into ", output_rds, "\n",
  sep = ""
)
