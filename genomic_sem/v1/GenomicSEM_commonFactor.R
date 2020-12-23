# Arguments
# --input_files <INPUT FILES LIST> comma-separated
# --trait_names <TRAIT NAMES LIST> comma-separated
# --sample_sizes<SAMPLE SIZES LIST> comma-separated
# --sample_prev <SAMPLE PREVALENCE LIST> comma-separated
# --pop_prev <POPULATION PREVALENCE LIST> comma-separated
# --reference <REFERENCE FILE>
# --info_filter <R_SQ filter> e.g. 0.8
# --maf_filter <MAF filter> e.g. 0.01
# --out_prefix <OUT PREFIX>
# --ld <LD SCORE REFERENCE FILE>
# --munge <BOOLEAN WHETHER MUNGING IS NEEDED>
# --LDSC <BOOLEAN WHETHER LDSC IS NEEDED>
# --LDSC_file <FILE OF ALREADY RUN LDSC> e.g. rds file
#  --estimation <ESTIMATION METHOF OF COMMON FACTOR> e.g. DWLS or ML
# --common_factor <BOOLEAN WHETHER COMMON FACTOR MODEL IS RUN>
# --common_factor_model <FILE PATH FOR COMMON FACTOR MODEL> e.g. lav file with lavaan syntax
# --se_logit <LIST IF SUMM STATS ARE LOGIT OR NOT> comma-separated
# --sumstats <BOOLEAN WHETHER SUMSTATS FOR GWAS IS RUN>
# --sumstats_file <FILE OF ALREADY RUN SUMSTATS> e.g. rds file
# --common_factor_gwas <BOOLEAN WHETHER COMMON FACTOR GWAS MODEL IS RUN>
# --common_factor_gwas_model <FILE PATH FOR COMMON FACTOR GWAS MODEL> e.g. lav file with lavaan syntax
# --parallel <BOOLEAN WHETHER PARALLEL COMPUTING IS CONDUCTED>


#install.packages("magrittr")
#install.packages("devtools")
#library(devtools)
#install_github("MichelNivard/GenomicSEM", dependencies=TRUE)
require(GenomicSEM)
require(Matrix)
require(stats)
library(R.utils)

args <- commandArgs(asValue = TRUE)
cat("Arguments:\n")
str(args)

## Parse arguments
out_prefix = toString(args["out_prefix"])
#setwd(outDir)
input.files = strsplit(toString(args["input_files"]), ",")[[1]]
trait.names = strsplit(toString(args["trait_names"]), ",")[[1]]
sample.sizes = strsplit(toString(args["sample_sizes"]), ",")[[1]]
info.filter = as.numeric(args["info_filter"])
maf.filter = as.numeric(args["maf_filter"])
traits = as.vector(sapply(trait.names, function(x) paste0(x, ".sumstats.gz")))
sample.prev = as.numeric(strsplit(toString(args["sample_prev"]), ",")[[1]])
pop.prev = as.numeric(strsplit(toString(args["pop_prev"]), ",")[[1]])
reference = toString(args["reference"])
ld = toString(args["ld"])
estimation = toString(args["estimation"])
se.logit = strsplit(toString(args["se_logit"]), ",")[[1]]
commonFactorModel = toString(args["common_factor_model"])
commonFactorGWASModel = toString(args["common_factor_gwas_model"])

cat(paste0("Out Prefix: \n", out_prefix))
cat(paste0("Input Files: ", input.files, "\n"))
cat(paste0("Trait Names: ", trait.names, "\n"))
cat(paste0("Sample Sizes: ", sample.sizes, "\n"))
cat(paste0("Info Filter: ", info.filter, "\n"))
cat(paste0("MAF Filter: ", maf.filter, "\n"))
cat(paste0("Sample Prev: ", sample.prev, "\n"))
cat(paste0("Pop Prev: ", pop.prev, "\n"))
cat(paste0("Reference: ", reference, "\n"))
cat(paste0("ld: ", ld, "\n"))
cat(paste0("Estimation: ", estimation, "\n"))
cat(paste0("SE Logit: ", se.logit, "\n"))
#cat(paste0("Parallel Processing: ", as.logical(args["parallel"]), "\n"))

