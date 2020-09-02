#!/usr/local/bin/Rscript

library(gds2bgen)

args <- commandArgs(TRUE)

loop = TRUE
fileInBgen = ""
fileOutGds = ""
storageOption = "LZMA_RA"
floatType = "double"
geno = FALSE
dosage = FALSE
prob = FALSE
optimize = FALSE
parallel = 8

while (loop) {

	if (args[1] == "--in_bgen") {
		fileInBgen = args[2]
	}

	if (args[1] == "--out_gds") {
		fileOutGds = args[2]
	}

	if (args[1] == "--storage-option") {
		storageOption = args[2]
	}

	if (args[1] == "--float-type") {
		floatType = args[2]
	}

	if (args[1] == "--geno") {
		geno = toupper(args[2])
	}

	if (args[1] == "--dosage") {
		dosage = toupper(args[2])
	}

	if (args[1] == "--prob") {
		prob = toupper(args[2])
	}

	if (args[1] == "--optimize") {
		optimize = toupper(args[2])
	}

	if (args[1] == "--parallel") {
		parallel = args[2]
	}

	if (length(args) > 1) {
		args = args[2:length(args)]
	} else {
		loop=FALSE
	}

}

seqBGEN2GDS(
    fileInBgen,
    fileOutGds,
    storage.option=storageOption,
    float.type=floatType,
    geno=geno,
    dosage=dosage,
    prob=prob,
	optimize=optimize,
	digest=TRUE,
    parallel=parallel,
	verbose=TRUE
)

