# Helper functions for reading MultiQC exports, normalizing sample IDs, and
# computing QC metrics used by bulk_rnaseq_quality_control.R.
# Return the first non-NULL value, providing a compact defaulting operator.
`%||%` <- function(x, y) {
	if (!is.null(x)) x else y
}

# Read a tab-delimited QC export with consistent parsing options.
safe_read_tsv <- function(path) {
	if (!file.exists(path)) {
		stop(paste("Missing required file:", path))
	}
	if (file.info(path)$size == 0) {
		return(data.frame())
	}
	tryCatch(
		utils::read.table(
			path,
			sep = "\t",
			header = TRUE,
			check.names = FALSE,
			quote = "",
			comment.char = "",
			stringsAsFactors = FALSE,
			fill = TRUE
		),
		error = function(e) {
			if (grepl("no lines available in input", e$message, fixed = TRUE)) {
				warning(paste("Empty QC input table:", path), call. = FALSE)
				return(data.frame())
			}
			stop(e)
		}
	)
}

# Resolve the first existing .txt or .tsv file for a known MultiQC export stem.
resolve_input_file <- function(data_dir, stems, exts = c("txt", "tsv")) {
	for (stem in stems) {
		for (ext in exts) {
			candidate <- file.path(data_dir, paste0(stem, ".", ext))
			if (file.exists(candidate)) {
				return(candidate)
			}
		}
	}
	file.path(data_dir, paste0(stems[1], ".", exts[1]))
}

# Convert MultiQC labels into comparable sample-level identifiers.
normalize_sample_labels <- function(x) {
	get_one_label <- function(value) {
		label <- trimws(as.character(value))
		label <- gsub('^"|"$', "", label)
		parts <- trimws(strsplit(label, " | ", fixed = TRUE)[[1]])
		parts <- parts[nzchar(parts)]
		if (length(parts) > 0) {
			ignore_parts <- c("agg_multiqc_input_dir", "aggregated_qc_logs")
			candidate_parts <- parts[!tolower(parts) %in% ignore_parts]
			if (length(candidate_parts) == 0) {
				candidate_parts <- parts
			}
			# Prefer the first non-adapter token, which is typically the sample ID.
			no_adapter_idx <- which(!grepl(" - ", candidate_parts, fixed = TRUE))
			if (length(no_adapter_idx) > 0) {
				label <- candidate_parts[no_adapter_idx[1]]
			} else {
				label <- candidate_parts[1]
			}
		}
		label <- sub(" - .*$", "", label)
		label <- sub("\\.\\.\\..*$", "", label)
		label <- sub("\\.split\\.[0-9]+$", "", label)
		label
	}
	vapply(x, get_one_label, character(1))
}

# Identify the sample column when a MultiQC table stores sample IDs as data.
get_sample_column <- function(df) {
	cn <- colnames(df)
	cand <- cn[grepl("^(sample|samplename|sample_name)$", cn, ignore.case = TRUE)]
	if (length(cand) > 0) {
		return(cand[1])
	}
	NULL
}

# Preserve sample IDs as row names so downstream metric tables can be aligned.
set_sample_rownames <- function(df) {
	if (!is.data.frame(df) || nrow(df) == 0) {
		return(df)
	}
	current_rn <- rownames(df)
	if (
		!is.null(current_rn) &&
		length(current_rn) == nrow(df) &&
		!all(current_rn %in% as.character(seq_len(nrow(df))))
	) {
		return(df)
	}
	sample_col <- get_sample_column(df)
	if (!is.null(sample_col)) {
		rn <- trimws(as.character(df[[sample_col]]))
		empty_idx <- which(is.na(rn) | rn == "")
		if (length(empty_idx) > 0) {
			rn[empty_idx] <- paste0("row_", empty_idx)
		}
		# Preserve raw labels for downstream parsing while forcing rowname uniqueness.
		rownames(df) <- make.unique(rn)
	}
	df
}

# Find the first column whose name matches one of the supplied patterns.
find_numeric_column <- function(df, patterns, default = NULL) {
	cn <- colnames(df)
	if (length(cn) == 0) {
		return(default)
	}
	for (pat in patterns) {
		idx <- grep(pat, cn, ignore.case = TRUE)
		if (length(idx) > 0) {
			return(cn[idx[1]])
		}
	}
	default
}

# Coerce percentages, counts, and character values to numeric values.
as_numeric_vector <- function(x) {
	if (is.factor(x)) {
		x <- as.character(x)
	}
	if (is.character(x)) {
		x <- gsub("%", "", x, fixed = TRUE)
		x <- gsub(",", "", x, fixed = TRUE)
	}
	suppressWarnings(as.numeric(x))
}

# Convert wide or tuple-valued QC tables into plotting-friendly long form.
reshape_long_plot <- function(df, x_col_name = "x") {
	if (!is.data.frame(df) || nrow(df) == 0) {
		return(data.frame())
	}
	df <- set_sample_rownames(df)
	sample_col <- get_sample_column(df)
	value_cols <- setdiff(colnames(df), sample_col %||% character(0))
	tuple_cols <- value_cols[vapply(
		df[value_cols],
		function(col_values) any(grepl(",", as.character(col_values), fixed = TRUE), na.rm = TRUE),
		logical(1)
	)]
	if (length(tuple_cols) > 0) {
		tuple_mat <- as.matrix(df[, tuple_cols, drop = FALSE])
		long_parts <- vector("list", length = nrow(tuple_mat) * ncol(tuple_mat))
		part_idx <- 0L
		for (row_idx in seq_len(nrow(tuple_mat))) {
			for (col_idx in seq_len(ncol(tuple_mat))) {
				cell_value <- as.character(tuple_mat[row_idx, col_idx])
				nums <- regmatches(
					cell_value,
					gregexpr("-?[0-9]+(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?", cell_value, perl = TRUE)
				)[[1]]
				if (length(nums) >= 2) {
					part_idx <- part_idx + 1L
					long_parts[[part_idx]] <- data.frame(
						value = as.numeric(nums[2]),
						x_value = as.numeric(nums[1]),
						stringsAsFactors = FALSE
					)
				}
			}
		}
		if (part_idx == 0L) {
			return(data.frame())
		}
		out <- do.call(rbind, long_parts[seq_len(part_idx)])
		colnames(out)[colnames(out) == "x_value"] <- x_col_name
		return(out)
	}
	num_cols <- colnames(df)[vapply(df, is.numeric, logical(1))]
	if (length(num_cols) == 0) {
		# Try coercion if all values arrived as character.
		num_guess <- lapply(df, as_numeric_vector)
		num_ok <- vapply(num_guess, function(v) sum(!is.na(v)) > 0, logical(1))
		num_cols <- names(num_ok)[num_ok]
		for (nm in num_cols) {
			df[[nm]] <- num_guess[[nm]]
		}
	}
	if (length(num_cols) == 0) {
		return(data.frame())
	}
	out <- stats::setNames(
		stack(df[, num_cols, drop = FALSE]),
		c("value", x_col_name)
	)
	out
}

# Load all MultiQC tables consumed by the QC workflow.
load_paired_end_qc_data <- function(data_dir) {
	paths <- list(
		fastqc = resolve_input_file(data_dir, c("multiqc_fastqc")),
		hisat2 = resolve_input_file(data_dir, c("multiqc_hisat2")),
		rseqc_bam_stat = resolve_input_file(data_dir, c("multiqc_rseqc_bam_stat")),
		rseqc_read_distribution = resolve_input_file(data_dir, c("multiqc_rseqc_read_distribution")),
		salmon = resolve_input_file(data_dir, c("multiqc_salmon")),
		trimmomatic = resolve_input_file(data_dir, c("multiqc_trimmomatic")),
		phred_bp = resolve_input_file(data_dir, c("fastqc_per_base_sequence_quality_plot")),
		phred_seq = resolve_input_file(data_dir, c("fastqc_per_sequence_quality_scores_plot")),
		gc_content = resolve_input_file(
			data_dir,
			c("fastqc_per_sequence_gc_content_plot_Counts", "fastqc_per_sequence_gc_content_plot")
		),
		seq_duplication = resolve_input_file(data_dir, c("fastqc_sequence_duplication_levels_plot")),
		adapter_content = resolve_input_file(data_dir, c("fastqc_adapter_content_plot"))
	)

	out <- list(
		fastqc = set_sample_rownames(safe_read_tsv(paths$fastqc)),
		hisat2 = set_sample_rownames(safe_read_tsv(paths$hisat2)),
		rseqc_bam_stat = set_sample_rownames(safe_read_tsv(paths$rseqc_bam_stat)),
		rseqc_alignment_category = set_sample_rownames(safe_read_tsv(paths$rseqc_read_distribution)),
		salmon = set_sample_rownames(safe_read_tsv(paths$salmon)),
		trimmomatic = set_sample_rownames(safe_read_tsv(paths$trimmomatic)),
		phred_bp = set_sample_rownames(safe_read_tsv(paths$phred_bp)),
		phred_seq = set_sample_rownames(safe_read_tsv(paths$phred_seq)),
		gc_content = set_sample_rownames(safe_read_tsv(paths$gc_content)),
		seq_duplication = set_sample_rownames(safe_read_tsv(paths$seq_duplication)),
		adapter_content = set_sample_rownames(safe_read_tsv(paths$adapter_content))
	)
	out
}

