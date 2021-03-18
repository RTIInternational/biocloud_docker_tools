# Modified from https://github.com/broadinstitute/gtex-pipeline/blob/master/qtl/src/run_PEER.R
# Original Author: Francois Aguet
# Modified by: Bryan Quach <bquach@rti.org>

library(peer, quietly = T)
library(optparse, quietly = T)
peer.version <- 1.3 #software version

WriteTable <- function(data, filename, index.name) {
    datafile <- file(filename, open = "wt")
    on.exit(close(datafile))
    header <- c(index.name, colnames(data))
    writeLines(paste0(header, collapse = "\t"), con = datafile, sep = "\n")
    write.table(data, datafile, sep = "\t", col.names = F, quote = F)
}

# Generate usage doc and retrieve command line args
p <- OptionParser(usage = "\n%prog [options] --omic_data file <omic_data_file> --output_prefix <output_prefix> --num_factors <num_factors>",
    description = "\nProbabilistic Estimation of Expression Residuals (PEER)\n\nRun PEER using the R interface. PEER is a method designed to estimate surrogate variables/latent factors/hidden factors that contribute to gene expression variability, but it can be applied to other data types as well. For more information, please refer to https://doi.org/10.1038/nprot.2011.457.",
    prog = "Rscript run_peer.R")
p <- add_option(object = p, opt_str = c("--omic_data_file"), default = NULL, type = "character",
    help = "[REQUIRED] A tab delimited file with .tab file extension containing N + 1 rows and G + 1 columns, where N is the number of samples, and G is the number of features (genes, methylation sites, chromatin accessibility windows, etc.). The first row and column must contain sample IDs and feature IDs respectively. Feature values should be normalized across samples and variance stabilized.")
p <- add_option(object = p, opt_str = c("--output_prefix"), default = NULL, type = "character",
    help = "[REQUIRED] File name prefix for output files. To specify an output directory as well, use --output_dir.")
p <- add_option(object = p, opt_str = c("--num_factors"), type = "integer", default = NULL,
    help = "[REQUIRED] Number of hidden factors to estimate. PEER uses automatic relevance determination to choose a suitable effective number of factors, so this parameter needs only to be set to a sufficiently large value. Without prior information available, a general recommendation is to use 25% of the number of samples but no more than 100 factors.")
p <- add_option(object = p, opt_str = c("--cov_file"), help = "A tab delimited file with a .tab file extension containing a matrix of size M + 1 × C + 1, where M >= N and is the number of samples for which covariate data is provided. If this file is input, the set of samples used in the hidden factor estimation procedure will be the intersection of samples in the covariate matrix and omic data matrix. C is the number of known covariates to be included in association test regression models of downstream analyses. Examples of common covariates include sex, age, batch variables, and quality metrics. Categorical variables (e.g., batch number) have to be encoded as D - 1 indicator/binary variables, where D is the number of categories for a given categorical variable. For the indicator variables, a value of 1 signifies membership in the category and a value of 0 indicates otherwise. The first row and column must contain sample IDs and covariate IDs respectively [default=%default].")
p <- add_option(object = p, opt_str = c("--alphaprior_a"), type = "double", default = 0.001,
    help = "Shape parameter of the gamma distribution prior of the model noise distribution [default=%default].")
p <- add_option(object = p, opt_str = c("--alphaprior_b"), type = "double", default = 0.01,
    help = "Scale parameter of the gamma distribution prior of the model noise distribution. [default=%default]")
p <- add_option(object = p, opt_str = c("--epsprior_a"), type = "double", default = 0.1,
    help = "Shape parameter of the gamma distribution prior of the model weight distribution. [default=%default]")
p <- add_option(object = p, opt_str = c("--epsprior_b"), type = "double", default = 10,
    help = "Scale parameter of the gamma distribution prior of the model weight distribution. [default=%default]")
p <- add_option(object = p, opt_str = c("--tol"), type = "double", default = 0.001,
    help = "Threshold for the increase in model evidence when optimizing hidden factor values. Estimation completes for a hidden factor when the increase in model evidence exceeds this value [default=%default].")
