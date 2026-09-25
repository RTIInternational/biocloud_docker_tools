library(optparse)

option_list <- list(
  make_option(
    "--model_lavaan",
    type = "character",
    help = "Lavaan model file for the user model (required)"
  ),
  make_option(
    "--results_rds",
    type = "character",
    help = paste(
      "RDS file containing output from gsem_usergwas.R or ",
      "gsem_commonfactorgwas.R (required)"
    )
  ),
  make_option(
    "--output_prefix",
    type = "character",
    help = "Output prefix for SNP results (required)"
  )
)

## Parse command-line arguments
parser <- OptionParser(option_list = option_list)
opt <- parse_args(parser)

## Check for required parameters
required_parameters <- c(
  "model_lavaan",
  "results_rds",
  "output_prefix"
)
for (param in required_parameters) {
  if (is.null(opt[[param]])) {
    stop(paste("Missing required parameter:", param))
  }
}

# Extract model lines containing "SNP" except for the SNP variance row.
model <- readLines(opt$model_lavaan, warn = FALSE)
normalized_model <- gsub("\\s+", "", model)
snp_components <- grep("SNP", normalized_model, value = TRUE)
snp_components <- unique(snp_components[
  snp_components != "SNP~~SNP" & nzchar(snp_components)
])

if (length(snp_components) == 0) {
  stop("No SNP components found in the model.")
} else {
  print("SNP components found in the model:")
  print(snp_components)
}

# Extract and combine the corresponding SNP results from the function output.
results <- readRDS(opt$results_rds)
if (length(results) == 0) {
  stop("No results found in the RDS file.")
}

if (!all(vapply(results, is.data.frame, logical(1)))) {
  stop("The results RDS must contain a list of data frames.")
}

component_rows <- lapply(results, function(result) {
  result_component <- gsub(
    "\\s+",
    "",
    paste(result$lhs, result$op, result$rhs)
  )
  lapply(snp_components, function(component) {
    result[result_component == component, , drop = FALSE]
  })
})

snp_results <- setNames(
  lapply(seq_along(snp_components), function(component_index) {
    matching_rows <- lapply(component_rows, `[[`, component_index)
    matching_rows <- matching_rows[vapply(matching_rows, nrow, integer(1)) > 0]
    if (length(matching_rows) == 0) {
      stop(
        "No result rows found for model component: ",
        snp_components[component_index]
      )
    }
    do.call(rbind, matching_rows)
  }),
  snp_components
)

output_dir <- dirname(opt$output_prefix)
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

for (component in names(snp_results)) {
  component_filename <- gsub("[^A-Za-z0-9_.-]+", "_", component)
  output_tsv <- file.path(
    output_dir,
    paste0(basename(opt$output_prefix), "_", component_filename, ".tsv")
  )
  write.table(
    snp_results[[component]],
    file = output_tsv,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )
  print(paste("Saved SNP results for component", component, "to", output_tsv))
}

print("Finished saving all SNP results.")