# Restrict tximport matrices to the samples retained for QC analysis.
subset_txi <- function(txi, ids, dimension = 2) {
	if (!is.list(txi)) {
		stop("txi must be a list-like tximport object")
	}
	if (dimension != 2) {
		stop("Only dimension=2 (sample columns) is supported")
	}
	for (nm in names(txi)) {
		obj <- txi[[nm]]
		if (is.matrix(obj) || is.data.frame(obj)) {
			shared <- intersect(colnames(obj), ids)
			if (length(shared) > 0) {
				txi[[nm]] <- obj[, shared, drop = FALSE]
			}
		}
	}
	txi
}

# Split FastQC rows into read orientation, trimming, and unpaired groups.
parse_by_trim_status <- function(raw_fastqc, paired_end = TRUE, r1_query = "(\\.R1|_R1)", r2_query = "(\\.R2|_R2)") {
	if (!is.data.frame(raw_fastqc) || nrow(raw_fastqc) == 0) {
		empty <- data.frame()
		return(list(trimmed_r1 = empty, trimmed_r2 = empty, untrimmed_r1 = empty, untrimmed_r2 = empty))
	}
	df <- raw_fastqc
	sample_col <- get_sample_column(df)
	labels <- if (!is.null(sample_col)) df[[sample_col]] else rownames(df)
	labels <- trimws(as.character(labels))
	is_trimmed <- grepl("trimmed", labels, ignore.case = TRUE)
	is_r1 <- grepl(r1_query, labels)
	is_r2 <- grepl(r2_query, labels)
	is_unpaired <- grepl("\\.unpaired$", labels)

	mk <- function(mask) {
		out <- df[mask, , drop = FALSE]
		if (nrow(out) > 0) {
			rn <- normalize_sample_labels(labels[mask])
			rownames(out) <- make.unique(rn)
		}
		out
	}

	list(
		trimmed_r1 = mk(is_trimmed & is_r1 & !is_unpaired),
		trimmed_r2 = mk(is_trimmed & is_r2 & !is_unpaired),
		untrimmed_r1 = mk(!is_trimmed & is_r1),
		untrimmed_r2 = mk(!is_trimmed & is_r2)
	)
}

# Plotting helpers return ggplot objects unless an explicit metric table is requested.
plot_seq_depth <- function(data, sort = TRUE) {
	df <- set_sample_rownames(data)
	col_depth <- find_numeric_column(df, c("total.*sequences", "sequences", "reads", "input"))
	if (is.null(col_depth)) {
		stop("Could not identify sequence depth column.")
	}
	vals <- as_numeric_vector(df[[col_depth]])
	plot_df <- data.frame(sample = rownames(df), values = vals, stringsAsFactors = FALSE)
	if (sort) {
		ord <- order(plot_df$values, decreasing = TRUE, na.last = TRUE)
		plot_df <- plot_df[ord, , drop = FALSE]
	}
	plot_df$sample <- factor(plot_df$sample, levels = plot_df$sample)
	ggplot2::ggplot(plot_df, ggplot2::aes(x = sample, y = values)) +
		ggplot2::geom_col(fill = "gray40") +
		ggplot2::labs(x = "Sample", y = "Read count") +
		ggplot2::theme_bw() +
		ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())
}

# Plot the distribution of sequence depths across samples.
plot_seq_depth_hist <- function(data) {
	df <- set_sample_rownames(data)
	col_depth <- find_numeric_column(df, c("total.*sequences", "sequences", "reads", "input"))
	if (is.null(col_depth)) {
		stop("Could not identify sequence depth column.")
	}
	vals <- as_numeric_vector(df[[col_depth]])
	plot_df <- data.frame(values = vals)
	ggplot2::ggplot(plot_df, ggplot2::aes(x = values)) +
		ggplot2::geom_histogram(bins = 30, fill = "gray30", color = "white") +
		ggplot2::labs(x = "Read count", y = "Sample count") +
		ggplot2::theme_bw()
}

# Plot or return the percentage of unique reads for each sample.
plot_unique_read_pct <- function(data, sort = TRUE, fill = "red4", return_data = FALSE) {
	df <- set_sample_rownames(data)
	col_unique <- find_numeric_column(df, c("%?.*unique", "unique.*pct", "deduplicated", "duplication"))
	if (is.null(col_unique)) {
		stop("Could not identify unique-read percentage column.")
	}
	vals <- as_numeric_vector(df[[col_unique]])
	# If this looks like duplication percentage, invert to get unique percentage.
	if (grepl("dup", col_unique, ignore.case = TRUE) && mean(vals, na.rm = TRUE) > 0) {
		vals <- 100 - vals
	}
	out <- data.frame(values = vals, row.names = rownames(df))
	if (return_data) {
		return(out)
	}
	plot_df <- data.frame(sample = rownames(df), values = vals, stringsAsFactors = FALSE)
	if (sort) {
		ord <- order(plot_df$values, decreasing = TRUE, na.last = TRUE)
		plot_df <- plot_df[ord, , drop = FALSE]
	}
	plot_df$sample <- factor(plot_df$sample, levels = plot_df$sample)
	ggplot2::ggplot(plot_df, ggplot2::aes(x = sample, y = values)) +
		ggplot2::geom_col(fill = fill) +
		ggplot2::labs(x = "Sample", y = "Unique reads (%)") +
		ggplot2::theme_bw() +
		ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())
}

# Plot median per-base Phred quality for each read group.
plot_phred_per_bp <- function(data, labels = c("R1", "R2"), line_colors = c("goldenrod2", "steelblue4"), alpha = 0.5) {
	if (!is.list(data) || length(data) == 0) {
		stop("Expected list of per-base phred data frames.")
	}
	long_parts <- list()
	for (i in seq_along(data)) {
		df <- data[[i]]
		long_df <- reshape_long_plot(df, x_col_name = "base")
		if (nrow(long_df) == 0) {
			next
		}
		long_df$group <- labels[pmin(i, length(labels))]
		long_parts[[length(long_parts) + 1]] <- long_df
	}
	if (length(long_parts) == 0) {
		stop("No numeric per-base phred data found.")
	}
	plot_df <- do.call(rbind, long_parts)
	plot_df$base_num <- as_numeric_vector(plot_df$base)
	ggplot2::ggplot(plot_df, ggplot2::aes(x = base_num, y = value, color = group)) +
		ggplot2::stat_summary(fun = stats::median, geom = "line", linewidth = 0.9, alpha = alpha) +
		ggplot2::scale_color_manual(values = line_colors) +
		ggplot2::labs(x = "Base position", y = "Phred score", color = NULL) +
		ggplot2::theme_bw()
}

# Plot median read GC distributions for each read group.
plot_gc_content <- function(data, labels = c("R1", "R2"), line_colors = c("goldenrod2", "steelblue4"), alpha = 0.5) {
	if (!is.list(data) || length(data) == 0) {
		stop("Expected list of GC-content data frames.")
	}
	long_parts <- list()
	for (i in seq_along(data)) {
		df <- data[[i]]
		long_df <- reshape_long_plot(df, x_col_name = "gc_bin")
		if (nrow(long_df) == 0) {
			next
		}
		long_df$group <- labels[pmin(i, length(labels))]
		long_parts[[length(long_parts) + 1]] <- long_df
	}
	if (length(long_parts) == 0) {
		stop("No numeric GC-content data found.")
	}
	plot_df <- do.call(rbind, long_parts)
	plot_df$gc_bin_num <- as_numeric_vector(plot_df$gc_bin)
	ggplot2::ggplot(plot_df, ggplot2::aes(x = gc_bin_num, y = value, color = group)) +
		ggplot2::stat_summary(fun = stats::median, geom = "line", linewidth = 0.9, alpha = alpha) +
		ggplot2::scale_color_manual(values = line_colors) +
		ggplot2::labs(x = "GC content (%)", y = "Density", color = NULL) +
		ggplot2::theme_bw()
}

# Plot excluded and retained read percentages from Trimmomatic output.
plot_trimmomatic_paired <- function(data, binsize = c(2.5, 0.25)) {
	df <- set_sample_rownames(data)
	drop_col <- find_numeric_column(df, c("dropped.*pct", "dropped", "discard", "unpaired"))
	if (is.null(drop_col)) {
		stop("Could not identify Trimmomatic dropped percentage column.")
	}
	dropped <- as_numeric_vector(df[[drop_col]])
	retained <- 100 - dropped
	plot_df <- data.frame(sample = rownames(df), dropped = dropped, retained = retained)
	plot_df$sample <- factor(plot_df$sample, levels = plot_df$sample)

	p_excluded <- ggplot2::ggplot(plot_df, ggplot2::aes(x = sample, y = dropped)) +
		ggplot2::geom_col(fill = "tomato3") +
		ggplot2::labs(x = "Sample", y = "Dropped reads (%)", title = "Excluded") +
		ggplot2::theme_bw() +
		ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())

	p_retained <- ggplot2::ggplot(plot_df, ggplot2::aes(x = sample, y = retained)) +
		ggplot2::geom_col(fill = "steelblue4") +
		ggplot2::labs(x = "Sample", y = "Retained reads (%)", title = "Retained") +
		ggplot2::theme_bw() +
		ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())

	list(excluded = p_excluded, retained = p_retained)
}