p <- add_option(object = p, opt_str = c("--var_tol"), type = "double", default = 0.00001,
    help = "Threshold for the variance of model residuals when optimizing hidden factor values. Estimation completes for a hidden factor when the variance of residuals is smaller than this value [default=%default].")
p <- add_option(object = p, opt_str = c("--max_iter"), type = "double", default = 1000,
    help = "Max number of iterations for updating values of each hidden factor [default=%default].")
p <- add_option(object = p, opt_str = c("--output_dir", "-o"), default = ".",
    help = "Directory in which to save outputs [default=%default].")
p <- add_option(object = p, opt_str = c("--version", "-v"), action = "store_true", default = F, 
    help = "Print PEER version number.")
argv <- parse_args(p)

# Quick execution for printing version number
if(argv$version){
    cat(paste0("PEER v", peer.version))
    quit(save = "no")
}

# Check if positional arguments were given 
if(is.null(argv$omic_data_file)){
    stop("Error: Please provide a value for --omic_data_file")
}
if(is.null(argv$output_prefix)){
    stop("Error: Please provide a value for --output_prefix")
}
if(is.null(argv$num_factors)){
    stop("Error: Please provide a value for --num_factors")
}


# Check validity of argument inputs
if(!file.exists(argv$omic_data_file)){ 
    stop(paste0("Error: ", argv$omic_data_file, 
        " not found. Check your file path and name.")) 
}
if(!grepl(x = argv$omic_data_file, pattern = "\\.tab$", perl = T)){ 
    stop("Error: --omic_data_file requires .tab extension.")
}
if(!is.null(argv$cov_file) && !file.exists(argv$cov_file)){ 
    stop(paste0("Error: ", argv$cov_file, 
        " not found. Check your file path and name.")) 
}
if(!is.null(argv$cov_file) &&
    !grepl(x = argv$cov_file, pattern = "\\.tab$", perl = T)){ 
    stop("Error: --cov_file requires .tab extension.")
}
if(is.na(argv$num_factors) | argv$num_factors <= 0 | 
   !is.finite(argv$num_factors) | argv$num_factors != as.integer(argv$num_factors)){ 
    stop(paste0("Error: Please provide a valid number for 'num_factors'. Use --help for more details."))
}
if(argv$max_iter <= 0 | !is.finite(argv$max_iter) | 
   argv$max_iter != as.integer(argv$max_iter)){ 
    stop(paste0("Error: Please provide a valid number for --max_iter. Use --help for more details."))
}
if(argv$tol <= 0 | !is.finite(argv$tol)){ 
    stop(paste0("Error: Please provide a valid value for --tol. Use --help for more details."))
}
if(argv$var_tol <= 0 | !is.finite(argv$var_tol)){ 
    stop(paste0("Error: Please provide a valid value for --var_tol. Use --help for more details."))
}
if(argv$alphaprior_a < 0 | !is.finite(argv$alphaprior_a)){ 
    stop(paste0("Error: Please provide a valid value for --alphaprior_a. Use --help for more details."))
}
if(argv$alphaprior_b < 0 | !is.finite(argv$alphaprior_b)){ 
    stop(paste0("Error: Please provide a valid value for --alphaprior_b. Use --help for more details."))
}
if(argv$epsprior_a < 0 | !is.finite(argv$epsprior_a)){ 
    stop(paste0("Error: Please provide a valid value for --epsprior_a. Use --help for more details."))
}
if(argv$epsprior_b < 0 | !is.finite(argv$epsprior_b)){ 
    stop(paste0("Error: Please provide a valid value for --epsprior_b. Use --help for more details."))
}

# Create output directory if needed
dir.create(argv$output_dir, showWarnings = F)

# Load omic data
cat(paste0("Loading data from ", argv$omic_data_file, " ..."))
omic.data <- read.table(argv$omic_data_file, sep = "\t", header = T, 
    check.names = F, comment.char = "", row.names = 1)
