# Required packages
pacman::p_load(
  logr, sesame, parallel, BiocParallel, minfi, wateRmelon, dplyr, tibble, tidyr,
  PCAtools, GGally
)

args <- commandArgs(TRUE)
# Top directory where all the idats are stored
idat_location <- args[1]
# Methylation platform (EPICv2, EPIC, HM450, etc.)
platform <- args[2]
# Sample sheet with required columns sample_id and prefix, and optional column
# sex. If sex is absent, the predicted sex is used instead.
# (prefix = IDAT basename without the _Red/_Grn suffix)
sample_sheet_name <- args[3]
# Run name to identify the run in the output directory and log file names.
run_name <- args[4]

#idat_location <- "../idats"
#platform <- "EPIC"
#sample_sheet_name <- "inputs/nac_sample_sheet.txt"
#run_name <- "260622_libd_nac"

out_dir <- file.path("outputs", run_name)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
plot_dir <- file.path(out_dir, "plots")
dir.create(plot_dir, recursive = TRUE, showWarnings = FALSE)

# Create log file location
log_file <- file.path(out_dir, "dnam_processing_qc.log")
# Open log
lf <- logr::log_open(
  log_file, logdir = FALSE, show_notes = FALSE, traceback = FALSE
)
# On exit, close the log file
on.exit(logr::log_close())

# Set up a parallel backend that works on all platforms (including Windows).
# MulticoreParam uses forking and is not supported on Windows; SnowParam uses
# sockets and works everywhere.
n_workers <- max(1L, parallel::detectCores() - 2L)
if (.Platform$OS.type == "windows") {
  bpparam <- BiocParallel::SnowParam(workers = n_workers)
} else {
  bpparam <- BiocParallel::MulticoreParam(workers = n_workers)
}

# Write the input parameters to the log file.
logr::sep("Input parameters")
logr::log_print(
  paste("IDAT location:", idat_location), console = FALSE, blank_after = FALSE
)
logr::log_print(
  paste("Platform:", platform), console = FALSE, blank_after = FALSE
)
logr::log_print(
  paste("Sample sheet:", sample_sheet_name), console = FALSE,
  blank_after = FALSE
)
logr::log_print(paste("Output directory:", out_dir), console = FALSE)

################################################################################

logr::sep("Matching idat files with sample sheet")

# Get a list of all the idats in the idat location
idat_prefixes <- sesame::searchIDATprefixes(idat_location)

