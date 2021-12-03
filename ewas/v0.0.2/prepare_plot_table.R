suppressPackageStartupMessages(require(optparse)) 
suppressPackageStartupMessages(require(lattice)) 

option_list = list(
  make_option(c("-i", "--input-files"), action="store", type="character",
              help="A list of input files. Make sure to enclose them with double quotes."),
  make_option(c("-f", "--fdr"), default=0.05, type='double',
              help="False discovery rate (apply the Benjamini-Hochberg method). [default %default]")
)

opt = parse_args(OptionParser(option_list=option_list))
####################################################################################################

inputs <- strsplit(opt$i, " ")

results <- list()

for (i in 1:length(inputs[[1]])) {

    ewas_results <- inputs[[1]][i]
    results[[i]] <- read.csv(ewas_results)

}

all_results <- Reduce(rbind, results) # successively apply rbind to the list of results in a recursive fashion

#FORMAT DATA
resu_annot_sub <- all_results[,c("probeID","BETA","P_VAL","chr","pos")] #Subset to those columns necessary
resu_annot_sub$chr_new <- gsub("[xX]", "23", resu_annot_sub$chr) # change chrX to chr23
resu_annot_sub$chr_new <- as.numeric(gsub("[a-zA-Z ]", "", resu_annot_sub$chr_new)) #create chr.new with "chr" prefix removed for chr; necessary for plotting purposes
resu_annot_sub$chr_new <- gsub("23", "X", resu_annot_sub$chr_new) #change chr23 to chrX

#resu_annot_sub$chr_ordered <- factor(resu_annot_sub$chr_new,levels=c(1:22, "X"))
resu_annot_sub$chr_ordered <- factor(resu_annot_sub$chr_new)

## find sigLin for FDR<1% in Manhattan plot
find_fdr <- function(target=0.10, start_guess=1e-10, pval_vec) {
    difference <- 10
    while (difference > target/100) {
        fdr_val <- p.adjust(c(start_guess, pval_vec), method="BH")[1]
        #print(fdr_val)
        difference <- abs(fdr_val - target)
        start_guess <- start_guess + 1e-8
        #print(start_guess)
    }

    return (signif(start_guess, 4) ) # FDR of <target> is reached at <start_guess>
}

fdr_value <- find_fdr(target=opt$fdr,  pval_vec=resu_annot_sub$P_VAL)
bonferroni <- signif(0.05 / length(resu_annot_sub$probeID),3)

#p_bh <- p.adjust(c(1.84e-6,resu.annot.sub$P_VAL),method="BH") # Given a set of p-values, returns p-values adjusted using Benjamini & Hochberg (fdr)
#head(p_bh)[1]

outstring <- paste0("fdr_", opt$fdr, "_adjusted_gw_threshold.txt")
writeLines(toString(fdr_value), outstring)
writeLines(toString(bonferroni), "bonferroni_adjusted_gw_threshold.txt")
write.table(resu_annot_sub, "plotting_table.csv", quote=F, row.names=F)