# Extract or return Salmon transcriptome mapping percentages.
plot_salmon_mapping_pct <- function(data, return_data = FALSE) {
	df <- set_sample_rownames(data)
	map_col <- find_numeric_column(df, c("mapped.*pct", "mapping.*pct", "% mapped", "mapping rate", "percent.*mapped", "mapping"))
	if (is.null(map_col)) {
		stop("Could not identify Salmon mapping percentage column.")
	}
	vals <- as_numeric_vector(df[[map_col]])
	out <- data.frame(values = vals, row.names = rownames(df))
	if (return_data) {
		return(out)
	}
	out
}

# Extract or return Salmon mapped read depth in millions.
plot_salmon_mapped_reads <- function(data, return_data = FALSE) {
	df <- set_sample_rownames(data)
	reads_col <- find_numeric_column(df, c("mapped.*reads", "num.*mapped", "aligned.*reads", "reads"))
	if (is.null(reads_col)) {
		stop("Could not identify Salmon mapped read count column.")
	}
	vals <- as_numeric_vector(df[[reads_col]]) / 1e6
	out <- data.frame(values = vals, row.names = rownames(df))
	if (return_data) {
		return(out)
	}
	out
}

# Plot Salmon input reads against mapped reads.
plot_salmon_stats <- function(data) {
	df <- set_sample_rownames(data)
	input_col <- find_numeric_column(df, c("input.*reads", "total.*reads", "processed", "reads"))
	mapped_col <- find_numeric_column(df, c("mapped.*reads", "num.*mapped", "aligned.*reads", "reads"))
	if (is.null(input_col) || is.null(mapped_col)) {
		stop("Could not identify Salmon input/mapped read columns.")
	}
	plot_df <- data.frame(
		input_reads = as_numeric_vector(df[[input_col]]),
		mapped_reads = as_numeric_vector(df[[mapped_col]])
	)
	ggplot2::ggplot(plot_df, ggplot2::aes(x = input_reads, y = mapped_reads)) +
		ggplot2::geom_point(size = 2.5, alpha = 0.8, color = "#0f766e") +
		ggplot2::labs(x = "Input reads", y = "Mapped reads") +
		ggplot2::theme_bw()
}

# Plot overall and unique HISAT2 alignment rates.
plot_hisat2_stats <- function(data) {
	df <- set_sample_rownames(data)
	overall_col <- find_numeric_column(df, c("overall.*alignment", "overall.*rate", "aligned.*pct", "mapping.*pct", "percent.*aligned", "alignment.*rate"))
	unique_col <- find_numeric_column(df, c("concordant.*exactly.*1", "unique.*pct", "uniq"))
	if (is.null(overall_col)) {
		stop("Could not identify HISAT2 mapping columns.")
	}
	plot_df <- data.frame(overall = as_numeric_vector(df[[overall_col]]))
	if (!is.null(unique_col)) {
		plot_df$unique <- as_numeric_vector(df[[unique_col]])
		ggplot2::ggplot(plot_df, ggplot2::aes(x = overall, y = unique)) +
			ggplot2::geom_point(size = 2.5, alpha = 0.8, color = "#1d4ed8") +
			ggplot2::labs(x = "Overall HISAT2 mapping (%)", y = "Unique alignment (%)") +
			ggplot2::theme_bw()
	} else {
		plot_df$sample <- seq_len(nrow(plot_df))
		ggplot2::ggplot(plot_df, ggplot2::aes(x = sample, y = overall)) +
			ggplot2::geom_point(size = 2.5, alpha = 0.8, color = "#1d4ed8") +
			ggplot2::labs(x = "Sample index", y = "Overall HISAT2 mapping (%)") +
			ggplot2::theme_bw()
	}
}

# Extract sample-level HISAT2 overall alignment rate.
extract_hisat2_mapping_pct <- function(data) {
	df <- set_sample_rownames(data)
	overall_col <- find_numeric_column(df, c("overall.*alignment", "overall.*rate", "aligned.*pct", "mapping.*pct", "percent.*aligned", "alignment.*rate"))
	if (is.null(overall_col)) {
		stop("Could not identify HISAT2 mapping percentage column.")
	}

	sample_key <- normalize_sample_labels(rownames(df))
	values <- as_numeric_vector(df[[overall_col]])
	weights <- NULL
	if (all(c("paired_total", "unpaired_total") %in% colnames(df))) {
		weights <- as_numeric_vector(df$paired_total) + as_numeric_vector(df$unpaired_total)
	}

	if (!is.null(weights) && any(is.finite(weights) & weights > 0)) {
		keep <- is.finite(values) & is.finite(weights) & weights > 0
		agg_num <- tapply(values[keep] * weights[keep], sample_key[keep], sum)
		agg_den <- tapply(weights[keep], sample_key[keep], sum)
		agg_values <- agg_num / agg_den
	} else {
		agg_values <- tapply(values, sample_key, function(sample_values) {
			out <- mean(sample_values, na.rm = TRUE)
			if (is.nan(out)) NA_real_ else out
		})
	}

	data.frame(values = as.numeric(agg_values), row.names = names(agg_values))
}

# Compare HISAT2 and Salmon mapping rates after sample-level aggregation.
plot_hisat2_vs_salmon <- function(hisat2, salmon) {
	hisat_df <- set_sample_rownames(hisat2)
	salmon_df <- set_sample_rownames(salmon)
	hisat_col <- find_numeric_column(hisat_df, c("overall.*alignment", "overall.*rate", "aligned.*pct", "mapping.*pct", "percent.*aligned", "alignment.*rate"))
	salmon_col <- find_numeric_column(salmon_df, c("mapped.*pct", "mapping.*pct", "% mapped", "mapping rate", "percent.*mapped", "mapping"))
	if (is.null(hisat_col) || is.null(salmon_col)) {
		stop("Could not identify HISAT2 and Salmon mapping percentage columns.")
	}

	# HISAT2 may be reported as split-level rows (e.g., sample.split.0, sample.split.1).
	# Collapse to sample-level keys so it can be compared against sample-level Salmon rows.
	hisat_key <- normalize_sample_labels(rownames(hisat_df))
	salmon_key <- normalize_sample_labels(rownames(salmon_df))

	hisat_vals <- as_numeric_vector(hisat_df[[hisat_col]])
	salmon_vals <- as_numeric_vector(salmon_df[[salmon_col]])

	hisat_weights <- NULL
	if (all(c("paired_total", "unpaired_total") %in% colnames(hisat_df))) {
		hisat_weights <- as_numeric_vector(hisat_df$paired_total) + as_numeric_vector(hisat_df$unpaired_total)
	}

	agg_hisat <- if (!is.null(hisat_weights) && any(is.finite(hisat_weights))) {
		num <- tapply(hisat_vals * hisat_weights, hisat_key, sum, na.rm = TRUE)
		den <- tapply(hisat_weights, hisat_key, sum, na.rm = TRUE)
		num / den
	} else {
		tapply(hisat_vals, hisat_key, mean, na.rm = TRUE)
	}

	agg_salmon <- tapply(salmon_vals, salmon_key, mean, na.rm = TRUE)
	shared <- intersect(names(agg_hisat), names(agg_salmon))
	if (length(shared) == 0) {
		stop("No overlapping sample IDs between HISAT2 and Salmon after normalization.")
	}

	plot_df <- data.frame(
		sample_id = shared,
		hisat2_mapping = as.numeric(agg_hisat[shared]),
		salmon_mapping = as.numeric(agg_salmon[shared]),
		stringsAsFactors = FALSE
	)
	plot_df <- plot_df[stats::complete.cases(plot_df[, c("hisat2_mapping", "salmon_mapping")]), , drop = FALSE]
	if (nrow(plot_df) == 0) {
		stop("No finite HISAT2/Salmon mapping values available after aggregation.")
	}
	ggplot2::ggplot(plot_df, ggplot2::aes(x = hisat2_mapping, y = salmon_mapping)) +
		ggplot2::geom_point(size = 2.5, alpha = 0.8, color = "#7c2d12") +
		ggplot2::labs(x = "HISAT2 mapping (%)", y = "Salmon mapping (%)") +
		ggplot2::theme_bw()
}

