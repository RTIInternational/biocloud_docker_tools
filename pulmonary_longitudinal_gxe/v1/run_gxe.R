#!/usr/local/bin/Rscript

library(data.table)
library(bigsnpr)
library(lmerTest)
library(lme4)
library(dbplyr)
library(optparse)

option_list = list(
    make_option(
        c('--file-bgen'),
        action='store',
        default=NULL,
        type='character',
        help="Path to bgen file containing imputed genotypes (required)"
    ),
    make_option(
        c('--file-bgi'),
        action='store',
        default=NULL,
        type='character',
        help="Path to bgen index file (required)"
    ),
    make_option(
        c('--file-sample'),
        action='store',
        default=NULL,
        type='character',
        help="Path to sample file (required)"
    ),
    make_option(
        c('--file-pheno'),
        action='store',
        default=NULL,
        type='character',
        help="Path to phenotype file (required)"
    ),
    make_option(
        c('--ancestry'),
        action='store',
        default=NULL,
        type='character',
        help="Ancestry on which to run analysis (required)"
    ),
    make_option(
        c('--pheno'),
        action='store',
        default=NULL,
        type='character',
        help="Phenotype for model (required)"
    ),
    make_option(
        c('--omega3'),
        action='store',
        default=NULL,
        type='character',
        help="Omega-3 to use for interaction (required)"
    ),
    make_option(
        c('--file-out-prefix'),
        action='store',
        default=NULL,
        type='character',
        help="Path to output file (required)"
    ),
    make_option(
        c('--ncores'),
        action='store',
        default=1,
        type='integer',
        help="# of cores to use"
    )
)

args = parse_args(OptionParser(option_list=option_list))

get_arg = function(args, parameter) {
    return(args[parameter][[1]])
}

file_bgen = get_arg(args, "file-bgen")
file_bgi = get_arg(args, "file-bgi")
file_sample = get_arg(args, "file-sample")
file_pheno = get_arg(args, "file-pheno")
ancestry = get_arg(args, "ancestry")
pheno = get_arg(args, "pheno")
omega3 = get_arg(args, "omega3")
file_out_prefix = get_arg(args, "file-out-prefix")
ncores = get_arg(args, "ncores")

# Read sample file
print("Reading sample file")
samp_file = read.table(
    file_sample,
    header = TRUE
)

# Read pheno file
print("Reading pheno file")
pheno_file = read.table(
    file_pheno,
    header = TRUE
)

# Get list of samples in both pheno and geno files
with_geno_pheno = subset(pheno_file, pheno_file$IID %in% samp_file$ID_1)
with_geno_pheno$FID_IID = paste0(with_geno_pheno$FID, "_", with_geno_pheno$IID)

## Read index file
print("Reading bgi file")
info = snp_readBGI(file_bgi)
all_snp_ids = list(with(info, paste(chromosome, position, allele1, allele2, sep = "_")))

## Read bgen file
print("Reading bgen file")
rds = snp_readBGEN(
    bgenfiles = file_bgen,
    backingfile = sprintf("%s.bgen", file_out_prefix),
    list_snp_id = all_snp_ids,
    ncores = ncores
)
ukb.bigSNP = bigsnpr::snp_attach(rds)

# Get genotype matrix
snp_ids = ukb.bigSNP$map$rsid
genotypes = as.data.frame(ukb.bigSNP$genotypes[])
colnames(genotypes) = snp_ids
genotypes$IID = samp_file[-1,]$ID_1

## Create df with phenotype and chunk of genotypes to run
merged = merge(with_geno_pheno, genotypes, by = 'IID')

## Convert time to time in years, as well as PFT to ML rather than L (this is how Bonnie had run things for her PFT GWAS paper)
merged$time_years = merged$time_since_baseline / 365
merged$FEV1 = merged$FEV1 * 1000
merged$FVC = merged$FVC * 1000
merged$FEV1_FVC_ratio = merged$FEV1/merged$FVC

## Subset to ancestry
final_data = subset(merged, merged$anc == ancestry) #Subset to eurs for now

#Fit models
gwas_1df_inter = as.data.frame(matrix(nrow=length(snp_ids), ncol=6))
gwas_2df_time = as.data.frame(matrix(nrow=length(snp_ids), ncol=3))
gwas_2df_n3 = as.data.frame(matrix(nrow=length(snp_ids), ncol=3))