# If there are no idat files in the idat location, stop the script and print a
# message.
if (length(idat_prefixes) == 0) {
  stop("No idat files found in the idat location. Please check the idat
       location and try again.")
}

# If the platform is not one of the supported platforms, stop the script and
# print a message.
supported_platforms <- c("EPICv2", "EPIC", "HM450", "HM27")
if (!platform %in% supported_platforms) {
  stop(
    "Platform not supported. Please check the platform and try again.
    Supported platforms are: ", paste(supported_platforms, collapse = ", ")
  )
}
rm(supported_platforms)

# Read in the sample sheet.
sample_sheet <- read.table(sample_sheet_name, header = TRUE, sep = "\t")

# If the sample sheet is empty, stop the script and print a message.
if (nrow(sample_sheet) == 0) {
  stop("Sample sheet is empty. Please check the sample sheet and try again.")
}

# If the sample sheet does not have the required columns, stop the script and
# print a message.
required_columns <- c("sample_id", "prefix")
if (!all(required_columns %in% colnames(sample_sheet))) {
  stop(
    "Sample sheet is missing required columns. Please check the sample sheet and
    try again. Required columns are: ", paste(required_columns, collapse = ", ")
  )
}
rm(required_columns)

# Match idat files with the sample sheet.
matching_files <- idat_prefixes[names(idat_prefixes) %in% sample_sheet$prefix]

# If there are no matching idat files, stop the script and print a message.
if (length(matching_files) == 0) {
  stop(
    "No matching idat files found. Please check the idat location and sample
    sheet and try again."
  )
}

# Write a message listing the matched idat files and the corresponding sample
# IDs.
matched_samples <- sample_sheet$sample_id[
  match(names(matching_files), sample_sheet$prefix)
]
logr::log_print(
  paste(
    "Matched the following", length(matching_files),
    "idat files with the sample sheet:"
  ), console = FALSE, blank_after = FALSE
)
sample_sheet |>
  dplyr::filter(sample_id %in% matched_samples) |>
  dplyr::select(sample_id, prefix) |>
  logr::put(console = FALSE)

rm(matched_samples)

logr::sep("Reading in idat files")

# Read in the idat files so that we can get beadcount.
# force = TRUE allows mixing IDATs with slightly different array sizes (e.g.
# minor manufacturing revisions of the same platform).
rgchannelset <- minfi::read.metharray(
  basenames = matching_files, extended = TRUE, force = TRUE
)
# Store the beadcount information for later.
beadcount <- wateRmelon::beadcount(rgchannelset)
rm(rgchannelset)

# Read in the idat files using sesame to get the SDF objects for each sample.
sdf <- BiocParallel::bplapply(
  matching_files, sesame::readIDATpair, platform = platform,
  BPPARAM = bpparam
)

# Write the number of probes and samples in the rgchannelset object.
logr::log_print(
  paste(
    "Read in", length(sdf), "samples and", nrow(sdf[[1]]), "probes."
  ), console = FALSE
)

logr::sep("Checking predicted vs. reported sex")

# Infer the sex of the samples
predicted_sex <- BiocParallel::bplapply(
  sdf, function(x) sesame::inferSex(sesame::getBetas(x), platform = platform),
  BPPARAM = bpparam
)

# Add predicted sex to the sample sheet.
sample_sheet <- do.call(rbind, predicted_sex) |>
  as.data.frame() |>
  tibble::rownames_to_column(var = "prefix") |>
  dplyr::rename("predicted_sex" = V1) |>
  dplyr::right_join(sample_sheet, by = "prefix")

# If the sex column is present (case-insensitive), check for mismatches;
# otherwise skip.
colnames(sample_sheet) <- tolower(colnames(sample_sheet))
if ("sex" %in% colnames(sample_sheet)) {
  sample_sheet <- sample_sheet |>
    dplyr::mutate(
      sex_match = dplyr::case_when(
        predicted_sex == "MALE" & toupper(sex) %in% c("M", "MALE") ~ TRUE,
        predicted_sex == "FEMALE" & toupper(sex) %in% c("F", "FEMALE") ~ TRUE,
        is.na(predicted_sex) | is.na(sex) ~ NA,
        TRUE ~ FALSE
      )
    )

  mismatched_samples <- sample_sheet |>
    dplyr::filter(sex_match == FALSE) |>
    dplyr::pull(sample_id)

  if (length(mismatched_samples) > 0) {
    logr::log_print(
      paste(
        "Removing", length(mismatched_samples),
        "samples with mismatched predicted and reported sex:"
      ), console = FALSE, blank_after = FALSE
    )
    logr::log_print(mismatched_samples)

    sample_sheet <- sample_sheet |>
      dplyr::filter(!sample_id %in% mismatched_samples)
    sdf <- sdf[
      names(sdf) %in%
        sample_sheet$prefix[!sample_sheet$sample_id %in% mismatched_samples]
    ]
  } else {
    logr::log_print(
      "All samples have matching predicted and reported sex.",
      console = FALSE
    )
  }
  rm(mismatched_samples)
} else {
  logr::log_print(
    "No sex column in sample sheet. Skipping mismatch check; using predicted sex.",
    console = FALSE
  )
}
rm(predicted_sex)

# Apply the following recommended masks to the data. This is step "Q" in the
# openSesame pipeline, but I'm applying the masks manually here so that I can
# keep track of which probes are masked for which reasons. The recommended masks
# are from the "Experiment-independent Probe Masking" in
# https://zhou-lab.github.io/sesame/v1.16/supplemental.html#Preprocessing_Functions. #nolint: line length linter
# And the descriptionss of the masks are from:
# https://zwdzwd.github.io/InfiniumAnnotation/mask.html
# 1) mapping = Probes masked for mapping reasons. Probes retained should have
# high quality (>=40 on 0-60 scale) consistent (with designed MAPINFO) mapping
# (for both in the case of type I) without INDELs.
# 2) channel switch (aka typeINextBaseSwitch) = Probe has a SNP in the extension
# base that causes a color channel switch from the official annotation
# (described as color-channel-switching, or CCS SNP in the reference). These
# probes should be processed differently than designed (by summing up both
# color channels instead of just the annotated color channel).
# 3) snp5_GMAF1p = probes masked because 5bp 3'-subsequence (including extension
# for Type II) overlap with any of the SNPs with global MAF >1%.
# 4) extension (aka expBase) = probes masked for extension base inconsistent
# with specified color channel (type-I) or CpG (type-II) based on mapping.
# 5) sub30_copy = probes masked because the 30bp 3'-subsequence of the probe is
# non-unique.

logr::sep("Applying recommended sample-independent masks")

mask_cols <- c(
  "mapping", "channel_switch", "snp5_GMAF1p", "extension", "sub30_copy"
)

sdf_masked <- lapply(sdf, function(x) sesame::qualityMask(x, mask_cols))
rm(sdf, mask_cols)

# Mask probes with <3 beadcount in >5% of samples.
beadcount_remove_probes <- rowMeans(is.na(beadcount)) > 0.05
sdf_masked <- lapply(
  sdf_masked, function(x) sesame::addMask(x, beadcount_remove_probes)
)
rm(beadcount)

logr::sep("Dye bias correction")

# inferInfiniumIChannel = Infer channel for Infinium-I probes (C) and
# dyeBiasNL = Dye bias correction (non-linear) (D)
sdf_dye_corrected <- sesame::openSesame(
  sdf_masked, prep = "CD", func = NULL, platform = platform,
  BPPARAM = bpparam
)
rm(sdf_masked)
logr::sep("Calculating pOOBAH detection p-values and applying mask")

# Now calculate the pOOBAH p-values for the sample and apply a mask for probes
# with pOOBAH p-value > 0.05. This is step "P" in the openSesame pipeline, but
# I'm applying it manually so that I can keep track of the pOOBAH p-values for
# each sample and probe.
poobah_pvals <- BiocParallel::bplapply(sdf_dye_corrected,
  function(x) sesame::pOOBAH(x, combine.neg = TRUE, return.pval = TRUE),
  BPPARAM = bpparam
)

# Create a dataframe with the pOOBAH p-values for all samples and CpGs
poobah_pvalue_df <- poobah_pvals |>
  as.data.frame(check.names = FALSE) |>
  # Rename the columns to the sample IDs instead of the prefixes.
  dplyr::rename_with(
    .fn = ~paste0(
      sample_sheet$sample_id[match(.x, sample_sheet$prefix)], "_poobah"
    ),
    .cols = dplyr::everything()
  ) |>
  tibble::rownames_to_column(var = "Probe_ID")

# Mask probes with detection p-value >0.05 in >5% of samples.
poobah_remove_probes <- rowMeans(
  poobah_pvalue_df[, -1] > 0.05, na.rm = TRUE
) > 0.05
names(poobah_remove_probes) <- poobah_pvalue_df$Probe_ID
sdf_dye_corrected <- lapply(
  sdf_dye_corrected, function(x) sesame::addMask(x, poobah_remove_probes)
)

# Write out the pOOBAH p-values for all samples and CpGs
write.table(
  poobah_pvalue_df, file.path(out_dir, "poobah_pvalues.txt"), sep = "\t",
  row.names = FALSE, quote = FALSE
)
logr::log_print(
  "pOOBAH p-values written to:", console = FALSE, blank_after = FALSE
)
logr::log_print(file.path(out_dir, "poobah_pvalues.txt"), console = FALSE)

# Add the masking info to a masking dataframe.
cpg_masking_info <- tibble(
  Probe_ID = sdf_dye_corrected[[1]]$Probe_ID
) |>
  dplyr::mutate(
    mapping = Probe_ID %in% sesame::getMask(platform, "mapping"),
    channel_switch = Probe_ID %in% sesame::getMask(platform, "channel_switch"),
    snp5_GMAF1p = Probe_ID %in% sesame::getMask(platform, "snp5_GMAF1p"),
    extension = Probe_ID %in% sesame::getMask(platform, "extension"),
    sub30_copy = Probe_ID %in% sesame::getMask(platform, "sub30_copy"),
    low_beadcount = Probe_ID %in% names(which(beadcount_remove_probes)),
    poobah = Probe_ID %in% names(which(poobah_remove_probes)),
    ch_probe = grepl("^ch", Probe_ID),
    ct_probe = grepl("^ct", Probe_ID),
    rs_probe = grepl("^rs", Probe_ID)
  ) |>
  # Create a new column that is TRUE/FALSE for if there is a TRUE in any of the
  # columns besides Probe_ID.
  dplyr::mutate(any_reason = dplyr::if_any(-Probe_ID, ~.))

logr::sep("Identifying samples with high failure rates")

# Identify samples that have detection p > 0.05 for >1% of probes)
kept_probes <- cpg_masking_info |>
  dplyr::filter(!any_reason) |>
  dplyr::pull(Probe_ID)

sample_mask_rate <- vapply(
  poobah_pvals, function(x) mean(x[kept_probes] > 0.05, na.rm = TRUE),
  numeric(1)
)
rm(poobah_pvals, poobah_pvalue_df)

# Identify any samples that have >1% of probes with detection p > 0.05
high_failure_samples <- names(sample_mask_rate[sample_mask_rate > 0.01])

logr::log_print(
  "Removing samples with high failure rates (>1% probes with det. p > 0.05):",
  console = FALSE, blank_after = FALSE
)
data.frame(
  sample_id =
    sample_sheet$sample_id[match(names(sample_mask_rate), sample_sheet$prefix)],
  prop_failed_probes = signif(sample_mask_rate, 2)
) |>
  tibble::rownames_to_column(var = "prefix") |>
  dplyr::filter(prefix %in% high_failure_samples) |>
  logr::put(console = FALSE)

sdf_dye_corrected <- sdf_dye_corrected[
  !names(sdf_dye_corrected) %in% high_failure_samples
]

logr::sep("Applying NOOB normalization")

# Lastly, apply noob = Background subtraction using oob (B)
sdf_processed <- sesame::openSesame(
  sdf_dye_corrected, prep = "B", func = NULL, platform = platform,
  BPPARAM = bpparam
)
rm(sdf_dye_corrected)

logr::sep("Calculating QC stats")

# Calculate QC stats.
qc_stats <- BiocParallel::bplapply(
  sdf_processed, sesame::sesameQC_calcStats,
  BPPARAM = bpparam
)

# Add QC stats to the sample_sheet
qc_stat_df <- do.call(rbind, lapply(qc_stats, as.data.frame)) |>
  tibble::rownames_to_column(var = "prefix") |>
  dplyr::left_join(
    sample_sheet |> dplyr::select(prefix, sample_id), by = "prefix"
  ) |>
  dplyr::relocate(sample_id)

# Write out the QC stats for all samples.
write.table(
  qc_stat_df, file.path(out_dir, "qc_stats.txt"), sep = "\t", row.names = FALSE,
  quote = FALSE
)

logr::log_print("QC stats written to:", console = FALSE, blank_after = FALSE)
logr::log_print(file.path(out_dir, "qc_stats.txt"), console = FALSE)
rm(qc_stats, qc_stat_df)

# Extract allele frequencies
logr::sep("Extracting allele frequencies")

allele_freqs <- BiocParallel::bplapply(
  sdf_processed, sesame::getAFs, BPPARAM = bpparam
) |>
  as.data.frame(check.names = FALSE) |>
  # Rename the columns to the sample IDs instead of the prefixes.
  dplyr::rename_with(
    .fn = ~sample_sheet$sample_id[match(.x, sample_sheet$prefix)],
    .cols = dplyr::everything()
  ) |>
  tibble::rownames_to_column(var = "Probe_ID")

# Write allele frequencies to a file.
write.table(
  allele_freqs, file.path(out_dir, "allele_freqs.txt"), sep = "\t",
  row.names = FALSE, quote = FALSE
)
logr::log_print(
  "Allele frequencies written to:", console = FALSE, blank_after = FALSE
)
logr::log_print(file.path(out_dir, "allele_freqs.txt"), console = FALSE)

# Calculate pairwise sample correlation based on allele frequencies.
allele_freq_cor <- cor(allele_freqs[, -1], use = "pairwise.complete.obs")
high_cor_samples <- as.data.frame(allele_freq_cor) |>
  tibble::rownames_to_column(var = "sample_id") |>
  tidyr::pivot_longer(
    cols = -sample_id, names_to = "sample_id_2", values_to = "correlation"
  ) |>
  dplyr::filter(sample_id != sample_id_2) |>
  # Identify any pairs of samples with correlation > 0.8
  dplyr::filter(correlation > 0.8)

if (nrow(high_cor_samples) > 0) {
  logr::log_print(
    "The following pairs of samples have high correlation (> 0.8) based on
    allele frequencies:", console = FALSE, blank_after = FALSE
  )
  high_cor_samples |> logr::put(console = FALSE)
} else {
  logr::log_print(
    "No pairs of samples have high correlation (> 0.8) based on allele
    frequencies.", console = FALSE
  )
}

logr::sep("Extracting control probe signals and calculating PCs")

# I think there's some error in SeSame, because `negControls` and `normControls`
# are erroring as "not exported object from namespace:sesame", even though they
# are in the package reference.
controls_df <- lapply(sdf_processed, attr, "controls")
# Current (6/15/26, sesame v1.30.1) controls df has columns "G", "R", "col",
# "type", "<NA>", and "<NA>", with Names in rownames. The "col" and "type"
# columns are actually the beadcount from the green and red channels,
# respectively, and the NA columns are the color channel and control type,
# respectively. This comes from a mistake in the `readControls` function where
# the colnames are not properly assigned.
controls_df <- lapply(controls_df, function(df) {
  # Remove the incorrect "col" and "type" columns, which are actually "GN" and
  # "RN"
  df <- df[, -which(colnames(df) %in% c("col", "type"))]
  # Rename the columns to be what's in the `readControls` function.
  colnames(df) <- c("G", "R", "col", "type")
  df |> tibble::rownames_to_column(var = "Name")
})

# Extract the negative control probes.
neg_ctrl_mat <- lapply(controls_df, function(df) {
  df |> dplyr::filter(grepl("negative", tolower(type)))
}) |>
  dplyr::bind_rows(.id = "prefix") |>
  dplyr::left_join(
    sample_sheet |> dplyr::select(prefix, sample_id), by = "prefix"
  ) |>
  dplyr::select(sample_id, Name, G, R) |>
  tidyr::pivot_longer(
    cols = c(G, R), names_to = "channel", values_to = "signal"
  ) |>
  dplyr::mutate(feature = paste(Name, channel, sep = "_")) |>
  dplyr::select(sample_id, feature, signal) |>
  tidyr::pivot_wider(names_from = feature, values_from = signal) |>
  tibble::column_to_rownames(var = "sample_id") |>
  as.matrix()

# Calculate PCs and determine how many to retain.
neg_ctrl_pca <- prcomp(neg_ctrl_mat, center = TRUE, scale. = TRUE)
neg_ctrl_pca$variance <- summary(neg_ctrl_pca)$importance[2, ] * 100

# Calculate the number of PCs to retain based on the Elbow method.
elbow_n <- PCAtools::findElbowPoint(neg_ctrl_pca$variance)
logr::log_print(
  "Negative control probe PCs based on Elbow method:",
  console = FALSE, blank_after = FALSE
)
logr::log_print(elbow_n, console = FALSE)

logr::log_print(
  "Variance explained by the retained negative control probe PCs:",
  console = FALSE, blank_after = FALSE
)
neg_ctrl_pca$variance[1:elbow_n] |> logr::put(console = FALSE)

# Plot the negative control PCs against each other
png(file.path(plot_dir, "neg_ctrl_pc_pairs.png"))
GGally::ggpairs(
  as.data.frame(neg_ctrl_pca$x[, 1:min(5, elbow_n)]),
  title = "Pairs plot of negative control probe PCs"
)
dev.off()
logr::log_print("Pairs plot of negative control probe PCs written to:",
  console = FALSE, blank_after = FALSE
)
logr::log_print(file.path(plot_dir, "neg_ctrl_pc_pairs.png"), console = FALSE)

# Extract loadings for the max number of PCs to retain.
pcs_df <- as.data.frame(neg_ctrl_pca$x[, 1:elbow_n]) |>
  # Rename the columns to have a "neg_ctrl_" prefix
  dplyr::rename_with(
    .fn = ~paste0("neg_ctrl_", .x), .cols = dplyr::everything()
  ) |>
  tibble::rownames_to_column(var = "sample_id")

# Now repeat all that for the non-negative control probes. This is inspired by
# the `ctrlsva` function in the `ENmix` package.
nonneg_ctrl_mat <- lapply(controls_df, function(df) {
  df |> dplyr::filter(!grepl("negative", tolower(type)))
}) |>
  dplyr::bind_rows(.id = "prefix") |>
  dplyr::left_join(
    sample_sheet |> dplyr::select(prefix, sample_id), by = "prefix"
  ) |>
  dplyr::select(sample_id, Name, G, R) |>
  tidyr::pivot_longer(
    cols = c(G, R), names_to = "channel", values_to = "signal"
  ) |>
  dplyr::mutate(feature = paste(Name, channel, sep = "_")) |>
  dplyr::select(sample_id, feature, signal) |>
  tidyr::pivot_wider(names_from = feature, values_from = signal) |>
  tibble::column_to_rownames(var = "sample_id") |>
  as.matrix()

# Calculate PCs and determine how many to retain.
nonneg_ctrl_pca <- prcomp(nonneg_ctrl_mat, center = TRUE, scale. = TRUE)
nonneg_ctrl_pca$variance <- summary(nonneg_ctrl_pca)$importance[2, ] * 100

# Calculate the number of PCs to retain based on the Elbow method.
elbow_n <- PCAtools::findElbowPoint(nonneg_ctrl_pca$variance)
logr::log_print(
  "Non-negative control probe PCs based on Elbow method:", console = FALSE,
  blank_after = FALSE
)
logr::log_print(elbow_n, console = FALSE)

logr::log_print(
  "Variance explained by the retained non-negative control probe PCs:",
  console = FALSE, blank_after = FALSE
)
nonneg_ctrl_pca$variance[1:elbow_n] |> logr::put(console = FALSE)

# Plot the non-negative control PCs against each other
png(file.path(plot_dir, "nonneg_ctrl_pc_pairs.png"))
GGally::ggpairs(
  as.data.frame(nonneg_ctrl_pca$x[, 1:min(5, elbow_n)]),
  title = "Pairs plot of non-negative control probe PCs"
)
dev.off()
logr::log_print("Pairs plot of non-negative control probe PCs written to:",
  console = FALSE, blank_after = FALSE
)
logr::log_print(
  file.path(plot_dir, "nonneg_ctrl_pc_pairs.png"), console = FALSE
)

# Add to pcs dataframe
pcs_df <- pcs_df |>
  dplyr::left_join(
    as.data.frame(nonneg_ctrl_pca$x[, 1:elbow_n]) |>
      # Rename the columns to have a "nonneg_ctrl_" prefix
      dplyr::rename_with(
        .fn = ~paste0("nonneg_ctrl_", .x), .cols = dplyr::everything()
      ) |>
      tibble::rownames_to_column(var = "sample_id"),
    by = "sample_id"
  )

# Calculate PCs on beta values after masking everything but cg probes.
final_probes_mask <- cpg_masking_info$any_reason
names(final_probes_mask) <- cpg_masking_info$Probe_ID
sdf_processed <- lapply(
  sdf_processed, function(x) sesame::addMask(x, final_probes_mask)
)
beta_values <- lapply(sdf_processed, sesame::getBetas, sum.TypeI = TRUE)

beta_values_mat <- beta_values |>
  as.data.frame(check.names = FALSE) |>
  # Rename the columns to the sample IDs instead of the prefixes.
  dplyr::rename_with(
    .fn = ~sample_sheet$sample_id[match(.x, sample_sheet$prefix)],
    .cols = dplyr::everything()
  ) |>
  # Remove masked probes that are missing in more than 5% of the samples.
  dplyr::mutate(
    prop_missing = rowMeans(is.na(dplyr::across(dplyr::everything())))
  ) |>
  dplyr::filter(prop_missing <= 0.05) |>
  dplyr::select(-prop_missing) |>
  as.matrix()

beta_pca <- prcomp(t(beta_values_mat), center = TRUE, scale. = TRUE)
beta_pca$variance <- summary(beta_pca)$importance[2, ] * 100

# Calculate the number of PCs to retain based on the Elbow method.
elbow_n <- PCAtools::findElbowPoint(beta_pca$variance)
logr::log_print(
  "Beta value PCs based on Elbow method:", console = FALSE,
  blank_after = FALSE
)
logr::log_print(elbow_n, console = FALSE)

logr::log_print(
  "Variance explained by the retained beta value PCs:",
  console = FALSE, blank_after = FALSE
)
beta_pca$variance[1:elbow_n] |> logr::put(console = FALSE)

# Plot the beta value PCs against each other
png(file.path(plot_dir, "beta_pc_pairs.png"))
GGally::ggpairs(
  as.data.frame(beta_pca$x[, 1:min(5, elbow_n)]),
  title = "Pairs plot of beta value PCs"
)
dev.off()
logr::log_print("Pairs plot of beta value PCs written to:",
  console = FALSE, blank_after = FALSE
)
logr::log_print(
  file.path(plot_dir, "beta_pc_pairs.png"), console = FALSE
)

# Add to pcs dataframe
pcs_df <- pcs_df |>
  dplyr::left_join(
    as.data.frame(beta_pca$x[, 1:elbow_n]) |>
      # Rename the columns to have a "betas_" prefix
      dplyr::rename_with(
        .fn = ~paste0("betas_", .x), .cols = dplyr::everything()
      ) |>
      tibble::rownames_to_column(var = "sample_id"),
    by = "sample_id"
  )

# Add PCs to sample_sheet
sample_sheet <- sample_sheet |>
  dplyr::left_join(pcs_df, by = "sample_id")

rm(neg_ctrl_mat, nonneg_ctrl_mat, pcs_df, beta_pca, controls_df, elbow_n,
   neg_ctrl_pca, nonneg_ctrl_pca)

# Now write out the processed files.
logr::sep("Writing out processed files")

# Write out the number of probes masked for each reason.
logr::log_print(
  "Number of probes masked by recommended experiment-independent masks,",
  console = FALSE, blank_after = FALSE
)
logr::log_print(
  "having beadcount < 3 in >5% of samples, or",
  console = FALSE, blank_after = FALSE
)
logr::log_print(
  "having pOOBAH p-value > 0.05 in >5% of samples:",
  console = FALSE, blank_after = FALSE
)
cpg_masking_info |>
  dplyr::select(-Probe_ID) |>
  dplyr::summarize(dplyr::across(dplyr::everything(), ~sum(.))) |>
  tidyr::pivot_longer(
    cols = dplyr::everything(),
    names_to = "masking_reason", values_to = "n_probes"
  ) |>
  logr::put(console = FALSE)

# Write out the CpG masking info
write.table(
  cpg_masking_info, file.path(out_dir, "cpg_masking.txt"), sep = "\t",
  row.names = FALSE, quote = FALSE
)
logr::log_print("CpG masking info written to:",
  console = FALSE, blank_after = FALSE
)
logr::log_print(file.path(out_dir, "cpg_masking.txt"), console = FALSE)

# Updated sample sheet with PCs
write.table(
  sample_sheet, file.path(out_dir, "sample_sheet_pcs.txt"), sep = "\t",
  row.names = FALSE, quote = FALSE
)
logr::log_print(
  "Sample sheet with PCs written to:", console = FALSE, blank_after = FALSE
)
logr::log_print(file.path(out_dir, "sample_sheet_pcs.txt"), console = FALSE)

# SDF file
saveRDS(sdf_processed, file.path(out_dir, "sdf_processed.rds"))
logr::log_print(
  "Processed SDF object written to:", console = FALSE, blank_after = FALSE
)
logr::log_print(file.path(out_dir, "sdf_processed.rds"), console = FALSE)

# Beta-value matrix table
write.table(
  beta_values_mat, file.path(out_dir, "beta_values.txt"), sep = "\t",
  row.names = FALSE, quote = FALSE
)

logr::log_print(
  "Beta values for filtered probes written to:", console = FALSE,
  blank_after = FALSE
)
logr::log_print(file.path(out_dir, "beta_values.txt"), console = FALSE)

# M-values
m_values <- lapply(beta_values, sesame::BetaValueToMValue)
m_values_mat <- m_values |>
  as.data.frame(check.names = FALSE) |>
  # Rename the columns to the sample IDs instead of the prefixes.
  dplyr::rename_with(
    .fn = ~sample_sheet$sample_id[match(.x, sample_sheet$prefix)],
    .cols = dplyr::everything()
  ) |>
  tibble::rownames_to_column(var = "Probe_ID") |>
  # Filter to the same probes that were retained in the beta values.
  dplyr::filter(Probe_ID %in% kept_probes) |>
  tibble::column_to_rownames(var = "Probe_ID") |>
  as.matrix()

write.table(
  m_values_mat, file.path(out_dir, "m_values.txt"), sep = "\t",
  row.names = FALSE, quote = FALSE
)

logr::log_print(
  "M-values for filtered probes written to:", console = FALSE,
  blank_after = FALSE
)
logr::log_print(file.path(out_dir, "m_values.txt"), console = FALSE)

# Add session info to the log file.
logr::sep("Session info")
logr::log_print(sessionInfo(), console = FALSE)