# Consolidate RSeQC mapping components into exonic, intronic, and intergenic percentages.
extract_mapping_categories <- function(data) {
	df <- set_sample_rownames(data)
	cn <- colnames(df)
	cn_key <- gsub("[^a-z0-9]", "", tolower(cn))

	pick_one_by_patterns <- function(patterns) {
		idx <- integer(0)
		for (pat in patterns) {
			idx <- c(idx, grep(pat, cn, ignore.case = TRUE, perl = TRUE))
		}
		idx <- unique(idx)
		if (length(idx) == 0) {
			return(NULL)
		}

		# Prefer explicit percent fields, then count fields, avoid base-length fields.
		idx <- idx[!grepl("total[_\\.]?bases", cn[idx], ignore.case = TRUE)]
		if (length(idx) == 0) {
			return(NULL)
		}
		idx_pct <- idx[grepl("tag[_\\.]?pct|pct|percent|percentage", cn[idx], ignore.case = TRUE)]
		if (length(idx_pct) > 0) {
			return(cn[idx_pct[1]])
		}
		idx_count <- idx[grepl("tag[_\\.]?count|count", cn[idx], ignore.case = TRUE)]
		if (length(idx_count) > 0) {
			return(cn[idx_count[1]])
		}
		cn[idx[1]]
	}

	pick_many <- function(group_patterns) {
		unique(Filter(Negate(is.null), lapply(group_patterns, pick_one_by_patterns)))
	}

	# Match both legacy OmixJutsu-style names and MultiQC v1.35 rseqc names.
	intergenic_cols <- pick_many(list(
		c("^other[_\\.]?intergenic"),
		c("^downstream[_\\.]?10kb", "^tes[_\\.]?down[_\\.]?10kb"),
		c("^upstream[_\\.]?10kb", "^tss[_\\.]?up[_\\.]?10kb")
	))
	intronic_cols <- pick_many(list(
		c("^introns?([_\\.]|$)", "^intron([_\\.]|$)")
	))
	exonic_cols <- pick_many(list(
		c("^3[_\\.]?utr[_\\.]?exons?", "^utr[_\\.]?3"),
		c("^5[_\\.]?utr[_\\.]?exons?", "^utr[_\\.]?5"),
		c("^cds[_\\.]?exons?", "^cds([_\\.]|$)")
	))

	# Fallback to pre-consolidated category columns when legacy component columns are absent.
	if (length(intergenic_cols) == 0) {
		intergenic_col <- find_numeric_column(df, c("intergenic"))
		if (!is.null(intergenic_col)) intergenic_cols <- intergenic_col
	}
	if (length(intronic_cols) == 0) {
		intronic_col <- find_numeric_column(df, c("intronic", "intron"))
		if (!is.null(intronic_col)) intronic_cols <- intronic_col
	}
	if (length(exonic_cols) == 0) {
		exonic_col <- find_numeric_column(df, c("exonic", "exon"))
		if (!is.null(exonic_col)) exonic_cols <- exonic_col
	}

	if (length(intergenic_cols) == 0 || length(intronic_cols) == 0 || length(exonic_cols) == 0) {
		stop("Could not identify exonic, intronic, and intergenic mapping columns.")
	}

	sum_selected_cols <- function(cols) {
		mat <- as.data.frame(lapply(cols, function(col) as_numeric_vector(df[[col]])), stringsAsFactors = FALSE)
		rowSums(as.matrix(mat), na.rm = TRUE)
	}

	intergenic_vals <- sum_selected_cols(intergenic_cols)
	intronic_vals <- sum_selected_cols(intronic_cols)
	exonic_vals <- sum_selected_cols(exonic_cols)

	out <- data.frame(
		Exonic = as.numeric(exonic_vals),
		Intronic = as.numeric(intronic_vals),
		Intergenic = as.numeric(intergenic_vals),
		row.names = rownames(df)
	)

	# If values are fractional shares (0-1), convert to percentages.
	row_total <- rowSums(out[, c("Exonic", "Intronic", "Intergenic")], na.rm = TRUE)
	if (is.finite(stats::median(row_total, na.rm = TRUE)) && stats::median(row_total, na.rm = TRUE) <= 1.5) {
		out$Exonic <- out$Exonic * 100
		out$Intronic <- out$Intronic * 100
		out$Intergenic <- out$Intergenic * 100
	}

	out
}

# Plot or return consolidated RSeQC mapping categories.
plot_mapping_categories <- function(data, sort = TRUE, consolidate = TRUE, return_data = FALSE) {
	out <- extract_mapping_categories(data)
	if (return_data) {
		return(out)
	}
	plot_df <- out
	if (sort) {
		ord <- order(plot_df$Exonic + plot_df$Intronic + plot_df$Intergenic, decreasing = TRUE, na.last = TRUE)
		plot_df <- plot_df[ord, , drop = FALSE]
	}
	plot_df$sample <- rownames(plot_df)
	metric_cols <- c("Exonic", "Intronic", "Intergenic")
	long <- data.frame(
		sample = rep(plot_df$sample, times = length(metric_cols)),
		category = rep(metric_cols, each = nrow(plot_df)),
		value = as.numeric(unlist(plot_df[, metric_cols, drop = FALSE], use.names = FALSE)),
		stringsAsFactors = FALSE
	)
	long$sample <- factor(long$sample, levels = unique(plot_df$sample))
	ggplot2::ggplot(long, ggplot2::aes(x = sample, y = value, fill = category)) +
		ggplot2::geom_col(position = "fill") +
		ggplot2::labs(x = "Sample", y = "Fraction", fill = "Category") +
		ggplot2::theme_bw() +
		ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())
}

# Plot or return RNA integrity number distributions.
plot_rin <- function(data, return_data = FALSE, colors = "gray30", box_fill = "goldenrod", jitter_alpha = 0.5) {
	df <- as.data.frame(data)
	vals <- as_numeric_vector(df[[1]])
	out <- data.frame(values = vals)
	if (return_data) {
		return(out)
	}
	hist <- ggplot2::ggplot(out, ggplot2::aes(x = values)) +
		ggplot2::geom_histogram(bins = 30, fill = colors, color = "white") +
		ggplot2::labs(x = "RIN", y = "Sample count") +
		ggplot2::theme_bw()
	boxplot <- ggplot2::ggplot(out, ggplot2::aes(x = "", y = values)) +
		ggplot2::geom_boxplot(fill = box_fill, outlier.alpha = 0) +
		ggplot2::geom_jitter(width = 0.12, alpha = jitter_alpha, color = colors) +
		ggplot2::labs(x = NULL, y = "RIN") +
		ggplot2::theme_bw() +
		ggplot2::coord_flip()
	list(hist = hist, boxplot = boxplot)
}

# Calculate and plot Shannon diversity from normalized expression counts.
plot_shannon_index <- function(data, min_value = 10, colors = "gray30", return_data = FALSE, return = FALSE) {
	mat <- as.matrix(data)
	mat[is.na(mat)] <- 0
	keep_rows <- rowSums(mat >= min_value, na.rm = TRUE) > 0
	if (any(keep_rows)) {
		mat <- mat[keep_rows, , drop = FALSE]
	}
	mat <- pmax(mat, 0)
	col_tot <- colSums(mat, na.rm = TRUE)
	sh <- rep(NA_real_, ncol(mat))
	for (i in seq_len(ncol(mat))) {
		if (col_tot[i] > 0) {
			p <- mat[, i] / col_tot[i]
			p <- p[p > 0]
			sh[i] <- -sum(p * log(p))
		}
	}
	out <- data.frame(values = sh, row.names = colnames(mat))
	if (isTRUE(return_data) || isTRUE(return)) {
		return(out)
	}
	hist <- ggplot2::ggplot(out, ggplot2::aes(x = values)) +
		ggplot2::geom_histogram(bins = 30, fill = colors, color = "white") +
		ggplot2::labs(x = "Shannon index", y = "Sample count") +
		ggplot2::theme_bw()
	boxplot <- ggplot2::ggplot(out, ggplot2::aes(x = "", y = values)) +
		ggplot2::geom_boxplot(fill = "khaki", outlier.alpha = 0) +
		ggplot2::geom_jitter(width = 0.12, alpha = 0.5, color = colors) +
		ggplot2::labs(x = NULL, y = "Shannon index") +
		ggplot2::theme_bw() +
		ggplot2::coord_flip()
	list(hist = hist, boxplot = boxplot)
}

# Calculate the count-weighted mean Phred score for each sample.
plot_phred_mean <- function(data, return_data = TRUE) {
	df <- set_sample_rownames(data)
	if (!is.data.frame(df) || nrow(df) == 0) {
		return(data.frame(values = numeric(0)))
	}
	sample_col <- get_sample_column(df)
	value_cols <- setdiff(colnames(df), sample_col %||% character(0))
	if (length(value_cols) == 0) {
		return(data.frame(values = numeric(0)))
	}

	tuple_cols <- value_cols[vapply(
		df[value_cols],
		function(col_values) any(grepl(",", as.character(col_values), fixed = TRUE), na.rm = TRUE),
		logical(1)
	)]

	if (length(tuple_cols) > 0) {
		tuple_mat <- as.matrix(df[, tuple_cols, drop = FALSE])
		score_mat <- matrix(NA_real_, nrow = nrow(tuple_mat), ncol = ncol(tuple_mat))
		count_mat <- matrix(NA_real_, nrow = nrow(tuple_mat), ncol = ncol(tuple_mat))
		for (row_idx in seq_len(nrow(tuple_mat))) {
			for (col_idx in seq_len(ncol(tuple_mat))) {
				nums <- regmatches(
					as.character(tuple_mat[row_idx, col_idx]),
					gregexpr("-?[0-9]+(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?", as.character(tuple_mat[row_idx, col_idx]), perl = TRUE)
				)[[1]]
				if (length(nums) >= 2) {
					score_mat[row_idx, col_idx] <- as.numeric(nums[1])
					count_mat[row_idx, col_idx] <- as.numeric(nums[2])
				}
			}
		}
		denom <- rowSums(count_mat, na.rm = TRUE)
		vals <- ifelse(denom > 0, rowSums(score_mat * count_mat, na.rm = TRUE) / denom, NA_real_)
	} else {
		coerced <- lapply(df[value_cols], as_numeric_vector)
		num_ok <- vapply(coerced, function(vals) sum(!is.na(vals)) > 0, logical(1))
		num_cols <- names(num_ok)[num_ok]
		if (length(num_cols) == 0) {
			return(data.frame(values = numeric(0)))
		}
		for (col_name in num_cols) {
			df[[col_name]] <- coerced[[col_name]]
		}
		phred_bins <- as_numeric_vector(num_cols)
		if (sum(!is.na(phred_bins)) >= 2) {
			count_mat <- as.matrix(df[, num_cols, drop = FALSE])
			storage.mode(count_mat) <- "numeric"
			valid_bins <- !is.na(phred_bins)
			count_mat <- count_mat[, valid_bins, drop = FALSE]
			phred_bins <- phred_bins[valid_bins]
			denom <- rowSums(count_mat, na.rm = TRUE)
			vals <- ifelse(denom > 0, as.numeric(count_mat %*% phred_bins) / denom, NA_real_)
		} else {
			vals <- rowMeans(df[, num_cols, drop = FALSE], na.rm = TRUE)
		}
	}
	out <- data.frame(values = vals, row.names = rownames(df))
	if (return_data) {
		return(out)
	}
	out
}

