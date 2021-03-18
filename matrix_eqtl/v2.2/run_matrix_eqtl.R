library(MatrixEQTL, quietly = T)
library(optparse, quietly = T)
options(stringsAsFactors = F)
version <- 2.2 #software version

# Generate usage doc and retrieve command line args
p <- OptionParser(usage = "\n%prog [options] --omic_data_file <omic_data_file> --snp_file <snp_file> --output_prefix <output_prefix> --model <model>",
    description = "Matrix eQTL\n\nRun Matrix eQTL. Matrix eQTL is an R package designed for efficient QTL analysis of RNA expression phenotypes, but it can be applied to other molecular data types as well. For more information, please refer to https://doi.org/10.1093/bioinformatics/bts163.",
    prog = "Rscript /opt/run_matrix_eqtl.R")
p <- add_option(object = p, opt_str = c("--omic_data_file"), default = NULL, type = "character",
    help = "[REQUIRED] A tab delimited file containing N + 1 columns and G + 1 rows, where N is the number of samples, and G is the number of features (genes, methylation sites, chromatin accessibility windows, etc.). The first row and column must contain sample IDs and feature IDs respectively. Feature values should be normalized across samples.")
p <- add_option(object = p, opt_str = c("--snp_file"), default = NULL, type = "character",
    help = "[REQUIRED] A tab delimited file containing N + 1 columns and V + 1 rows, where N is the number of samples, and V is the number of DNA variants. The first row and column must contain sample IDs and variant IDs respectively. The column sample ID order should match --omic_data_file.")
p <- add_option(object = p, opt_str = c("--output_prefix"), default = NULL, type = "character",
    help = "[REQUIRED] File name prefix for output files. To specify an output directory as well, use --output_dir.")
p <- add_option(object = p, opt_str = c("--model"), type = "character", default = NULL,
    help = "[REQUIRED] Type of regression model to use for model fitting. Must be one of \"linear\", \"anova\", or \"interaction\". The option \"linear\" assumes linear additive genotypic effects. The option \"anova\" treats genotypes as categorical variables. If \"interaction\" is specified, the interaction term will be the DNA variant and the last covariate term in --cov_file.")
p <- add_option(object = p, opt_str = c("--omic_coordinates_file"), default = NULL, type = "character",
    help = "A tab delimited file containing G + 1 rows and 4 columns. G is equal to the number of omic features in --omic_data_file. The first row consists of ordered column labels that respectively correspond to the omic feature IDs, feature chromosome (e.g., chr1), start position, and end position. Required if running a cis-eQTL analysis.")
p <- add_option(object = p, opt_str = c("--snp_coordinates_file"), default = NULL, type = "character",
    help = "A tab delimited file containing V + 1 rows and 4 columns. V is equal to the number of DNA variants in --snp_file. The first row consists of ordered column labels. These columns respectively correspond to the variant IDs, variant chromosome (e.g., chr1), and start position. Required if running a cis-eQTL analysis.")
p <- add_option(object = p, opt_str = c("--cov_file"), default = NULL, type = "character", help = "A tab delimited file containing a matrix of size C + 1 × N + 1, where C is the number of model covariates and N is the number of samples. Categorical variables (e.g., batch number) have to be encoded as D - 1 indicator/binary variables, where D is the number of categories for a given categorical variable. For the indicator variables, a value of 1 signifies membership in the category and a value of 0 indicates otherwise. The first row and column must contain sample IDs and covariate IDs respectively. The column sample ID order should match --omic_data_file [default=%default].")
p <- add_option(object = p, opt_str = c("--pval_threshold"), type = "double", default = 1.0,
    help = "The max p-value for which to report results [default=%default].")
p <- add_option(object = p, opt_str = c("--missing_code"), type = "character", default = "NA",
    help = "Character representation of the coding used to represent missing values in the data [default=%default]")
p <- add_option(object = p, opt_str = c("--batch_size"), type = "integer", default = 1000,
    help = "The number of variants and features to store in random access memory at once. Larger values consume more memory but provide improvements in runtime [default=%default].")
p <- add_option(object = p, opt_str = c("--cis"), action = "store_true", default = F,
    help = "Perform a cis-eQTL analysis only [default=%default].")
p <- add_option(object = p, opt_str = c("--cis_size"), type = "integer", default = 1000000,
    help = "Defines the one-sided length in genomic bases of the cis-window around a genomic feature. For example, a 1 Mb cis-window for a gene annotation corresponds to both the 5' and 3' end of a gene being extended by 1 Mb [default=%default].")
p <- add_option(object = p, opt_str = c("--anova_levels"), type = "integer", default = 3,
    help = "The number of categories for the genotype variable if using ANOVA for association testing [default=%default].")
