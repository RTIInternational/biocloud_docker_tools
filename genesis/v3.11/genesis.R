#!/usr/local/bin/Rscript

library(GENESIS)
library(GWASTools)

args <- commandArgs(TRUE)

loop = TRUE
fileInGeno = ""
genoFormat = ""
fileInPheno = ""
pheno = ""
covars = ""
family = ""
gxE = ""
fileOut = ""
gzip = FALSE

while (loop) {

	if (args[1] == "--in-geno") {
		fileInGeno = args[2]
	}

	if (args[1] == "--in-geno-format") {
		genoFormat = args[2]
	}

	if (args[1] == "--in-pheno") {
		fileInPheno = args[2]
	}

	if (args[1] == "--pheno") {
		pheno = args[2]
	}

    # Comma-delimited
	if (args[1] == "--covars") {
		covars = strsplit(args[2], ",")[[1]]
	}

	if (args[1] == "--family") {
		family = args[2]
	}

	if (args[1] == "--gxe") {
		gxE = args[2]
	}

	if (args[1] == "--out") {
		fileOut = args[2]
	}

	if (args[1] == "--gzip") {
		gzip = TRUE
	}

	if (length(args) > 1) {
		args = args[2:length(args)]
	} else {
		loop=FALSE
	}

}

# Read phenotype data
pheno = read.table(
    fileInPheno,
    header = T
)

# Convert phenotype data to ScanAnnotationDataFrame
phenoScanAnnot = ScanAnnotationDataFrame(pheno)

# Fit the null model
nullmod = fitNullModel(
    phenoScanAnnot,
    outcome = pheno,
    covars = covars,
    family = family
)

# Read genotype data
if (genoFormat == "gds") {
    geno <- GdsGenotypeReader(
        fileInGeno
    )
}
genoData <- GenotypeData(geno)

# Create genotype iterator
genoIterator = GenotypeBlockIterator(genoData, snpBlock=500)

# Run association testing
if (gxE == "") {
    assoc = assocTestSingle(
        genoIterator,
        null.model = nullmod
    )
} else {
    assoc = assocTestSingle(
        genoIterator,
        null.model = nullmod,
        GxE = c(gxE)
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
out = fileOut
if (gzip) {
    out <- gzfile(fileOut + ".gz", "w")
}
write.table(
    assoc,
    file = out,
    row.names = FALSE,
    quote = FALSE,
    sep = "\t"
)