# Calculate the count-weighted mean GC percentage for each sample.
plot_gc_mean <- function(data, return_data = TRUE) {
	df <- set_sample_rownames(data)
	value_cols <- setdiff(colnames(df), get_sample_column(df) %||% character(0))
	tuple_cols <- value_cols[vapply(
		df[value_cols],
		function(col_values) any(grepl(",", as.character(col_values), fixed = TRUE), na.rm = TRUE),
		logical(1)
	)]

	if (length(tuple_cols) > 0) {
		tuple_mat <- as.matrix(df[, tuple_cols, drop = FALSE])
		gc_mat <- matrix(NA_real_, nrow = nrow(tuple_mat), ncol = ncol(tuple_mat))
		count_mat <- matrix(NA_real_, nrow = nrow(tuple_mat), ncol = ncol(tuple_mat))
		for (row_idx in seq_len(nrow(tuple_mat))) {
			for (col_idx in seq_len(ncol(tuple_mat))) {
				nums <- regmatches(
					as.character(tuple_mat[row_idx, col_idx]),
					gregexpr("-?[0-9]+(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?", as.character(tuple_mat[row_idx, col_idx]), perl = TRUE)
				)[[1]]
				if (length(nums) >= 2) {
					gc_mat[row_idx, col_idx] <- as.numeric(nums[1])
					count_mat[row_idx, col_idx] <- as.numeric(nums[2])
				}
			}
		}
		denom <- rowSums(count_mat, na.rm = TRUE)
		vals <- ifelse(denom > 0, rowSums(gc_mat * count_mat, na.rm = TRUE) / denom, NA_real_)
	} else {
		num_cols <- colnames(df)[vapply(df, is.numeric, logical(1))]
		if (length(num_cols) == 0) {
			coerced <- lapply(df, as_numeric_vector)
			num_ok <- vapply(coerced, function(v) sum(!is.na(v)) > 0, logical(1))
			num_cols <- names(num_ok)[num_ok]
			for (nm in num_cols) {
				df[[nm]] <- coerced[[nm]]
			}
		}
		if (length(num_cols) == 0) {
			return(data.frame(values = numeric(0)))
		}

		gc_bins <- as_numeric_vector(num_cols)
		if (sum(!is.na(gc_bins)) >= 3 && max(gc_bins, na.rm = TRUE) <= 1.5) {
			# Some schemas encode GC bins as fractions (0-1); convert to percent.
			gc_bins <- gc_bins * 100
		}
		use_weighted <- sum(!is.na(gc_bins)) >= 3

		if (use_weighted) {
			mat <- as.matrix(df[, num_cols, drop = FALSE])
			storage.mode(mat) <- "numeric"
			valid_bins <- !is.na(gc_bins)
			mat <- mat[, valid_bins, drop = FALSE]
			gc_bins <- gc_bins[valid_bins]

			# Weighted mean GC per sample: sum(%GC * counts_or_density) / sum(counts_or_density).
			denom <- rowSums(mat, na.rm = TRUE)
			numer <- as.numeric(mat %*% gc_bins)
			vals <- ifelse(denom > 0, numer / denom, NA_real_)
		} else {
			# Fallback for unexpected schemas where GC bin positions are unavailable.
			vals <- rowMeans(df[, num_cols, drop = FALSE], na.rm = TRUE)
		}
	}

	if (sum(!is.na(vals)) > 0 && stats::median(vals, na.rm = TRUE) <= 1.5) {
		# Defensive scaling when computed GC values are fractional rather than percent.
		vals <- vals * 100
	}
	out <- data.frame(values = vals, row.names = rownames(df))
	if (return_data) {
		return(out)
	}
	out
}

# Calculate the combined exonic plus intronic gene-mapping percentage.
plot_gene_mapping_rate <- function(data, group = NULL, return_data = TRUE) {
	df <- as.data.frame(data)
	if (!all(c("Exonic", "Intronic") %in% colnames(df))) {
		stop("plot_gene_mapping_rate expects Exonic and Intronic columns")
	}
	vals <- as_numeric_vector(df$Exonic) + as_numeric_vector(df$Intronic)
	out <- data.frame(values = vals, row.names = rownames(df))
	if (return_data) {
		return(out)
	}
	out
}

# Calculate the intergenic-to-intronic mapping ratio.
plot_dna_contamination_ratio <- function(data, group = NULL, return_data = TRUE) {
	df <- as.data.frame(data)
	if (!all(c("Intergenic", "Intronic") %in% colnames(df))) {
		stop("plot_dna_contamination_ratio expects Intergenic and Intronic columns")
	}
	intergenic <- as_numeric_vector(df$Intergenic)
	intronic <- as_numeric_vector(df$Intronic)
	vals <- intergenic / intronic
	vals[!is.finite(vals)] <- NA_real_
	out <- data.frame(values = vals, row.names = rownames(df))
	if (return_data) {
		return(out)
	}
	out
}

# Calculate mean expression for selected features partitioned by sample group.
plot_partitioned_mean_expression <- function(dds, group_var, feature_ids, invert_cols = TRUE, return_data = TRUE) {
	mat <- SummarizedExperiment::assay(dds)
	feature_ids <- intersect(feature_ids, rownames(mat))
	if (length(feature_ids) == 0) {
		stop("No feature IDs found in assay matrix")
	}
	vals <- colMeans(mat[feature_ids, , drop = FALSE], na.rm = TRUE)
	out <- data.frame(values = as.numeric(vals), row.names = colnames(mat))
	if (return_data) {
		return(out)
	}
	out
}

# Calculate a principal-component score for selected features by sample group.
plot_partitioned_pc <- function(dds_vst, pc = 1, group_var, center = TRUE, scale = FALSE, feature_ids, return_data = TRUE) {
	mat <- SummarizedExperiment::assay(dds_vst)
	feature_ids <- intersect(feature_ids, rownames(mat))
	if (length(feature_ids) < 2) {
		stop("Need at least two feature IDs for PCA")
	}
	pca <- stats::prcomp(t(mat[feature_ids, , drop = FALSE]), center = center, scale. = scale)
	vals <- pca$x[, pc]
	out <- data.frame(values = as.numeric(vals), row.names = rownames(pca$x))
	if (return_data) {
		return(out)
	}
	out
}

# Compute feature-level expression fractions as percentages of sample totals.
compute_feature_fraction <- function(count_matrix, feature_ids) {
	feature_ids <- intersect(feature_ids, rownames(count_matrix))
	out <- data.frame(values = rep(NA_real_, ncol(count_matrix)), row.names = colnames(count_matrix))
	if (length(feature_ids) == 0) {
		return(out)
	}
	total_counts <- colSums(count_matrix, na.rm = TRUE)
	feature_counts <- colSums(count_matrix[feature_ids, , drop = FALSE], na.rm = TRUE)
	out$values <- ifelse(total_counts > 0, (feature_counts / total_counts) * 100, NA_real_)
	out
}

# Generate paired histogram and horizontal boxplot summaries for percentage metrics.
plot_fraction_summary <- function(metric_df, title_text, fill_color = "goldenrod") {
	if (is.null(metric_df) || !is.data.frame(metric_df) || nrow(metric_df) == 0) {
		stop("Metric table is empty.")
	}
	value_col <- if ("values" %in% colnames(metric_df)) "values" else colnames(metric_df)[1]
	values <- suppressWarnings(as.numeric(metric_df[[value_col]]))
	plot_df <- data.frame(sample_id = rownames(metric_df), values = values, stringsAsFactors = FALSE)
	hist_plot <- ggplot2::ggplot(plot_df, ggplot2::aes(x = values)) +
		ggplot2::geom_histogram(bins = 30, fill = "gray30", color = "white") +
		ggplot2::labs(title = title_text, x = "Percent of normalized counts", y = "Sample count") +
		ggplot2::theme_bw()
	box_plot <- ggplot2::ggplot(plot_df, ggplot2::aes(x = "", y = values)) +
		ggplot2::geom_boxplot(fill = fill_color, outlier.alpha = 0) +
		ggplot2::geom_jitter(width = 0.12, alpha = 0.5, color = "gray30") +
		ggplot2::labs(x = NULL, y = "Percent of normalized counts") +
		ggplot2::theme_bw() +
		ggplot2::coord_flip()
	list(hist = hist_plot, boxplot = box_plot)
}

