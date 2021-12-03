#!/usr/bin/Rscript
library(parallel)  # to use multicore approach - part of base R – can be omitted if lapply() used instead of mclapply()
library(MASS) # rlm function for robust linear regression
library(lmtest) #to use coeftest
library(sandwich) #Huberís estimation of the standard error
library(data.table)
library(stats)
library(IlluminaHumanMethylationEPICanno.ilm10b4.hg19) 
library(optparse)

option_list = list(
  make_option(c("-p", "--phenotype-file"), action="store", type="character",
              help="Phenotype file name and path."),
  make_option(c("-t", "--test-var"), type='character',
              help="The name of the phenotype of interest that was measured as shown in the header of the phenotype file. The test variable."),
  make_option(c("-s", "--sample-name"), type='character',
              help="Column name given in the header of the phenotype file. This should match the DNAm file header too."),
  make_option(c("-m", "--dnam"), type='character',
              help="DNA methylation data."),
  make_option(c("-c", "--covariates"), type='character',
              help="Space separated string of covariate names. e.g. 'cov1 cov2 cov3'."),
  make_option(c("-o", "--output"), default="ewas_results", type='character',
              help="Basename for output results file. [default %default]")
)

opt <- parse_args(OptionParser(option_list=option_list))
covariates <- strsplit(opt$covariates, " ")[[1]]

####################################################################################################
lmtest <- function(model_data, probe_id, test_var, covariates) {
    lm_model <- as.formula(
        paste0( probe_id, "~", paste0(c(test_var, covariates), collapse=" + "))
    )
    mod <- try(lm(lm_model, data=model_data))

	if(class(mod) == "try-error"){
        print(paste("error thrown by column", probe_id))
        invisible(rep(NA, 3)) # doesn't print if not assigned. Use in place of return

	}else cf <- coef(summary(mod))
        cf[test_var, c("Estimate", "Std. Error", "Pr(>|t|)")] 
}

# read in phenotype file
cat("Reading phenotype data......\n")
pheno <- read.csv(opt$p, header=T, stringsAsFactors=F, sep=" ")

pheno[is.na(pheno[, opt$t]),][, opt$t] <- 0 # remove NA from phenotypes

cat("Phenotype data has ",dim(pheno)[1]," rows and ",dim(pheno)[2]," columns.\n\n")

cat("Loading DNA methylation data......\n")
    load(opt$dnam)
    
beta_matrix <- t(bVals_chr[,colnames(bVals_chr) %in% pheno[, opt$s]])
dim(beta_matrix)

cat("DNAm data has ",dim(beta_matrix)[1]," rows and ",dim(beta_matrix)[2]," columns.\n\n")

# combine the DNAm data and the phenotype data, which includes test-var and covars
ewas_mat <- merge(beta_matrix, pheno, by.x="row.names", by.y = opt$s)
#pheno_ordered <- pheno[match(row.names(beta_matrix), pheno$Sample_Name),] # (first) matches of its first argument in its second argument.
#ewas_mat <- cbind(beta_matrix, pheno_ordered)

#Run adjusted EWAS
system.time(
    ind.res <- mclapply(X=dimnames(unlist(beta_matrix))[[2]], 
                        FUN=lmtest,
                        model_data=ewas_mat,
                        test_var=opt$t,
                        covariates=covariates)

# https://stackoverflow.com/questions/14427253/passing-several-arguments-to-fun-of-lapply-and-others-apply
)
names(ind.res) <- dimnames(beta_matrix)[[2]]

setattr(ind.res, 'class', 'data.frame')
setattr(ind.res, "row.names", c(NA_integer_,4))
setattr(ind.res, "names", make.names(names(ind.res), unique=TRUE))
probelistnames <- names(ind.res)
all.results <- t(data.table(ind.res))
all.results<-data.table(all.results)
all.results[, probeID := probelistnames]
setnames(all.results, c("BETA","SE", "P_VAL", "probeID")) # rename columns
setcolorder(all.results, c("probeID","BETA","SE", "P_VAL"))
rm(probelistnames, ind.res)

#Add column for number of samples for each probe
tbeta_matrix<-t(beta_matrix) #transform methylation data again so that rows are probes and columns are samples
all.results<-all.results[match(rownames(tbeta_matrix),all.results$probeID),] # match order of all.results with order of probes in tbeta_matrix
all.results$N<- rowSums(!is.na(tbeta_matrix))

#Add columns to include Illumina probe annotation
annEPIC = getAnnotation(IlluminaHumanMethylationEPICanno.ilm10b4.hg19)
a<-as.data.frame(all.results)
b<-as.data.frame(annEPIC)
all.results.annot<-merge(a, b, by.x="probeID", by.y="Name")
all.results.annot<-all.results.annot[order(all.results.annot$P_VAL),] #sort by P_VAL
write.table(all.results.annot, 
	    paste0(opt$output, "_", all.results.annot$chr[1], "_", Sys.Date(), ".csv"), 
            na="NA",sep = ",",row.names=FALSE) #Export full results; these will be used later for plotting
