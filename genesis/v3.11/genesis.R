#!/usr/local/bin/Rscript

# Arguments
# --in-geno <GENOTYPE FILE>
# --in-geno-format <GENOTYPE TYPE> e.g., gds
# --in-pheno <PHENOTYPE FILE>
# --pheno <PHENO>
# --covars <COVAR LIST> comma-separated
# --gxe <INTERACTION COVAR>
# --family <FAMILY> e.g., gaussian
# --out <OUTPUT FILE>

library(GENESIS)
library(GWASTools)
library(R.utils)

args <- commandArgs(asValue = TRUE)
cat("Arguments:\n")
str(args)

# Read phenotype data
pheno = read.table(
    toString(args["in-pheno"]),
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
if (toString(args["in-geno-format"]) == "gds") {
    geno <- GdsGenotypeReader(
        toString(args["in-geno"])
    )
}
genoData <- GenotypeData(geno)

# Create genotype iterator
genoIterator = GenotypeBlockIterator(genoData, snpBlock=500)

# Run association testing
if (toString(args["gxe"]) == "") {
    assoc = assocTestSingle(
        genoIterator,
        null.model = nullmod
    )
} else {
    assoc = assocTestSingle(
        genoIterator,
        null.model = nullmod,
        GxE = c(toString(args["gxe"]))
    )
}

# Add alleles to results
## Need to confirm that this is correct (alt vs. ref)
assoc$alt = getAlleleA(geno, assoc$variant.id)
assoc$ref = getAlleleB(geno, assoc$variant.id)

# Close iterator
close(genoIterator)

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