omic.data <- as.matrix(omic.data)
n.samples <- nrow(omic.data)
n.features <- ncol(omic.data)
cat("Done.\n")
cat(paste0("Loaded data matrix with ", n.samples, " rows and ", 
    n.features, " columns.\n"))

# Load covariate data
cov.data <- NULL
if(!is.null(argv$cov_file)){
    cat(paste0("Loading covariate data from ", argv$cov_file, " ..."))
    cov.data <- read.table(argv$cov_file, sep = "\t", header = T, as.is = T, 
        check.names = F, comment.char = "", row.names = 1)
    cov.data <- as.matrix(cov.data)
    n.vars <- ncol(cov.data)
    cat("Done.\n")
    cat(paste0("Loaded ", n.vars, " covariates.\n"))
    # Subset and match rows between covariate and omic data matrix
    cov.subset <- cov.data[rownames(cov.data) %in% rownames(omic.data), , drop = F]
    omic.subset <- omic.data[rownames(omic.data) %in% rownames(cov.subset), , drop = F]
    match.order <- match(rownames(cov.subset), table = rownames(omic.subset))
    cov.subset <- cov.subset[match.order, , drop = F]
    if(nrow(omic.subset) < nrow(omic.data)){
        cat(paste0("Data reduced to ", nrow(omic.subset), 
        " samples after matching with covariate data.\n"))
    }
    omic.data <- omic.subset
    cov.data <- cov.subset
}

# Set method parameters
cat(paste0("Setting initialization parameters ..."))
model <- PEER()
invisible(PEER_setNk(model, argv$num_factors))
invisible(PEER_setPhenoMean(model, omic.data))
invisible(PEER_setPriorAlpha(model, argv$alphaprior_a, argv$alphaprior_b))
invisible(PEER_setPriorEps(model, argv$epsprior_a, argv$epsprior_b))
invisible(PEER_setTolerance(model, argv$tol))
invisible(PEER_setVarTolerance(model, argv$var_tol))
invisible(PEER_setNmax_iterations(model, argv$max_iter))
if(!is.null(cov.data)){
    invisible(PEER_setCovariates(model, cov.data))
}
cat("Done.\n")

# Run inference routine
cat(paste0("Beginning estimation of ", argv$num_factors, " hidden factors.\n"))
time <- system.time(PEER_update(model))
cat("Finished estimation procedure.\n")
cat(paste0("Hidden factor estimation completed in ", round(time[3], 2) , " seconds (", round(time[3]/60, 2) ," minutes).\n"))

# Retrieve results
factor.mat <- PEER_getX(model)  # samples x PEER factors
weight.mat <- PEER_getW(model)  # omic features x PEER factors
precision.mat <- PEER_getAlpha(model)  # PEER factors x 1
resid.mat <- t(PEER_getResiduals(model))  # omic features x samples

# Add relevant row/column names
peer.var.names <- paste0("peer.factor", 1:ncol(factor.mat))
rownames(factor.mat) <- rownames(omic.data)
colnames(factor.mat) <- peer.var.names
colnames(weight.mat) <- peer.var.names
rownames(weight.mat) <- colnames(omic.data)
rownames(precision.mat) <- peer.var.names
colnames(precision.mat) <- "alpha"
precision.mat <- as.data.frame(precision.mat)
precision.mat$relevance <- 1.0 / precision.mat$alpha
rownames(resid.mat) <- colnames(omic.data)
colnames(resid.mat) <- rownames(omic.data)

# Write results
cat("Exporting results ... ")
WriteTable(t(factor.mat), file.path(argv$output_dir, paste0(argv$output_prefix, "_peer_covariates.txt")), "ID")  
WriteTable(weight.mat, file.path(argv$output_dir, paste0(argv$output_prefix, "_peer_weights.txt")), "ID")
WriteTable(precision.mat, file.path(argv$output_dir, paste0(argv$output_prefix, "_peer_precisions.txt")), "ID")
WriteTable(resid.mat, file.path(argv$output_dir, paste0(argv$output_prefix, "_peer_residuals.txt")), "ID")
cat("Done.\n")