p <- add_option(object = p, opt_str = c("--keep_all_pvals"), action = "store_true", default = F,
    help = "Keep all p-values regardless of --pval_threshold to be used for assessing the p-value distribution [default=%default].")
p <- add_option(object = p, opt_str = c("--no_fdr"), action = "store_true", default = F,
    help = "Skip FDR calculations and save all nominally significant associations [default=%default].")
p <- add_option(object = p, opt_str = c("--output_dir", "-o"), default = ".",
    help = "Directory in which to save outputs [default=%default].")
p <- add_option(object = p, opt_str = c("--normalize"), type = "character", default = "none",
    help = "Apply normalization to the omic data values in --omic_data_file. Must be either \"none\", \"rint\" (for rank inverse-normal transform), or \"log\" (for log10 transform) [default=%default].")
p <- add_option(object = p, opt_str = c("--version", "-v"), action = "store_true", default = F,
    help = "Print version number.")
argv <- parse_args(p)

# Quick execution for printing version number
if(argv$version){
    cat(paste0("Matrix eQTL v", version))
    quit(save = "no")
}

# Check if positional arguments were given
if(is.null(argv$omic_data_file)){
    stop("Error: Please provide a value for --omic_data_file")
}
if(is.null(argv$snp_file)){
    stop("Error: Please provide a value for --snp_file")
}
if(is.null(argv$omic_coordinates_file) && argv$cis){
    stop("Error: Please provide a value for --omic_coordinates_file")
}
if(is.null(argv$snp_coordinates_file) && argv$cis){
    stop("Error: Please provide a value for --snp_coordinates_file")
}
if(is.null(argv$output_prefix)){
    stop("Error: Please provide a value for --output_prefix")
}
if(is.null(argv$model)){
    stop("Error: Please provide a value for --model")
}

# Check validity of argument inputs
if(!file.exists(argv$omic_data_file)){
    stop(paste0("Error: ", argv$omic_data_file,
        " not found. Check your file path and name."))
}
if(!file.exists(argv$snp_file)){
    stop(paste0("Error: ", argv$snp_file,
        " not found. Check your file path and name."))
}
if(is.null(argv$omic_coordinates_file) && argv$cis){
    stop(paste0("Error: ", argv$omic_coordinates_file,
        " not found. Check your file path and name."))
}
if(is.null(argv$snp_coordinates_file) && argv$cis){
    stop(paste0("Error: ", argv$snp_coordinates_file,
        " not found. Check your file path and name."))
}
if(!is.null(argv$omic_coordinates_file) && argv$cis){
    if(!file.exists(argv$omic_coordinates_file)){
        stop(paste0("Error: ", argv$omic_coordinates_file,
            " not found. Check your file path and name."))
    }
}
if(!is.null(argv$snp_coordinates_file) && argv$cis){
    if(!file.exists(argv$snp_coordinates_file)){
        stop(paste0("Error: ", argv$snp_coordinates_file,
            " not found. Check your file path and name."))
    }
}
if(!is.null(argv$cov_file) && !file.exists(argv$cov_file)){
    stop(paste0("Error: ", argv$cov_file,
        " not found. Check your file path and name."))
}
if(!(argv$model %in% c("linear", "anova", "interaction"))){
    stop("Error: --model must be one of \"linear\", \"anova\", or \"interaction\" (case sensitive).")
}
if(!(argv$normalize %in% c("rint", "log", "none"))){
    stop("Error: --model must be one of \"rint\", \"log\", or \"none\" (case sensitive).")
}
if(argv$model == "interaction" && is.null(argv$cov_file)){
    stop(paste0("Error: Interaction model specified but --cov_file not specified. Please provide a covariate file. Use --help for more details."))
}
if(argv$pval_threshold < 0 | argv$pval_threshold > 1){
    stop(paste0("Error: Please provide a valid value for --pval_threshold. Use --help for more details."))
}
if(argv$batch_size <= 0 | !is.finite(argv$batch_size)){
    stop(paste0("Error: Please provide a valid value for --batch_size. Use --help for more details."))
}
if(argv$cis_size <= 0 | !is.finite(argv$cis_size)){
    stop(paste0("Error: Please provide a valid value for --cis_size. Use --help for more details."))
}
if(argv$anova_levels <= 1 | !is.finite(argv$anova_levels)){
    stop(paste0("Error: Please provide a valid value for --anova_levels. Use --help for more details."))
}

