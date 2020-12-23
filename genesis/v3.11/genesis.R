#!/usr/local/bin/Rscript


# Arguments
# --file-geno <GENOTYPE FILE>
# --geno-format <GENOTYPE TYPE> e.g., gds
# --file-pheno <PHENOTYPE FILE>
# --pheno <PHENO>
# --covars <COVAR LIST> comma-separated
# --gxe <INTERACTION COVAR> (optional)
# --file-variant-list <VARIANT LIST FILE>
# --family <FAMILY> e.g., gaussian
# --chr <CHR>
# --out <OUTPUT FILE>

library(GENESIS)
library(GWASTools)
library(R.utils)

args <- commandArgs(asValue = TRUE)
cat("Arguments:\n")
str(args)

# Read phenotype data
pheno = read.table(
    toString(args["file-pheno"]),
    header = T
)

# Convert phenotype data to ScanAnnotationDataFrame
phenoScanAnnot = ScanAnnotationDataFrame(pheno)

# Fit the null model
nullmod = fitNullModel(
    phenoScanAnnot,
    outcome = toString(args["pheno"]),
    covars = strsplit(toString(args["covars"]), ",")[[1]],
    family = toString(args["family"])
)

# Read genotype data
if (toString(args["geno-format"]) == "gds") {
    geno <- GdsGenotypeReader(
        toString(args["file-geno"])
    )
}
genoData <- GenotypeData(geno)

# Create genotype iterator
snpInclude = NULL
if (toString(args["file-variant-list"]) != "") {
    snpInclude = read.table(
        toString(args["file-variant-list"]),
        header = F
    )
    snpInclude = snpInclude$V1
}
genoIterator = GenotypeBlockIterator(
    genoData,
    snpBlock=500,
    snpInclude = snpInclude
)

# Run association testing
gxE = NULL
if (args["gxe"] == "NULL" || args["gxe"] == "") {
    assoc = assocTestSingle(
        genoIterator,
        null.model = nullmod
    )
} else {
    assoc = assocTestSingle(
        genoIterator,
        null.model = nullmod,
        GxE = toString(args["gxe"])
    )
}

# Add alleles to results
## Need to confirm that this is correct (alt vs. ref)
assoc$alt = getAlleleA(geno, assoc$variant.id)
assoc$ref = getAlleleB(geno, assoc$variant.id)

# Close iterator
close(genoIterator)

# Fix chr
assoc$chr = toString(assoc$chr)
assoc$chr = toString(args["chr"])

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
    file = toString(args["out"]),
    row.names = FALSE,
    quote = FALSE,
    sep = "\t"
)
