require(GenomicSEM) # nolint: object_usage_linter.
library(optparse)

split_csv <- function(x) {
  trimws(strsplit(x, ",")[[1]])
}

option_list <- list(
  make_option(
    "--rds_files",
    type = "character",
    default = NULL,
    help = "Comma-separated list of RDS files to merge (required unless --rds_file_list is provided)"
  ),
  make_option(
    "--rds_file_list",
    type = "character",
    default = NULL,
    help = "Text file containing list of RDS file paths to merge, one per line (optional)"
  ),
  make_option(
    "--output_prefix",
    type = "character",
    default = NULL,
    help = "Output prefix for merged results (required unless --output_rds is provided)"
  ),
  make_option(
    "--output_rds",
    type = "character",
    default = NULL,
    help = "Explicit path for merged RDS output file (optional)"
  )
)

## Parse command-line arguments
parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)

## Collect input RDS files
rds_files <- character(0)
if (!is.null(opt$rds_files) && nzchar(trimws(opt$rds_files))) {
  rds_files <- c(rds_files, split_csv(opt$rds_files))
}
if (!is.null(opt$rds_file_list) && file.exists(opt$rds_file_list)) {
  lines <- readLines(opt$rds_file_list)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines)]
  rds_files <- c(rds_files, lines)
}

if (length(rds_files) == 0) {
  stop("Missing required parameter: --rds_files or --rds_file_list must be provided with at least one file.")
}

## Determine output paths
if (is.null(opt$output_prefix) && is.null(opt$output_rds)) {
  stop("Missing required parameter: either --output_prefix or --output_rds must be specified.")
}

if (!is.null(opt$output_rds)) {
  rds_file <- opt$output_rds
  output_dir <- dirname(rds_file)
  output_prefix <- sub("\\.rds$", "", rds_file)
} else {
  output_prefix <- opt$output_prefix
  output_dir <- dirname(output_prefix)
  rds_file <- paste0(output_prefix, ".rds")
}

## Check if files exist
for (f in rds_files) {
  if (!file.exists(f)) {
    stop(paste("Input RDS file does not exist:", f))
  }
}

## Create output directory if it doesn't exist
if (!dir.exists(output_dir) && nzchar(output_dir) && output_dir != ".") {
  dir.create(output_dir, recursive = TRUE)
}

## Output the parsed arguments for verification
cat("Arguments:\n")
str(opt)
cat("Merging", length(rds_files), "RDS files...\n")

## Function to recursively/flexibly merge RDS objects
merge_rds_objects <- function(obj_list) {
  if (length(obj_list) == 0) {
    stop("No objects to merge.")
  }
  if (length(obj_list) == 1) {
    return(obj_list[[1]])
  }

  first_obj <- obj_list[[1]]

  # Case 1: Data frame (or data.table / tibble)
  if (is.data.frame(first_obj)) {
    all_df <- all(vapply(obj_list, is.data.frame, logical(1)))
    if (!all_df) {
      stop("Inconsistent object types across RDS files: not all are data.frames.")
    }
    merged <- do.call(rbind, obj_list)
    rownames(merged) <- NULL
    return(merged)
  }

  # Case 2: Matrix
  if (is.matrix(first_obj)) {
    all_mat <- all(vapply(obj_list, is.matrix, logical(1)))
    if (!all_mat) {
      stop("Inconsistent object types across RDS files: not all are matrices.")
    }
    return(do.call(rbind, obj_list))
  }

  # Case 3: List of components (e.g. sub components or structured results)
  if (is.list(first_obj)) {
    all_list <- all(vapply(obj_list, is.list, logical(1)))
    if (!all_list) {
      stop("Inconsistent object types across RDS files: not all are lists.")
    }

    names_first <- names(first_obj)
    if (!is.null(names_first) && length(names_first) > 0) {
      merged_list <- list()
      for (nm in names_first) {
        sub_objs <- lapply(obj_list, function(x) x[[nm]])
        merged_list[[nm]] <- merge_rds_objects(sub_objs)
      }
      return(merged_list)
    } else {
      len_first <- length(first_obj)
      merged_list <- vector("list", len_first)
      for (i in seq_len(len_first)) {
        sub_objs <- lapply(obj_list, function(x) x[[i]])
        merged_list[[i]] <- merge_rds_objects(sub_objs)
      }
      return(merged_list)
    }
  }

  # Case 4: Vector
  if (is.vector(first_obj)) {
    return(do.call(c, obj_list))
  }

  stop(paste("Unsupported RDS object type for merging:", class(first_obj)[1]))
}

## Read all RDS files
loaded_objects <- lapply(rds_files, function(f) {
  cat("Reading:", f, "\n")
  readRDS(f)
})

## Merge objects
cat("Merging loaded objects...\n")
merged_result <- merge_rds_objects(loaded_objects)

## Save merged RDS output
cat("Saving merged output to RDS file:", rds_file, "\n")
saveRDS(merged_result, file = rds_file)

## Save merged text file if result is data.frame or matrix
if (is.data.frame(merged_result) || is.matrix(merged_result)) {
  tsv_file <- paste0(output_prefix, ".tsv")
  cat("Saving merged output to TSV file:", tsv_file, "\n")
  write.table(
    merged_result,
    file = tsv_file,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )
}

cat("Merge completed successfully.\n")
cat("Results saved to:\n")
cat("  RDS file: ", rds_file, "\n")
if (is.data.frame(merged_result) || is.matrix(merged_result)) {
  cat("  TSV file: ", tsv_file, "\n")
}