# Stream matching gene IDs from a GTF without shelling out to awk.
get_annotation_gene_ids <- function(gtf_path, seqnames = NULL, gene_types = NULL, exclude_par = FALSE) {
	if (!file.exists(gtf_path)) {
		stop(paste("Missing annotation GTF:", gtf_path))
	}

	extract_attr <- function(attributes, attr_name) {
		pattern <- paste0(attr_name, " \\\"([^\\\"]+)\\\"")
		out <- sub(paste0(".*", pattern, ".*"), "\\1", attributes)
		out[out == attributes] <- NA_character_
		out
	}

	ids <- character(0)
	con <- file(gtf_path, open = "r")
	on.exit(close(con), add = TRUE)

	repeat {
		lines <- readLines(con, n = 100000, warn = FALSE)
		if (length(lines) == 0) {
			break
		}

		lines <- lines[nzchar(lines) & !startsWith(lines, "#")]
		if (length(lines) == 0) {
			next
		}

		fields <- strsplit(lines, "\t", fixed = TRUE)
		field_lengths <- vapply(fields, length, integer(1))
		fields <- fields[field_lengths >= 9]
		if (length(fields) == 0) {
			next
		}

		seqname_values <- vapply(fields, `[[`, character(1), 1)
		feature_values <- vapply(fields, `[[`, character(1), 3)
		start_values <- suppressWarnings(as.integer(vapply(fields, `[[`, character(1), 4)))
		end_values <- suppressWarnings(as.integer(vapply(fields, `[[`, character(1), 5)))
		attribute_values <- vapply(fields, `[[`, character(1), 9)

		keep <- feature_values == "gene"
		if (!is.null(seqnames) && length(seqnames) > 0) {
			keep <- keep & seqname_values %in% seqnames
		}
		if (!is.null(gene_types) && length(gene_types) > 0) {
			gene_type_values <- extract_attr(attribute_values, "gene_type")
			gene_biotype_values <- extract_attr(attribute_values, "gene_biotype")
			keep <- keep & (gene_type_values %in% gene_types | gene_biotype_values %in% gene_types)
		}
		if (exclude_par) {
			is_chr_y <- seqname_values %in% c("chrY", "Y")
			overlaps_par <-
				(start_values <= 2781479 & end_values >= 10001) |
				(start_values <= 57217415 & end_values >= 56887903)
			keep <- keep & !(is_chr_y & overlaps_par)
		}

		if (any(keep, na.rm = TRUE)) {
			gene_ids <- extract_attr(attribute_values[keep], "gene_id")
			ids <- c(ids, gene_ids[!is.na(gene_ids) & nzchar(gene_ids)])
		}
	}

	unique(ids)
}

# Parse command-line inputs as strict --flag value pairs.
parse_flag_args <- function(cli_args) {
	if (length(cli_args) %% 2 != 0) {
		stop("All inputs must be provided as --flag value pairs.")
	}
	keys <- cli_args[seq(1, length(cli_args), by = 2)]
	vals <- cli_args[seq(2, length(cli_args), by = 2)]
	if (!all(startsWith(keys, "--"))) {
		stop("Invalid argument format. Flags must start with '--'.")
	}
	names(vals) <- sub("^--", "", keys)
	as.list(vals)
}

# Save each plot with a run_name prefix for traceability across runs.
save_plot <- function(plot_obj, filename, width = 10, height = 6, dpi = 150,
		plot_dir = get("plot_dir", parent.frame()),
		run_name = get("run_name", parent.frame())) {
	out_file <- file.path(plot_dir, paste0(run_name, "_", filename))
	ggplot2::ggsave(
		filename = out_file,
		plot = plot_obj,
		width = width,
		height = height,
		units = "in",
		dpi = dpi
	)
	logr::log_print(paste("Wrote plot:", out_file), console = FALSE)
}

# Keep plotting resilient: log and continue when one plot block fails.
with_plot_guard <- function(expr, plot_name) {
	tryCatch(
		expr,
		error = function(e) {
			logr::log_print(
				paste0("Skipping plot ", plot_name, " due to error: ", e$message),
				console = FALSE
			)
			NULL
		}
	)
}

# Extract the sample identifier from a MultiQC/FastQ label.
extract_fastq_id <- function(x) {
	get_one_id <- function(value) {
		id <- trimws(as.character(value))
		id <- gsub('^"|"$', "", id)
		parts <- trimws(strsplit(id, " | ", fixed = TRUE)[[1]])
		parts <- parts[nzchar(parts)]
		if (length(parts) > 0) {
			ignore_parts <- c("agg_multiqc_input_dir", "aggregated_qc_logs")
			candidate_parts <- parts[!tolower(parts) %in% ignore_parts]
			if (length(candidate_parts) == 0) {
				candidate_parts <- parts
			}

			# Prefer the first clean sample-like token over read/adapter-expanded tokens.
			no_adapter_idx <- which(!grepl(" - ", candidate_parts, fixed = TRUE))
			if (length(no_adapter_idx) > 0) {
				id <- candidate_parts[no_adapter_idx[1]]
			} else {
				id <- candidate_parts[1]
			}
		}
		id <- sub(" - .*$", "", id)
		id <- vapply(strsplit(id, "...", fixed = TRUE), `[[`, character(1), 1)
		id <- sub("\\.split\\.[0-9]+$", "", id)
		id
	}
	vapply(x, get_one_id, character(1))
}

# Normalize sample identifiers by removing common file, lane, and read suffixes.
normalize_sample_id <- function(x) {
	x <- trimws(as.character(x))
	x <- basename(x)
	x <- sub(" - .*$", "", x)
	x <- sub("\\.(fastq|fq)(\\.gz)?$", "", x, ignore.case = TRUE)
	x <- sub("\\.bam$", "", x, ignore.case = TRUE)
	x <- sub("_L[0-9]{3}_R[12]_[0-9]{3}$", "", x, ignore.case = TRUE)
	x <- sub("_R[12]_[0-9]{3}$", "", x, ignore.case = TRUE)
	x <- sub("_R[12]$", "", x, ignore.case = TRUE)
	x <- sub("\\.R[12]$", "", x, ignore.case = TRUE)
	x <- sub("([._-])(trimmed|untrimmed)$", "", x, ignore.case = TRUE)
	x <- sub("\\.split\\.[0-9]+$", "", x, ignore.case = TRUE)
	x <- gsub("[._-]+$", "", x)
	x <- tolower(x)
	x <- sub("^sample[_-]*", "", x)
	x <- sub("^0+", "", x)
	x[x == ""] <- "0"
	x
}

# Create a punctuation-insensitive normalized sample identifier.
normalize_sample_id_compact <- function(x) {
	gsub("[^a-z0-9]", "", normalize_sample_id(x))
}

# Subset and reorder a per-sample QC frame to match phenotype/txi sample IDs.
subset_qc_df <- function(df, ids) {
	if (is.null(df) || !is.data.frame(df) || nrow(df) == 0) {
		return(df)
	}
	raw_row_ids <- rownames(df)
	if (
		is.null(raw_row_ids) ||
		length(raw_row_ids) == 0 ||
		all(raw_row_ids %in% as.character(seq_len(nrow(df))))
	) {
		if ("Sample" %in% colnames(df)) {
			raw_row_ids <- as.character(df$Sample)
		} else {
			raw_row_ids <- as.character(seq_len(nrow(df)))
		}
	}

	row_ids <- extract_fastq_id(raw_row_ids)
	id_values <- trimws(as.character(ids))
	row_values <- trimws(as.character(row_ids))

	keep <- row_values %in% id_values
	use_normalized_match <- FALSE

	if (!any(keep)) {
		row_norm <- normalize_sample_id(row_values)
		id_norm <- normalize_sample_id(id_values)
		keep <- row_norm %in% id_norm
		use_normalized_match <- any(keep)
		if (!use_normalized_match) {
			row_norm_compact <- normalize_sample_id_compact(row_values)
			id_norm_compact <- normalize_sample_id_compact(id_values)
			keep <- row_norm_compact %in% id_norm_compact
			use_normalized_match <- any(keep)
		}
	}

	out <- df[keep, , drop = FALSE]
	if (nrow(out) == 0) {
		return(out)
	}

	if (use_normalized_match) {
		row_key <- normalize_sample_id(row_values[keep])
		id_key <- normalize_sample_id(id_values)
		if (!any(row_key %in% id_key)) {
			row_key <- normalize_sample_id_compact(row_values[keep])
			id_key <- normalize_sample_id_compact(id_values)
		}
		if (anyDuplicated(row_key)) {
			dedup <- !duplicated(row_key)
			out <- out[dedup, , drop = FALSE]
			row_key <- row_key[dedup]
		}
		rownames(out) <- row_key
		matched_ids <- id_values[id_key %in% row_key]
		ord <- match(id_key[id_key %in% row_key], row_key)
	} else {
		row_key <- row_values[keep]
		id_key <- id_values
		if (anyDuplicated(row_key)) {
			dedup <- !duplicated(row_key)
			out <- out[dedup, , drop = FALSE]
			row_key <- row_key[dedup]
		}
		rownames(out) <- row_key
		matched_ids <- id_key[id_key %in% row_key]
		ord <- match(id_key[id_key %in% row_key], row_key)
	}

	out <- out[ord, , drop = FALSE]
	rownames(out) <- matched_ids
	out
}

# Recursively subset nested QC objects that mix lists and data frames.
subset_qc_object <- function(obj, ids) {
	if (is.data.frame(obj)) {
		return(subset_qc_df(obj, ids))
	}
	if (is.list(obj)) {
		return(lapply(obj, subset_qc_object, ids = ids))
	}
	obj
}

