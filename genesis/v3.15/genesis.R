#!/usr/local/bin/Rscript

library(GENESIS)
library(GWASTools)
library(R.utils)
library(optparse)

option_list = list(
    make_option(
        c('--file-geno'),
        action='store',
        default=NULL,
        type='character',
        help="Path to genotype file (required)"
    ),
    make_option(
        c('--geno-format'),
        action='store',
        default=NULL,
        type='character',
        help="Format of genotype file (required)"
    ),
    make_option(
        c('--file-pheno'),
        action='store',
        default=NULL,
        type='character',
        help="Path to phenotype file (required)"
    ),
    make_option(
        c('--file-out'),
        action='store',
        default=NULL,
        type='character',
        help="Path to output file (required)"
    ),
    make_option(
        c('--pheno'),
        action='store',
        default=NULL,
        type='character',
        help="Phenotype for model (required)"
    ),
    make_option(
        c('--family'),
        action='store',
        default=NULL,
        type='character',
        help="Error distribution to be used in the model (required)"
    ),
    make_option(
        c('--chr'),
        action='store',
        default=NULL,
        type='character',
        help="Label to use for chromosome being analyzed (optional)"
    ),
    make_option(
        c('--covars'),
        action='store',
        default=NULL,
        type='character',
        help="Covariates for model (comma-separated, optional)"
    ),
    make_option(
        c('--gxe'),
        action='store',
        default=NULL,
        type='character',
        help="Covariate to use for GxE interaction (optional)"
    ),
    make_option(
        c('--file-variant-list'),
        action='store',
        default=NULL,
        type='character',
        help="Path to list of variants to analyze (optional)"
    ),
    make_option(
        c('--grm'),
        action='store_true',
        default=FALSE,
        help="Flag indicating that GRM should be used in model (optional)"
    ),
    make_option(
        c('--grm-pc-cols'),
        action='store',
        default=NULL,
        type='character',
        help="PC columns to use for GRM calculation (comma-separated, optional)"
    )
)

getArg = function(parameter) {
    return(args[parameter][[1]])
}

checkForRequiredArgs = function(args) {
    requiredArgs = c(
        'file-geno',
        'geno-format',
        'file-pheno',
        'file-out',
        'pheno',
        'family'
    )
    for (arg in requiredArgs) {
        if (is.null(getArg(arg))) {
            stop(paste0('Required argument --', arg, ' is missing'))
        }
    }
    if (getArg("grm")) {
        if (is.null(getArg('grm-pc-cols'))) {
            stop('When -grm is specified, --grm-pc-cols is a required argument')
        }
    }
}

args = parse_args(OptionParser(option_list=option_list))
checkForRequiredArgs(args)
cat("Arguments:\n")
str(args)

# Read phenotype data
pheno = read.table(
    getArg("file-pheno"),
    header = TRUE
)

# Convert phenotype data to ScanAnnotationDataFrame
phenoScanAnnot = ScanAnnotationDataFrame(pheno)

# Read genotype data
if (getArg("geno-format") == "gds") {
    geno <- GdsGenotypeReader(
        getArg("file-geno")
    )
}
genoData <- GenotypeData(geno)

# Generate GRM
grm = NULL
if (getArg("grm")) {
    # Create genotype iterator
    genoIterator = GenotypeBlockIterator(
        genoData,
        snpBlock=500
    )
    cols = c('scanID', strsplit(getArg("grm-pc-cols"), ",")[[1]])
    pcs = as.matrix(pheno[, cols])
    rownames(pcs) = pcs[, 'scanID']
    pcs = pcs[,-1]
    pcRelateOutput = pcrelate (
        genoIterator,
        pcs,
        scale = 'overall',
        sample.include = pheno[ , 'scanID']
    )
    grm = pcrelateToMatrix(pcRelateOutput)
}

# Fit the null model
if (is.null(getArg('covars'))) {
    nullmod = fitNullModel(
        phenoScanAnnot,
        outcome = getArg("pheno"),
        family = getArg("family"),
        cov.mat = grm
    )
} else {
    nullmod = fitNullModel(
        phenoScanAnnot,
        outcome = getArg("pheno"),
        covars = strsplit(getArg("covars"), ",")[[1]],
        family = getArg("family"),
        cov.mat = grm
    )
}

# Create genotype iterator
snpInclude = NULL
if (!is.null(getArg("file-variant-list"))) {
    snpInclude = read.table(
        getArg("file-variant-list"),
        header = FALSE,
        stringsAsFactors = FALSE
    )
    snpInclude = snpInclude$V1
}
genoIterator = GenotypeBlockIterator(
    genoData,
    snpBlock=500,
    snpInclude = snpInclude
)

# Run association testing
assoc = assocTestSingle(
    genoIterator,
    null.model = nullmod,
    GxE = getArg("gxe")
)

# Add alleles to results
## Need to confirm that this is correct (alt vs. ref)
assoc$alt = getAlleleA(geno, assoc$variant.id)
assoc$ref = getAlleleB(geno, assoc$variant.id)

# Close iterator
close(genoIterator)

# Fix chr
assoc$chr = toString(assoc$chr)
if (!is.null(getArg("chr"))) {
    assoc$chr = getArg("chr")
}

# Reorder columns
colOrder = c(
    colnames(assoc)[1:3],
    "ref",
    "alt",
    colnames(assoc)[4:(ncol(assoc)-2)]
)

# Write results
write.table(
    assoc[,colOrder],
    file = getArg("file-out"),
    row.names = FALSE,
    quote = FALSE,
    sep = "\t"
)
