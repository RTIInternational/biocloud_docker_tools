`%||%` <- function(x, y) {
	if (!is.null(x)) x else y
}

safe_read_tsv <- function(path) {
	if (!file.exists(path)) {
		stop(paste("Missing required file:", path))
	}
	utils::read.table(
		path,
		sep = "\t",
		header = TRUE,
		check.names = FALSE,
		quote = "",
		comment.char = "",
		stringsAsFactors = FALSE,
		fill = TRUE
	)
}

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

get_sample_column <- function(df) {
	cn <- colnames(df)
	cand <- cn[grepl("^(sample|samplename|sample_name)$", cn, ignore.case = TRUE)]
	if (length(cand) > 0) {
		return(cand[1])
	}
	NULL
}

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
