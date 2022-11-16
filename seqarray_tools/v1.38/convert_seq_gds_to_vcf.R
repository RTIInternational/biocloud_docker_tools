#!/usr/local/bin/Rscript

library(SeqArray)
library(optparse)

option_list = list(
    make_option(
        c('--file-seq-gds'),
        action='store',
        default=NULL,
        type='character',
        help="Path to input GDS genotype file (required)"
    ),
    make_option(
        c('--file-vcf'),
        action='store',
        default=NULL,
        type='character',
        help="Path to output vcf genotype file (required)"
    ),
    make_option(
        c('--file-gds-variant-annot'),
        action='store',
        default=NULL,
        type='character',
        help="Path to annotation file for variants in GDS file (optional)"
    ),
    make_option(
        c('--file-variant-ids'),
        action='store',
        default=NULL,
        type='character',
        help="Path to file of variant IDs to extract (optional)"
    ),
    make_option(
        c('--variant-annot-xref-col'),
        action='store',
        default=NULL,
        type='character',
        help="Column in --file-variant-annot to use as xref with --file-variant-ids (optional)"
    ),
    make_option(
        c('--variant-annot-gds-id-col'),
        action='store',
        default=NULL,
        type='character',
        help="Column in --file-variant-annot containing the variant ID corresponding to the GDS file (optional)"
    ),
    make_option(
        c('--file-gds-sample-annot'),
        action='store',
        default=NULL,
        type='character',
        help="Path to annotation file for variants in GDS file (optional)"
    ),
    make_option(
        c('--file-sample-ids'),
        action='store',
        default=NULL,
        type='character',
        help="Path to file of sample IDs to keep (required)"
    ),
    make_option(
        c('--sample-annot-xref-col'),
        action='store',
        default=NULL,
        type='character',
        help="Column in --file-sample-annot to use as xref with --file-sample-ids (optional)"
    ),
    make_option(
        c('--sample-annot-gds-id-col'),
        action='store',
        default=NULL,
        type='character',
        help="Column in --file-sample-annot containing the sample ID corresponding to the GDS file (optional)"
    )
)


getArg = function(parameter) {
    return(args[parameter][[1]])
}

checkForRequiredArgs = function(args) {
    requiredArgs = c(
        'file-seq-gds',
        'file-vcf'
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

gds = seqOpen(getArg("file-seq-gds"))

extract = NULL
if (!is.null(getArg("file-variant-ids"))) {
    variantIDs = read.table(
        getArg("file-variant-ids"),
        header = FALSE,
        stringsAsFactors = FALSE
    )
    variantIDs = variantIDs$V1
    if (!is.null(getArg("file-gds-variant-annot")) && !is.null(getArg("variant-annot-xref-col")) && !is.null(getArg("variant-annot-gds-id-col"))) {
        variantAnnot = read.table(
            getArg("file-gds-variant-annot"),
            header = TRUE,
            stringsAsFactors = FALSE
        )
        extract = variantAnnot[variantAnnot[,getArg("variant-annot-xref-col")] %in% variantIDs, getArg("variant-annot-gds-id-col")]
    } else {
        extract = variantIDs
    }
}

keep = NULL
if (!is.null(getArg("file-sample-ids"))) {
    sampleIDs = read.table(
        getArg("file-sample-ids"),
        header = FALSE,
        stringsAsFactors = FALSE
    )
    sampleIDs = sampleIDs$V1
    if (!is.null(getArg("file-gds-sample-annot")) && !is.null(getArg("sample-annot-xref-col")) && !is.null(getArg("sample-annot-gds-id-col"))) {
        sampleAnnot = read.table(
            getArg("file-gds-sample-annot"),
            header = TRUE,
            stringsAsFactors = FALSE
        )
        keep = sampleAnnot[sampleAnnot[,getArg("sample-annot-xref-col")] %in% sampleIDs, getArg("sample-annot-gds-id-col")]
    } else {
        keep = sampleIDs
    }
}

seqSetFilter(gds, sample.id=keep, variant.id=extract)

seqGDS2VCF(gds, getArg("file-vcf"))