i=1
for(snp in snp_ids){
    # Compute maf
    maf = sum(final_data[[snp]]) / (2*length(final_data[[snp]]))
    if(maf < 0.001){
        i = i + 1
        print(sprintf("%s maf %s too low, skipped", snp, maf))
        next
    } else {
        print(snp)
    }
    
    # 0) Fit model that will be used to test each hypothesis. If pheno is FVC then include weight as a covariate
    skip_to_next = FALSE
    
    if(pheno == 'FVC'){
        tryCatch(
            {
                mod = lmerTest::lmer(
                    sprintf('%s ~ CURRENT_SMOKER + FORMER_SMOKER + AGE + AGE2 + SEX + HEIGHT + HEIGHT2 + WEIGHT +
                                            time_years + `%s` + %s + `%s`*time_years + `%s`*%s + `%s`*time_years*%s + 
                                            PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 +
                                            (1+time_years|IID)', pheno, snp, omega3, snp, snp, omega3, snp, omega3),
                    data = final_data,
                    control=lmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5))
                )
            },
            error = function(e) { skip_to_next = TRUE}
        )
    } else {
        tryCatch(
            {
                mod = lmerTest::lmer(
                    sprintf('%s ~ CURRENT_SMOKER + FORMER_SMOKER + AGE + AGE2 + SEX + HEIGHT + HEIGHT2 +
                                            time_years + `%s` + %s + `%s`*time_years + `%s`*%s + `%s`*time_years*%s + 
                                            PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 + PC10 +
                                            (1+time_years|IID)', pheno, snp, omega3, snp, snp, omega3, snp, omega3), 
                    data = final_data,
                    control=lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e5))
                )
            },
            error = function(e) { skip_to_next = TRUE}
        )
    }
    
    if(skip_to_next == TRUE) {
        print("Can't fit initial model. Skipping SNP")
        gwas_1df_inter[i,] = c(snp, NA, NA, NA, NA, NA)
        gwas_2df_time[i,] = c(snp, NA, NA)
        gwas_2df_n3[i,] = c(snp, NA, NA)
        next
    } 
    
    mod_coefs = summary(mod)$coefficients
    cov = vcov(mod)
    
    # 1) test SNP:w3:time using lmerTest/lmer function
    if((sprintf("time_years:`%s`:%s",snp, omega3) %in% rownames(mod_coefs)) | (sprintf("time_years:%s:%s",snp, omega3) %in% rownames(mod_coefs))){
        snp_n3_time_coefs = mod_coefs[grep(sprintf("time_years:`%s`:%s|time_years:%s:%s",snp, omega3, snp, omega3), rownames(mod_coefs)), ] #5 cols
        gwas_1df_inter[i,] = c(snp, snp_n3_time_coefs)
    } else {
        gwas_1df_inter[i,] = c(snp, NA, NA, NA, NA, NA)
        print("Skipped interaction test")
    }
    
    # 2) test SNP:time and SNP:w3:time 
    #Get fixed effect estimates
    snp_time_coefs = as.matrix(
        mod_coefs[grep(sprintf("time_years:%s:%s|time_years:%s|time_years:`%s`:%s|time_years:`%s`",snp, omega3, snp, snp, omega3, snp), rownames(mod_coefs)), ]
    )
    
    if(dim(snp_time_coefs)[1] == 2){ #Check if two terms. If not, sometimes will be 5x1 or other
        snp_time_betas = snp_time_coefs[,1]
        snp_time_cov_betas = cov[grep(sprintf("time_years:%s:%s|time_years:%s|time_years:`%s`:%s|time_years:`%s`",snp, omega3, snp, snp, omega3, snp), rownames(cov)), 
                                    grep(sprintf("time_years:%s:%s|time_years:%s|time_years:`%s`:%s|time_years:`%s`",snp, omega3, snp, snp, omega3, snp), colnames(cov))]
        
        #Compute wald test 
        snp_time_wald_stat = t(snp_time_betas) %*% solve(snp_time_cov_betas) %*% snp_time_betas
        snp_time_wald_pval = pchisq(as.numeric(snp_time_wald_stat), 2, lower.tail = FALSE) #2 df test
        gwas_2df_time[i,] = c(snp, as.numeric(snp_time_wald_stat), as.numeric(snp_time_wald_pval))
    } else {
        gwas_2df_time[i,] = c(snp, NA, NA)
        print("Skipped joint time test")
    }
    
    # 3) test SNP:w3 and SNP:w3:time 
    snp_n3_coefs = as.matrix(
        mod_coefs[grep(sprintf("time_years:%s:%s|%s:%s|time_years:`%s`:%s|`%s`:%s", snp, omega3, snp, omega3, snp, omega3, snp, omega3), rownames(mod_coefs)), ]
    )
    
    if(dim(snp_n3_coefs)[1] == 2){
        snp_n3_betas = (snp_n3_coefs[,1])
        snp_n3_cov_betas = cov[grep(sprintf("time_years:%s:%s|%s:%s|time_years:`%s`:%s|`%s`:%s",snp, omega3, snp, omega3, snp, omega3, snp, omega3), rownames(cov)), 
                                grep(sprintf("time_years:%s:%s|%s:%s|time_years:`%s`:%s|`%s`:%s",snp, omega3, snp, omega3, snp, omega3, snp, omega3), colnames(cov))]
        
        #Compute wald test 
        snp_n3_wald_stat = t(snp_n3_betas) %*% solve(snp_n3_cov_betas) %*% snp_n3_betas
        snp_n3_wald_pval = pchisq(as.numeric(snp_n3_wald_stat), 2, lower.tail = FALSE) #2 df test
        gwas_2df_n3[i,] = c(snp, as.numeric(snp_n3_wald_stat), as.numeric(snp_n3_wald_pval))
    } else{
        gwas_2df_n3[i,] = c(snp, NA, NA)
        print("Skipped joint omega3 test")
    }
    
    i = i + 1
}

#Add on column names and p value
colnames(gwas_1df_inter) = c("rsid", "est", "std_err", "df", "t_value", "p")
colnames(gwas_2df_time) = c("rsid", "time_2df_chi_sq", "time_2df_p")
colnames(gwas_2df_n3) = c("rsid", "n3_2df_chi_sq", "n3_2df_p")

#Combine output into one df 
all_output = merge(
    merge(
        gwas_1df_inter[complete.cases(gwas_1df_inter), ],
        gwas_2df_time[complete.cases(gwas_2df_time), ],
        by = 'rsid')
    ,
    gwas_2df_n3[complete.cases(gwas_2df_n3), ], by = 'rsid'
)

# Merge back on chr and pos from map
final_output = merge(ukb.bigSNP$map[,c("chromosome", "rsid", "physical.pos", "allele1", "allele2", "freq", "info")], all_output)

# Output 
write.table(
    final_output,
    sprintf("%s.tsv", file_out_prefix),
    col.names=TRUE,
    row.names=FALSE,
    quote=FALSE,
    sep="\t"
)