# Align a metric table to QC IDs and coerce its value column to numeric output.
align_metric_output <- function(metric_df, qc_ids, value_col = "values") {
	out <- data.frame(values = rep(NA_real_, length(qc_ids)), row.names = qc_ids)

	if (is.null(metric_df) || !is.data.frame(metric_df) || nrow(metric_df) == 0) {
		return(out)
	}
	if (!value_col %in% colnames(metric_df)) {
		return(out)
	}

	src_ids <- if ("Sample" %in% colnames(metric_df)) {
		as.character(metric_df$Sample)
	} else {
		rownames(metric_df)
	}
	if (is.null(src_ids) || length(src_ids) == 0) {
		src_ids <- as.character(seq_len(nrow(metric_df)))
	}

	src_ids <- extract_fastq_id(src_ids)
	src_norm <- normalize_sample_id(src_ids)
	qc_norm <- normalize_sample_id(qc_ids)
	if (!any(qc_norm %in% src_norm)) {
		src_norm <- normalize_sample_id_compact(src_ids)
		qc_norm <- normalize_sample_id_compact(qc_ids)
	}

	vals <- suppressWarnings(as.numeric(metric_df[[value_col]]))
	idx <- match(qc_norm, src_norm)
	out$values <- vals[idx]
	out
}

# Recover paired trimmed R1/R2 rows from mixed FastQC-like tables after fallback matching.
extract_trimmed_pairs <- function(df) {
	empty <- data.frame()
	if (is.null(df) || !is.data.frame(df) || nrow(df) == 0) {
		return(list(trimmed_r1 = empty, trimmed_r2 = empty))
	}

	if (!"Sample" %in% colnames(df) && ncol(df) > 2) {
		axis_vals <- as.character(df[[1]])
		axis_vals <- trimws(gsub('^"|"$', "", axis_vals))
		data_part <- df[, -1, drop = FALSE]
		col_ids <- trimws(gsub('^"|"$', "", colnames(data_part)))
		looks_like_sample_cols <- any(grepl("\\|", col_ids)) ||
			any(grepl("(\\.R1|\\.R2|_R1|_R2)", col_ids))
		if (looks_like_sample_cols && nrow(data_part) > 0) {
			transposed <- as.data.frame(t(as.matrix(data_part)), stringsAsFactors = FALSE)
			feature_names <- make.unique(ifelse(nzchar(axis_vals), axis_vals, as.character(seq_along(axis_vals))))
			colnames(transposed) <- feature_names
			transposed$Sample <- col_ids
			df <- transposed
		}
	}

	sample_labels <- if ("Sample" %in% colnames(df)) {
		as.character(df$Sample)
	} else {
		rownames(df)
	}
	if (is.null(sample_labels) || length(sample_labels) == 0) {
		sample_labels <- as.character(seq_len(nrow(df)))
	}
	sample_labels <- trimws(as.character(sample_labels))
	sample_labels <- gsub('^"|"$', "", sample_labels)

	is_unpaired <- grepl("\\.unpaired$", sample_labels)
	is_trimmed <- grepl("trimmed", sample_labels, ignore.case = TRUE)
	is_r1 <- grepl("(\\.R1|_R1)(\\.unpaired)?$", sample_labels)
	is_r2 <- grepl("(\\.R2|_R2)(\\.unpaired)?$", sample_labels)

	r1_mask <- is_trimmed & is_r1 & !is_unpaired
	r2_mask <- is_trimmed & is_r2 & !is_unpaired

	r1 <- df[r1_mask, , drop = FALSE]
	r2 <- df[r2_mask, , drop = FALSE]
	if (nrow(r1) > 0) {
		rownames(r1) <- make.unique(extract_fastq_id(sample_labels[r1_mask]))
	}
	if (nrow(r2) > 0) {
		rownames(r2) <- make.unique(extract_fastq_id(sample_labels[r2_mask]))
	}

	list(trimmed_r1 = r1, trimmed_r2 = r2)
}

# Capture a metric failure without terminating the full QC workflow.
collect_metric <- function(expr, metric_name) {
	tryCatch(
		expr,
		error = function(e) {
			logr::log_print(
				paste0("Skipping metric ", metric_name, " due to error: ", e$message),
				console = FALSE
			)
			NULL
		}
	)
}

# Standardize FASTQ-derived tables into trim/read-orientation partitions.
split_by_trim_status <- function(df) {
	if (is.null(df) || !is.data.frame(df) || nrow(df) == 0) {
		return(list(
			untrimmed_r1 = df,
			untrimmed_r2 = df,
			trimmed_r1 = df,
			trimmed_r2 = df,
			unpaired_r1 = df,
			unpaired_r2 = df
		))
	}

	if (!"Sample" %in% colnames(df) && ncol(df) > 2) {
		axis_vals <- as.character(df[[1]])
		axis_vals <- trimws(gsub('^"|"$', "", axis_vals))
		data_part <- df[, -1, drop = FALSE]
		col_ids <- trimws(gsub('^"|"$', "", colnames(data_part)))

		looks_like_sample_cols <- any(grepl("\\|", col_ids, fixed = FALSE)) ||
			any(grepl("(\\.R1|\\.R2|_R1|_R2)", col_ids))

		if (looks_like_sample_cols && nrow(data_part) > 0) {
			transposed <- as.data.frame(t(as.matrix(data_part)), stringsAsFactors = FALSE)
			feature_names <- make.unique(ifelse(nzchar(axis_vals), axis_vals, as.character(seq_along(axis_vals))))
			colnames(transposed) <- feature_names
			transposed$Sample <- col_ids
			df <- transposed
		}
	}

	id_src <- if ("Sample" %in% colnames(df)) {
		as.character(df$Sample)
	} else {
		rownames(df)
	}

	if (is.null(id_src) || length(id_src) == 0) {
		id_src <- as.character(seq_len(nrow(df)))
	}

	id_src <- trimws(as.character(id_src))
	id_src <- gsub('^"|"$', "", id_src)
	is_r1 <- grepl("(\\.R1|_R1)(\\.unpaired)?$", id_src)
	is_r2 <- grepl("(\\.R2|_R2)(\\.unpaired)?$", id_src)
	is_unpaired <- grepl("\\.unpaired$", id_src)
	is_trimmed <- grepl("trimmed", id_src, ignore.case = TRUE)

	out <- list(
		untrimmed_r1 = df[is_r1 & !is_trimmed, , drop = FALSE],
		untrimmed_r2 = df[is_r2 & !is_trimmed, , drop = FALSE],
		trimmed_r1 = df[is_r1 & is_trimmed & !is_unpaired, , drop = FALSE],
		trimmed_r2 = df[is_r2 & is_trimmed & !is_unpaired, , drop = FALSE],
		unpaired_r1 = df[is_r1 & is_unpaired, , drop = FALSE],
		unpaired_r2 = df[is_r2 & is_unpaired, , drop = FALSE]
	)

	for (nm in names(out)) {
		if (nrow(out[[nm]]) > 0) {
			row_ids <- extract_fastq_id(if (
				"Sample" %in% colnames(out[[nm]])
			) as.character(out[[nm]]$Sample) else rownames(out[[nm]]))
			rownames(out[[nm]]) <- make.unique(row_ids)
		}
	}

	out
}

# Recover FastQC rows using explicit labels and normalized sample identifiers.
recover_fastqc_subset <- function(df, ids) {
	if (is.null(df) || !is.data.frame(df) || nrow(df) == 0) {
		return(df)
	}
	raw_ids <- if ("Sample" %in% colnames(df)) as.character(df$Sample) else rownames(df)
	row_ids <- extract_fastq_id(raw_ids)
	row_values <- trimws(as.character(row_ids))
	id_values <- trimws(as.character(ids))
	keep <- row_values %in% id_values
	use_normalized_match <- FALSE
	if (!any(keep)) {
		row_norm <- normalize_sample_id(row_values)
		id_norm <- normalize_sample_id(id_values)
		keep <- row_norm %in% id_norm
		use_normalized_match <- any(keep)
		if (!use_normalized_match) {
			row_norm_compact <- normalize_sample_id_compact(row_values)
			id_norm_compact <- normalize_sample_id_compact(id_values)
			keep <- row_norm_compact %in% id_norm_compact
			use_normalized_match <- any(keep)
		}
	}
	out <- df[keep, , drop = FALSE]
	if (nrow(out) == 0) {
		return(out)
	}
	if (use_normalized_match) {
		row_key <- normalize_sample_id(row_values[keep])
		id_key <- normalize_sample_id(id_values)
		if (!any(row_key %in% id_key)) {
			row_key <- normalize_sample_id_compact(row_values[keep])
			id_key <- normalize_sample_id_compact(id_values)
		}
		if (anyDuplicated(row_key)) {
			dedup <- !duplicated(row_key)
			out <- out[dedup, , drop = FALSE]
			row_key <- row_key[dedup]
		}
		rownames(out) <- row_key
		matched_ids <- id_values[id_key %in% row_key]
		ord <- match(id_key[id_key %in% row_key], row_key)
	} else {
		row_key <- row_values[keep]
		if (anyDuplicated(row_key)) {
			dedup <- !duplicated(row_key)
			out <- out[dedup, , drop = FALSE]
			row_key <- row_key[dedup]
		}
		rownames(out) <- row_key
		matched_ids <- id_values[id_values %in% row_key]
		ord <- match(id_values[id_values %in% row_key], row_key)
	}
	out <- out[ord, , drop = FALSE]
	rownames(out) <- matched_ids
	out
}

