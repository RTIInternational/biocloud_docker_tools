#!/usr/bin/Rscript

library(SNPRelate)

args <- commandArgs(TRUE)

loop = TRUE
fileInVcf = ""
fileOutGds = ""

while (loop) {

	if (args[1] == "--in") {
		fileInVcf = args[2]
	}

	if (args[1] == "--out") {
		fileOutGds = args[2]
	}

	if (length(args) > 1) {
		args = args[2:length(args)]
	} else {
		loop=FALSE
	}

}

snpgdsVCF2GDS(fileInVcf, fileOutGds, verbose=TRUE)


