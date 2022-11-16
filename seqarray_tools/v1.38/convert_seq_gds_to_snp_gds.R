#!/usr/local/bin/Rscript

library(SeqArray)

args <- commandArgs(TRUE)

loop = TRUE
fileInSeqGds = ""
fileOutSnpGds = ""
compressGeno = "ZIP_RA"
optimize = FALSE
dosage = FALSE

while (loop) {

	if (args[1] == "--in-seq-gds") {
		fileInSeqGds = args[2]
	}

	if (args[1] == "--out-snp-gds") {
		fileOutSnpGds = args[2]
	}

	if (args[1] == "--compress-geno") {
		compressGeno = args[2]
	}

	if (args[1] == "--optimize") {
		optimize = TRUE
	}

	if (args[1] == "--dosage") {
		dosage = TRUE
	}

	if (length(args) > 1) {
		args = args[2:length(args)]
	} else {
		loop=FALSE
	}

}

seqGDS2SNP(
    fileInSeqGds,
    fileOutSnpGds,
    compress.geno=compressGeno,
    compress.annotation=compressGeno,
    optimize=optimize,
    verbose=TRUE,
    dosage=dosage
)