## Munge the Summary Statistic files ##
cat("Munging Summary Statistics...\n")
cat(as.logical(args["munge"]))
if (as.logical(args["munge"])) {
    munge(files=input.files, trait.names=trait.names, hm3=reference, N=sample.sizes, info.filter=info.filter, maf.filter=maf.filter)
}


## LDSC ##
if (as.logical(args["LDSC"])) {
    cat("Running LDSC...\n")
    LDSCoutput <- ldsc(traits=traits, sample.prev=sample.prev, population.prev=pop.prev, ld=ld, wld=ld, trait.names=trait.names)
    saveRDS(LDSCoutput, file=paste0(out_prefix, "_LDSCoutput.", paste(trait.names, collapse="."), ".rds"))
} else {
    cat("Loading Previous LDSC Results...\n")
    LDSCoutput = readRDS(toString(args["LDSC_file"]))
}


## Common Factor Model without SNPs ##
if (as.logical(args["common_factor"])) {
    #zeroVar <- 'F1 =~ NA*oaFOU + MVP1_MVP2 + PGC + deCODE
    #F1 ~~ 1*F1
    #oaFOU ~~ b*oaFOU
    #b > 0.001
    #MVP1_MVP2 ~~ c*MVP1_MVP2
    #c > 0.001
    #PGC ~~ 0*PGC
    #deCODE ~~ d*deCODE
    #d > 0.001'
    zeroVar <- readLines(commonFactorModel)

    cat("Running user Common Factor Model...\n")
    userCommonFactor = usermodel(covstruc=LDSCoutput, model = zeroVar, estimation = estimation, CFIcalc=TRUE, std.lv=FALSE, imp_cov=TRUE)
    saveRDS(userCommonFactor, file = paste0(out_prefix, "_commonFactor_", estimation, ".rds"))
}

## Run the sumstats function - setup SNPs for Common Factor GWAS ##
if (as.logical(args["sumstats"])) {
    cat("Running sumstats for Common Factor GWAS Model...\n")
    sumstats = sumstats(files=input.files, ref=reference, trait.names=trait.names, se.logit=c(T,T,T,T), OLS=NULL, linprob=NULL, prop=sample.prev, N=sample.sizes, info.filter=info.filter, maf.filter=maf.filter, keep.indel=TRUE, parallel=FALSE, cores=NULL)
    saveRDS(sumstats, file = paste0(out_prefix, "_sumstats_GWAS.", paste(trait.names, collapse="."), ".rds"))
} else {
    cat("Loading sumstats...\n")
    sumstats = readRDS(toString(args["sumstats_file"]))
}


## Common Factor Model with SNPs ##
if (as.logical(args["common_factor_gwas"])) {
    zeroVarSNP <- readLines(commonFactorGWASModel)
    #zeroVarSNP <- 'F1 =~ NA*oaFOU + MVP1_MVP2 + PGC + deCODE
    #F1 ~~ 1*F1
    #oaFOU ~~ b*oaFOU
    #b > 0.001
    #MVP1_MVP2 ~~ c*MVP1_MVP2
    #c > 0.001
    #PGC ~~ 0*PGC
    #deCODE ~~ d*deCODE
    #d > 0.001
    #F1 ~ SNP'

    cat("Running user Common Factor GWAS Model ... \n")
    #if (as.logical(args["parallel"])) {
    #    userCommonFactorGWAS = userGWAS(covstruc = LDSCoutput, SNPs = sumstats, estimation = estimation, model = zeroVarSNP, modelchi = FALSE, printwarn = TRUE, toler = FALSE, SNPSE = FALSE, parallel = TRUE, Output = NULL, GC='standard', MPI=FALSE)
    #} else {
    #    userCommonFactorGWAS = userGWAS(covstruc = LDSCoutput, SNPs = sumstats, estimation = estimation, model = zeroVarSNP, modelchi = FALSE, printwarn = TRUE, toler = FALSE, SNPSE = FALSE, parallel = FALSE, Output = NULL, GC='standard', MPI=FALSE)
    #}
    userCommonFactorGWAS = userGWAS(covstruc = LDSCoutput, SNPs = sumstats, estimation = estimation, model = zeroVarSNP, printwarn = FALSE, parallel = FALSE, MPI=FALSE) 
    saveRDS(userCommonFactorGWAS, file = paste0(out_prefix, '.rds'))
}