# Import data as a SlicedData object.
# 
# Args:
#   - filename: Path and name of file to import.
#   - delim: The file delimiter used.
#   - missing.val: The missing value coding used (as string).
#   - skip.rows: Number of rows in file to skip.
#   - skip.colmns: Number of columns in file to skip.
#   - batch.size: Number of records to pull per batch.
#
# Returns: A SlicedData object.
import.data <- function(filename, 
			delim = "\t", 
		    	missing.val = argv$missing_code, 
		    	skip.rows = 1, 
		    	skip.cols = 1, 
		    	batch.size = argv$batch_size){
    cat(paste0("Loading data from ", filename, " ..."))
    new.data = SlicedData$new();
    new.data$fileDelimiter = delim;
    new.data$fileOmitCharacters = missing.val; 
    new.data$fileSkipRows = skip.rows;          
    new.data$fileSkipColumns = skip.cols;       
    new.data$fileSliceSize = batch.size;
    new.data$LoadFile(filename);
    cat("Done.\n")
    cat(paste0("Loaded data matrix with ", new.data$nRows(), " rows and ",
    new.data$nCols(), " columns.\n"))
    return(new.data)
}

# Apply a rank inverse transform to a data vector
# 
# Args:
#   - data: A numeric vector.
#
# Returns: Rank inverse transformed values of the input vector.
rint <- function(data){
    if(! is.vector(data)){
        stop("Error: Input data is not a vector.")
    }
    zscore <- scale(data)
    rankings <- rank(zscore) - 0.5
    scaled.rank <- rankings / (max(rankings, na.rm = T) + 0.5)
    rint.values <- qnorm(scaled.rank)
    return(rint.values)
}

# Apply normalization to omic data and generate temp file.
#
# Args:
#   - file: Filename of file holding omic data.
#   - method: Normalization function name. Either "rint" or "log".
#
# Returns: Filename of temp file holding normalized data.
normalize <- function(file, method = "rint"){
    pheno.data <- read.table(file, header = T)
    if(method == "rint"){
        pheno.data[,2:ncol(pheno.data)] <- t(apply(pheno.data[,-1], 1, rint))
    }else if(method == "log"){
        pheno.data[,2:ncol(pheno.data)] <- t(apply(pheno.data[,-1], 1, log10))
    }else{
        stop("Error: 'method' must be either 'rint' or 'log10'.")
    }
    dir.create("./tmp", showWarnings = F)
    tmp.file <- tempfile(tmpdir = "tmp", pattern = "omic_data_", fileext = ".txt")
    write.table(pheno.data, file = tmp.file, quote = F, append = F, sep = "\t",
        row.names = F, col.names = T)
    return(tmp.file)
}

# Create output directory if needed
dir.create(argv$output_dir, showWarnings = F)

# Set model type
cat("\nModel type: ", argv$model, "\n")
model.map <- list("linear" = modelLINEAR, 
    "anova" = modelANOVA, 
    "interaction" = modelLINEAR_CROSS)
model.type <- model.map[[argv$model]]

# Set number of ANOVA levels
options(MatrixEQTL.ANOVA.categories = argv$anova_levels)

# Apply phenotype normalization if needed
if(argv$normalize != "none"){
    omic.file <- normalize(argv$omic_data_file, argv$normalize)
}else{
    omic.file <- argv$omic_data_file
}

# Load data
omic.data <- import.data(omic.file)
snp.data <- import.data(argv$snp_file)
if(!is.null(argv$cov_file)){
    cov.data <- import.data(argv$cov_file, skip.cols = 1)
}else{
    cov.data <- SlicedData$new()
}
if(argv$cis){
    omic.coordinates <- read.table(argv$omic_coordinates_file, header = T)
    snp.coordinates <- read.table(argv$snp_coordinates_file, header = T)
}

# Run QTL mappings
if(argv$cis){
    qtl.results = Matrix_eQTL_main(
        snps = snp.data,
        gene = omic.data,
        cvrt = cov.data,
	snpspos = snp.coordinates,
	genepos = omic.coordinates,
	cisDist = argv$cis_size,
        output_file_name = file.path(argv$output_dir, paste0(argv$output_prefix, "_qtl_table.txt")),
        output_file_name.cis = file.path(argv$output_dir, paste0(argv$output_prefix, "_cis_qtl_table.txt")),
        pvOutputThreshold = 0,
        pvOutputThreshold.cis = argv$pval_threshold,
        useModel = model.type, 
        errorCovariance = numeric(), 
        verbose = TRUE,
        pvalue.hist = argv$keep_all_pvals,
        min.pv.by.genesnp = FALSE,
        noFDRsaveMemory = argv$no_fdr)
}else{
    qtl.results = Matrix_eQTL_main(
        snps = snp.data,
        gene = omic.data,
        cvrt = cov.data,
        output_file_name = file.path(argv$output_dir, argv$output_prefix),
        pvOutputThreshold = argv$pval_threshold,
        useModel = model.type, 
        errorCovariance = numeric(), 
        verbose = TRUE,
        pvalue.hist = argv$keep_all_pvals,
        min.pv.by.genesnp = FALSE,
        noFDRsaveMemory = argv$no_fdr)
}

saveRDS(qtl.results, file = file.path(argv$output_dir, paste0(argv$output_prefix, "_qtl_results.rds")))
