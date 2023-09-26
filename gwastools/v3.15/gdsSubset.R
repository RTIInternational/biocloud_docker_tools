#!/usr/local/bin/Rscript

library(GWASTools)
library(optparse)

option_list = list(
    make_option(
        c('--file-in-gds'),
        action='store',
        default=NULL,
        type='character',
        help="Path to input GDS file (required)"
    ),
    make_option(
        c('--file-out-gds'),
        action='store',
        default=NULL,
        type='character',
        help="Path to output GDS file (required)"
    ),
    make_option(
        c('--file-gds-annot'),
        action='store',
        default=NULL,
        type='character',
        help="Path to annotation file for GDS (required)"
    ),
    make_option(
        c('--gds-annot-variant-id-col'),
        action='store',
        default='ID',
        type='character',
        help="Column in GDS annotation file matching variant IDs in --file-variant-list (optional)"
    ),
    make_option(
        c('--file-variant-list'),
        action='store',
        default=NULL,
        type='character',
        help="Path to list of variants to extract (optional)"
    ),
    make_option(
        c('--file-sample-list'),
        action='store',
        default=NULL,
        type='character',
        help="Path to list of samples to extract (optional)"
    )
)

getArg = function(parameter) {
    return(args[parameter][[1]])
}

checkForRequiredArgs = function(args) {
    requiredArgs = c(
        'file-in-gds',
        'file-out-gds',
        'file-gds-annot'
    )
    for (arg in requiredArgs) {
        if (is.null(getArg(arg))) {
            stop(paste0('Required argument --', arg, ' is missing'))
        }
    }
}

args = parse_args(OptionParser(option_list=option_list))
checkForRequiredArgs(args)
cat("Arguments:\n")
str(args)

sampleInclude = read.table(
    "/mnt/rti-pulmonary/scratch/gwas/ukbiobank/data/fev1/0010/afr/keep.txt",
    header = FALSE,
    stringsAsFactors = FALSE
)
sampleInclude = sampleInclude$V1

snpInclude = read.table(
    "/mnt/rti-pulmonary/gwas/ukbiobank/data/fev1/0010/Mediation_analysis_sig_SNPs_FEV1_eur.txt",
    header = FALSE,
    stringsAsFactors = FALSE
)
snpInclude = snpInclude$V1

annot = read.table(
    "/mnt/rti-shared/shared_data/post_qc/ukbiobank/genotype/array/imputed/v3/all/ukb_gds_annot_chr22_v3_grch37_dbsnp_b153.tsv",
    header = TRUE,
    stringsAsFactors = FALSE
)
extract = annot[annot$ID %in% snpInclude, "snpID"]

gdsSubset(
    "/mnt/rti-shared/shared_data/post_qc/ukbiobank/genotype/array/imputed/v3/all/ukb_imp_chr22_v3.gds",
    "/mnt/rti-pulmonary/scratch/gwas/ukbiobank/data/fev1/0010/afr/ukb_imp_chr22_v3_afr.gds",
    sample.include=sampleInclude,
    snp.include=extract
)

gdsSubset(
    getArg("file-in-gds"),
    getArg("file-out-gds"),
    sample.include=getArg("file-variant-list"),
    snp.include=getArg("file-sample-list")
)
