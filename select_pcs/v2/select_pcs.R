#!/usr/local/bin/Rscript

# Arguments
# --file_in_pheno <PHENO FILE>
# --file_in_pcs <PC FILE>
# --pheno_name <PHENOTYPE NAME>
# --coded_12
# --model_type <"logistic" OR "continuous">
# --ancestry <ANCESTRY LABEL>
# --pve_threshold <PVE THRESHOLD> (percentage)
# --combine_fid_iid (Set fid and iid fields to fid_iid)
# --file_out_pheno <OUTPUT PHENO FILE> (input phenotype file with PCs added)
# --file_out_prefix <OUTPUT PREFIX> (for plots and log)

library(R.utils)
library(stringr)

args = commandArgs(asValues = TRUE)
cat("Arguments:\n")
str(args)

file_in_pheno = toString(args["file_in_pheno"])
file_in_pcs = toString(args["file_in_pcs"])
pheno_name = toString(args["pheno_name"])
model_type = toString(args["model_type"])
ancestry = toString(args["ancestry"])
pve_threshold = strtoi(toString(args["pve_threshold"]))
file_out_pheno = toString(args["file_out_pheno"])
file_out_prefix = toString(args["file_out_prefix"])
coded_12 = if(args["coded_12"] == "TRUE") TRUE else FALSE
combine_fid_iid = if(args["combine_fid_iid"] == "TRUE") TRUE else FALSE

options(stringsAsFactors=F)

ancestry = toupper(ancestry) # for graph titles

# Read phenotype file
pheno = read.delim(file_in_pheno, sep="")

# Read PC file, split IDs, and update column names
pcs = read.table(
    file_in_pcs,
    skip=1
)
names(pcs)[1] <- "fid"
names(pcs)[2] <- "iid"
pc_names = paste0("PC", 1:10)
names(pcs)[3:12] <- pc_names
merge_data = merge(
    x = pheno[,c("fid", "iid", pheno_name)],
    y = pcs[, c("fid", "iid", pc_names)],
    by = c("fid", "iid"),
    sort = FALSE
)
model.str = paste0(pheno_name, "~", paste(pc_names, collapse=" + ")) 
# Get model fits
if (model_type=="continuous"){
    model_fit = lm(formula=as.formula(model.str), data=merge_data)
    pve_calc = "Mean Sq"
} else if (model_type=="logistic"){
    if (coded_12 == TRUE) {
        merge_data[,pheno_name] = merge_data[,pheno_name] - 1
    }
    model_fit = glm(formula=as.formula(model.str), data=merge_data, family=binomial(link="logit"))
    pve_calc = "Deviance"
}
# Get sequential (type I) sum of squares
anova_model = anova(model_fit)

# Calculate percent variance explained and sort
variance_explained = cbind(anova_model[pc_names,], 
                PVE=round(anova_model[pc_names, pve_calc]/sum(anova_model[pc_names, pve_calc])*100, digits=2))
pve_sorted = variance_explained[order(variance_explained$PVE, decreasing=T),]

pv_list = vector(length = 10)
total = 0
for (i in 1:nrow(pve_sorted)){
    pv_list[i] = row.names(pve_sorted[i,])
    total = total + pve_sorted[i, "PVE"]
    #print(total)
    if (total >= pve_threshold) break
}

topPCs = pv_list[which(pv_list != "FALSE")]

# Output summary
sink(paste0(file_out_prefix, ".log"))
cat("MODEL FORMULA:\n\n", model.str, "\n")
summary(model_fit)
pve_sorted
cat("Top PCs: ",topPCs, "\n")
cat(paste("PVE:     ", total))
sink()

# Set graphical parameters
cex.factor = 0.9
barplot_ylim = c(0, max(variance_explained$PVE)*1.2)

# Visualize PVE
png(paste0(file_out_prefix, "_pve.png"), width = 1000, height = 1000, type="cairo")
par(mfrow=c(1,2))
barplot(height=pve_sorted$PVE, names.arg=rownames(pve_sorted), beside=T, cex.names=cex.factor, 
        col="red3", border="red3", ylim=barplot_ylim, main=paste(ancestry,"Percent Variance Explained (Sorted PCs)"), ylab="PVE")
plot(cumsum(pve_sorted$PVE), type="b", main=paste(ancestry,"PVE Cumulative Sum (Sorted PCs)"), ylab="PVE", 
        lwd=2, col="red3", pch=17, xaxt="n", xlab="", ylim=c(0,100))
axis(side=1, at=c(1:10), labels=rownames(pve_sorted), cex.axis=cex.factor)
dev.off()

# Create final df
merge_data = merge(
    x = pheno,
    y = pcs[, c("fid", "iid", topPCs)],
    by = c("fid", "iid"),
    sort = FALSE
)

# Combine fid and iid if specified
if (combine_fid_iid) {
    merge_data$fid = paste0(merge_data$fid, "_", merge_data$iid)
    merge_data$iid = merge_data$fid
}

# Output phenotype file
write.table(
    merge_data,
    file = file_out_pheno,
    row.names = FALSE,
    quote = FALSE,
    sep = "\t"
)
