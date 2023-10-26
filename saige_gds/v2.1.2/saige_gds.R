#!/usr/local/bin/Rscript


library(R.utils)
library(SeqArray)
library(SAIGEgds)
library(SNPRelate)
library(optparse)


option_list = list(
    make_option(
        c('--geno'),
        action='store',
        default=NULL,
        type='character',
        help="Path to genotype GDS file (required)"
    ),
     make_option(
        c('--pheno'),
        action='store',
        default=NULL,
        type='character',
        help="Path to phenotype file (required)"
    ),
     make_option(
        c('--grm'),
        action='store',
        default=NULL,
        type='character',
        help="Path to GRM file (required)"
    ),
     make_option(
        c('--out'),
        action='store',
        default=NULL,
        type='character',
        help="Path to output file (required)"
    )
)

getArg = function(parameter) {
    return(args[parameter][[1]])
}

checkForRequiredArgs = function(args) {
    requiredArgs = c(
        'geno',
        'pheno',
        'grm',
        'out'
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




# read phenotype data
pheno <- read.table(
    getArg("pheno"),
    sep=" ",header=T,stringsAsFactors=F)
colnames(pheno)[1]<-"sample.id"



# Fit null model
sampid <- seqGetData(
    getArg("grm"),
    "sample.id")  # sample IDs in the genotype file
##Assume that col 1 = sample ID
# col 2 = phenotype
# all other ols are covariates
vars <- colnames(pheno)
frm <- as.formula( paste0(vars[2]," ~ ",paste(vars[3:length(vars)],collapse="+"))   )
glmm <- seqFitNullGLMM_SPA(frm, 
    pheno, 
    getArg("grm"),
    trait.type="quantitative", 
    sample.col="sample.id")



# P-value calculation #
assoc <- seqAssocGLMM_SPA(
    getArg("geno"),
    glmm, 
    mac=10, 
    parallel=2,
    maf=0.01)


# Save to file 

write.table(assoc,
    file=getARg("out"),
    sep="\t",
    col.names=T,
    row.names=F,
    quote=F)