# Build a PCA patch over selected samples and configured group variables.
build_pca_patch <- function(sample_ids_subset = NULL,
		group_vars = get("group_vars", parent.frame()),
		pheno_data = get("pheno_data", parent.frame()),
		dds_vst = get("dds_vst", parent.frame()),
		sex_col = get("sex_col", parent.frame())) {
	available_group_vars <- group_vars[group_vars %in% colnames(pheno_data)]
	if ("mitochondrial_mapping_rate" %in% colnames(pheno_data) &&
		!"mitochondrial_mapping_rate" %in% available_group_vars) {
		available_group_vars <- c(available_group_vars, "mitochondrial_mapping_rate")
	}
	if (length(available_group_vars) == 0) {
		logr::log_print(
			"Skipping PCA because none of the provided --group_vars are present in phenotype data.",
			console = FALSE
		)
		return(NULL)
	}

	assay_mat_full <- SummarizedExperiment::assay(dds_vst)
	if (is.null(sample_ids_subset)) {
		sample_keep <- colnames(assay_mat_full)
	} else {
		sample_keep <- intersect(colnames(assay_mat_full), as.character(sample_ids_subset))
	}

	if (length(sample_keep) < 3) {
		logr::log_print(
			paste0("Skipping PCA because fewer than 3 samples are available after filtering (n=", length(sample_keep), ")."),
			console = FALSE
		)
		return(NULL)
	}

	assay_mat <- assay_mat_full[, sample_keep, drop = FALSE]
	row_vars <- matrixStats::rowVars(assay_mat)
	keeper_rows <- order(row_vars, decreasing = TRUE)[seq_len(min(20000, length(row_vars)))]
	pca <- prcomp(
		t(assay_mat[keeper_rows, , drop = FALSE]),
		center = TRUE,
		scale. = FALSE
	)
	pct_var <- pca$sdev^2 / sum(pca$sdev^2)
	x_title <- paste0("PC1: ", round(pct_var[1] * 100), "% variance")
	y_title <- paste0("PC2: ", round(pct_var[2] * 100), "% variance")

	plot_data_base <- data.frame(
		PC1 = pca$x[, 1],
		PC2 = pca$x[, 2],
		sample_id = sample_keep,
		stringsAsFactors = FALSE
	)

	p_list <- list()

	for (gv in available_group_vars) {
		p_tmp <- tryCatch(
			{
				plot_df <- plot_data_base
				group_values <- as.vector(SummarizedExperiment::colData(dds_vst)[sample_keep, gv, drop = TRUE])
				plot_df$group <- group_values

				if (all(is.na(plot_df$group))) {
					stop("all values are NA")
				}

				p <- ggplot2::ggplot(
					plot_df,
					ggplot2::aes(x = PC1, y = PC2, fill = group)
				) +
					ggplot2::geom_point(size = 3, alpha = 1, shape = 21, color = "white") +
					ggplot2::labs(x = x_title, y = y_title, fill = gv, title = gv) +
					ggplot2::theme(
						plot.margin = grid::unit(c(0.5, 0.5, 0.5, 0.5), units = "cm"),
						title = ggplot2::element_text(size = 18),
						axis.text = ggplot2::element_text(size = 18),
						axis.title = ggplot2::element_text(size = 18),
						axis.title.y = ggplot2::element_text(vjust = 3),
						axis.title.x = ggplot2::element_text(vjust = -1),
						legend.title = ggplot2::element_text(size = 16),
						legend.text = ggplot2::element_text(size = 16)
					)

				data_min <- min(plot_df$PC1, plot_df$PC2, na.rm = TRUE)
				data_max <- max(plot_df$PC1, plot_df$PC2, na.rm = TRUE)
				if (is.finite(data_min) && is.finite(data_max)) {
					axis_min <- switch(
						as.character(sign(data_min)),
						`-1` = data_min * 1.05,
						`1` = data_min * 0.95,
						`0` = data_min - (diff(c(data_min, data_max)) * 0.05)
					)
					axis_max <- switch(
						as.character(sign(data_max)),
						`-1` = data_max * 0.95,
						`1` = data_max * 1.05,
						`0` = data_max + (diff(c(data_min, data_max)) * 0.05)
					)
					p <- p + ggplot2::xlim(axis_min, axis_max) + ggplot2::ylim(axis_min, axis_max)
				}

				if (is.numeric(plot_df$group) || is.integer(plot_df$group)) {
					p + ggplot2::scale_fill_gradient(
						low = "khaki1",
						high = "red4",
						na.value = "grey80"
					)
				} else {
					plot_df$group <- as.factor(plot_df$group)
					n_lvls <- nlevels(plot_df$group)
					p <- ggplot2::ggplot(
						plot_df,
						ggplot2::aes(x = PC1, y = PC2, fill = group)
					) +
						ggplot2::geom_point(size = 3, alpha = 1, shape = 21, color = "white") +
						ggplot2::labs(x = x_title, y = y_title, fill = gv, title = gv) +
						ggplot2::theme(
							plot.margin = grid::unit(c(0.5, 0.5, 0.5, 0.5), units = "cm"),
							title = ggplot2::element_text(size = 18),
							axis.text = ggplot2::element_text(size = 18),
							axis.title = ggplot2::element_text(size = 18),
							axis.title.y = ggplot2::element_text(vjust = 3),
							axis.title.x = ggplot2::element_text(vjust = -1),
							legend.title = ggplot2::element_text(size = 16),
							legend.text = ggplot2::element_text(size = 16)
						)

					if (is.finite(data_min) && is.finite(data_max)) {
						axis_min <- switch(
							as.character(sign(data_min)),
							`-1` = data_min * 1.05,
							`1` = data_min * 0.95,
							`0` = data_min - (diff(c(data_min, data_max)) * 0.05)
						)
						axis_max <- switch(
							as.character(sign(data_max)),
							`-1` = data_max * 0.95,
							`1` = data_max * 1.05,
							`0` = data_max + (diff(c(data_min, data_max)) * 0.05)
						)
						p <- p + ggplot2::xlim(axis_min, axis_max) + ggplot2::ylim(axis_min, axis_max)
					}

					if (n_lvls <= 8) {
						p + ggplot2::scale_fill_brewer(palette = ifelse(gv %in% c(sex_col, "Race"), "Dark2", "Set2"), na.value = "grey80")
					} else {
						p + ggplot2::scale_fill_hue(na.value = "grey80")
					}
				}
			},
			error = function(e) {
				logr::log_print(
					paste0("Skipping PCA group var '", gv, "' due to error: ", e$message),
					console = FALSE
				)
				NULL
			}
		)

		if (!is.null(p_tmp)) {
			p_list[[length(p_list) + 1]] <- p_tmp
		}
	}

	if (length(p_list) == 0) {
		logr::log_print("All PCA group variables were skipped; no PCA plot generated.", console = FALSE)
		return(NULL)
	}

	patchwork::wrap_plots(p_list, ncol = 2)
}

# Resolve numeric metric vectors with fallback column names for format drift across tools.
get_metric_numeric <- function(df, primary_col, fallback_cols = character(0)) {
	col_candidates <- c(primary_col, fallback_cols)
	col_candidates <- col_candidates[col_candidates %in% colnames(df)]
	if (length(col_candidates) == 0) {
		logr::log_print(
			paste0("Threshold metric column not found: ", primary_col),
			console = FALSE
		)
		return(rep(NA_real_, nrow(df)))
	}
	x <- df[[col_candidates[1]]]
	if (is.factor(x)) {
		x <- as.character(x)
	}
	if (is.character(x)) {
		x <- gsub("%", "", x, fixed = TRUE)
		x <- gsub(",", "", x, fixed = TRUE)
	}
	suppressWarnings(as.numeric(x))
}

# Minimal escaping helper so report tables are safe to embed in HTML.
html_escape <- function(x) {
	x <- as.character(x)
	x <- gsub("&", "&amp;", x, fixed = TRUE)
	x <- gsub("<", "&lt;", x, fixed = TRUE)
	x <- gsub(">", "&gt;", x, fixed = TRUE)
	x <- gsub('"', "&quot;", x, fixed = TRUE)
	x
}

# Render data frames as lightweight HTML tables for in-report summaries.
df_to_html_table <- function(df, max_rows = NULL) {
	if (is.null(df) || nrow(df) == 0) {
		return("<p>No rows available.</p>")
	}
	if (!is.null(max_rows)) {
		df <- utils::head(df, max_rows)
	}
	head_html <- paste0(
		"<tr>",
		paste0("<th>", html_escape(colnames(df)), "</th>", collapse = ""),
		"</tr>"
	)
	body_html <- apply(df, 1, function(r) {
		paste0(
			"<tr>",
			paste0("<td>", html_escape(r), "</td>", collapse = ""),
			"</tr>"
		)
	})
	paste0(
		"<table class='qc-table'><thead>",
		head_html,
		"</thead><tbody>",
		paste(body_html, collapse = "\n"),
		"</tbody></table>"
	)
}

markdown_escape <- function(x) {
	x <- as.character(x)
	x[is.na(x)] <- "NA"
	x <- gsub("|", "\\\\|", x, fixed = TRUE)
	x <- gsub("\r?\n", " ", x)
	x
}

df_to_markdown_table <- function(df, max_rows = NULL) {
	if (is.null(df) || nrow(df) == 0) {
		return("_No rows available._")
	}
	if (!is.null(max_rows)) {
		df <- utils::head(df, max_rows)
	}
	header <- paste0("| ", paste(markdown_escape(colnames(df)), collapse = " | "), " |")
	separator <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
	body <- apply(df, 1, function(row_values) {
		paste0("| ", paste(markdown_escape(row_values), collapse = " | "), " |")
	})
	paste(c(header, separator, body), collapse = "\n")
}
