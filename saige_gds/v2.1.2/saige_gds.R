#!/usr/local/bin/Rscript


args <- commandArgs(TRUE)
loop = TRUE
hasInFile = FALSE
hasOutFile = FALSE
hasCVcutoff = FALSE 
while (loop) {
        if (args[1] == "--help") {
                stop("saigeGDS.R --geno <in.gds> --pheno <in.pheno> --grm <in.grm.gds> --out <out.assoc.txt>")
        }

        if (args[1] == "--geno") {
                geno_fn = args[2] #/share/storage/REDS-III/RBCOmics/data/imputation/v1/imputations_by_race/chr1/rbc.CAUCASIAN.1000G_p3.chr1.0.gds
                hasPrefix = TRUE
        }

        if (args[1] == "--pheno") {
                phenoFile = args[2] #"/share/storage/REDS-III/RBCOmics/pica/phenotype/phenotype.pica.ice.ea.n7493.PC1-5.txt"
                hasPhenoFile = TRUE
        }
	if (args[1] == "--grm") {
		grm_fn = args[2] #"/share/storage/REDS-III/RBCOmics/pica/analysis/processing/chr1/rbc.CAUCASIAN.1000G_p3.chr1.0.grm_geno.gds"
		hasGrm = TRUE
	}
#	if (args[1] == "--CVcutoff") {
#		CVcutoff = args[2]
#		hasCVcutoff = TRUE
#	}
        if (args[1] == "--out") {
                outFile = args[2]
                hasOutFile = TRUE
        }
        if (length(args) > 1) {
                args = args[2:length(args)]
        } else {
                loop=FALSE
        }

}



library(SeqArray)
library(SAIGEgds)
library(SNPRelate)

#### only need to calculate kinship once; skip all these steps ####

#### Convert the imputed genotypes from plink to seqarray GDS
#bed.fn <- paste0(prefix,".bed") #"/share/storage/REDS-III/RBCOmics/data/imputation/v1/imputations_by_race/chr1/rbc.CAUCASIAN.1000G_p3.chr1.0.bed"
#bim.fn <- paste0(prefix,".bim") #"/share/storage/REDS-III/RBCOmics/data/imputation/v1/imputations_by_race/chr1/rbc.CAUCASIAN.1000G_p3.chr1.0.bim"
#fam.fn <- paste0(prefix,".fam") #"/share/storage/REDS-III/RBCOmics/data/imputation/v1/imputations_by_race/chr1/rbc.CAUCASIAN.1000G_p3.chr1.0.fam"
#grm_fn <- "/share/storage/REDS-III/RBCOmics/pica/analysis/processing/chr1/rbc.CAUCASIAN.1000G_p3.chr1.0.grm_geno.gds"
#phenoFile <- "/share/storage/REDS-III/RBCOmics/pica/phenotype/phenotype.pica.ice.ea.n7493.PC1-5.txt"

#out.gdsfn <- paste0(prefix,".gds") #"/share/storage/REDS-III/RBCOmics/pica/analysis/processing/chr1/rbc.CAUCASIAN.1000G_p3.chr1.0.gds"
#seqBED2GDS(bed.fn,fam.fn,bim.fn,out.gdsfn)



#### Load the GDS and calculate kinship matrix ####
#geno_fn <- out.gdsfn #"/share/storage/REDS-III/RBCOmics/pica/analysis/processing/chr1/rbc.CAUCASIAN.1000G_p3.chr1.0.gds"
#gds <- seqOpen(geno_fn)
##LD pruning
#set.seed(1000)
#snpset <- snpgdsLDpruning(gds)
#str(snpset)
#snpset.id <- unlist(snpset, use.names=FALSE)  # get the variant IDs of a LD-pruned set
#grm_fn <- paste0(prefix,".grm_geno.gds") #"/share/storage/REDS-III/RBCOmics/data/imputation/v1/imputations_by_race/chr1/rbc.CAUCASIAN.1000G_p3.chr1.0.grm_geno.gds"
#seqSetFilter(gds, variant.id=snpset.id)
## export to a GDS genotype file without annotation data. This is the genotype relationship matrix
#seqExport(gds, grm_fn, info.var=character(), fmt.var=character(), samp.var=character())



#### Fit null model ####
sampid <- seqGetData(grm_fn, "sample.id")  # sample IDs in the genotype file
pheno <- read.table(phenoFile,sep=" ",header=T,stringsAsFactors=F)
colnames(pheno)[1]<-"sample.id"
##Assume that col 1 = sample ID
# col 2 = phenotype
# all other ols are covariates
vars <- colnames(pheno)
frm <- as.formula( paste0(vars[2]," ~ ",paste(vars[3:length(vars)],collapse="+"))   )
#if (hasCVcutoff) {
#  CVcutoff <- as.numeric(CVcutoff)
#  glmm <- seqFitNullGLMM_SPA(frm, pheno, grm_fn, trait.type="binary", sample.col="sample.id", traceCVcutoff=CVcutoff)
#} else {
glmm <- seqFitNullGLMM_SPA(frm, pheno, grm_fn, trait.type="quantitative", sample.col="sample.id")
#}

#### P-value calculation ####
#close the gds first
#seqClose(gds)
assoc <- seqAssocGLMM_SPA(geno_fn, glmm, mac=10, parallel=2,maf=0.01)


#### Save to file ####
# GDS = 360k/chunk
# txt = 1.1M/chunk
# but it's a PITA to use gds downstream, so use txt
write.table(assoc,file=outFile,sep="\t",col.names=T,row.names=F,quote=F)
