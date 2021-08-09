#!/usr/bin/Rscript

# v8 changes:
#   - Added --qq_significance_line parameter

args <- commandArgs(TRUE)

loop = TRUE
hasInFile = FALSE
hasInFileTemplate = FALSE
hasInFileSnp = FALSE
hasInFileSnpTemplate = FALSE
hasInFileIndel = FALSE
hasInFileIndelTemplate = FALSE
hasHighlightList = FALSE
fileInSnp = ""
fileInSnpTemplate = ""
fileInIndel = ""
fileInIndelTemplate = ""
fileInCsv = FALSE
fileInHeader = FALSE
fileHighlightList = ""
hasOutPrefix = FALSE
colId = "MarkerName"
colChr = "chr"
colPos = "position"
colP = "P.value"
hasVariantTypeCol = FALSE
generateManhattanPlot = FALSE
generateSnpManhattanPlot = FALSE
generateIndelManhattanPlot = FALSE
generateSnpIndelManhattanPlot = FALSE
generateQqPlot = FALSE
generateSnpQqPlot = FALSE
generateIndelQqPlot = FALSE
generateSnpIndelQqPlot = FALSE
generateDataTable = FALSE
manhattanYLimit=0
manhattanPlotSigLine = TRUE
manhattanOddChrColor = "gray65"
manhattanEvenChrColor = "gray10"
manhattanHighlightColor = "red"
manhattanPointsCex = 1
manhattanSnpPch = 1
manhattanIndelPch = 2
manhattanPch = 1
manhattanCexAxis = 1.2
manhattanCexLab = 1.2
qqIncludeLines = FALSE
qqIncludeSignificanceLine = FALSE
qqBgPoints = "white"
chiDf=1
qqLambda = FALSE

while (loop) {

	if (args[1] == "--in") {
		fileIn = args[2]
		hasInFile = TRUE
	}

	# For templates, insert "__CHR__" in file name where chromosome # should be. Use --in_chromosomes to specify which chromosomes #s should be loaded.
	if (args[1] == "--in_template") {
		fileInTemplate = args[2]
		hasInFileTemplate = TRUE
	}

	if (args[1] == "--in_snp") {
		fileInSnp = args[2]
		hasInFileSnp = TRUE
	}

	if (args[1] == "--in_snp_template") {
		fileInSnpTemplate = args[2]
		hasInFileSnpTemplate = TRUE
	}

	if (args[1] == "--in_indel") {
		fileInIndel = args[2]
		hasInFileIndel = TRUE
	}

	if (args[1] == "--in_indel_template") {
		fileInIndelTemplate = args[2]
		hasInFileIndelTemplate = TRUE
	}

	if (args[1] == "--in_chromosomes") {
		if (args[2] == "autosomal") {
			inChr=c(1:22)
		} else if (args[2] == "autosomal_nonPAR") {
			inChr=c(1:23)
    }
	}

	if (args[1] == "--in_csv") {
		fileInCsv = TRUE
	}

	if (args[1] == "--in_header") {
		fileInHeader = TRUE
	}

	if (args[1] == "--highlight_list") {
		fileHighlightList = args[2]
		hasHighlightList = TRUE
	}

	if (args[1] == "--out") {
		outPrefix = args[2]
		hasOutPrefix = TRUE
	}

	if (args[1] == "--col_id") {
		colId = gsub("-",".",args[2])
	}

	if (args[1] == "--col_chromosome") {
		colChr = gsub("-",".",args[2])
	}

	if (args[1] == "--col_position") {
		colPos = gsub("-",".",args[2])
	}

	if (args[1] == "--col_p") {
		colP = gsub("-",".",args[2])
	}

	if (args[1] == "--col_variant_type") {
		colVariantType = gsub("-",".",args[2])
		hasVariantTypeCol = TRUE
	}

	if (args[1] == "--generate_manhattan_plot") {
		generateManhattanPlot = TRUE
	}

	if (args[1] == "--generate_snp_manhattan_plot") {
		generateSnpManhattanPlot = TRUE
	}

	if (args[1] == "--generate_indel_manhattan_plot") {
		generateIndelManhattanPlot = TRUE
	}

	if (args[1] == "--generate_snp_indel_manhattan_plot") {
		generateSnpIndelManhattanPlot = TRUE
	}

	if (args[1] == "--manhattan_no_line") {
		manhattanPlotSigLine = FALSE
	}

	if (args[1] == "--manhattan_ylim") {
		manhattanYLimit = as.numeric(args[2])
	}

	if (args[1] == "--manhattan_odd_chr_color") {
		manhattanOddChrColor = args[2]
	}

	if (args[1] == "--manhattan_even_chr_color") {
		manhattanEvenChrColor = args[2]
	}

	if (args[1] == "--manhattan_highlight_color") {
		manhattanHighlightColor = args[2]
	}

	if (args[1] == "--manhattan_points_cex") {
		manhattanPointsCex = as.numeric(args[2])
	}

	if (args[1] == "--manhattan_snp_pch") {
		manhattanSnpPch = as.numeric(args[2])
	}

	if (args[1] == "--manhattan_indel_pch") {
		manhattanIndelPch = as.numeric(args[2])
	}

	if (args[1] == "--manhattan_pch") {
		manhattanPch = as.numeric(args[2])
	}

	if (args[1] == "--manhattan_cex_axis") {
		manhattanCexAxis = as.numeric(args[2])
	}

	if (args[1] == "--manhattan_cex_lab") {
		manhattanCexLab = as.numeric(args[2])
	}

	if (args[1] == "--generate_qq_plot") {
		generateQqPlot = TRUE
	}

	if (args[1] == "--generate_snp_qq_plot") {
		generateSnpQqPlot = TRUE
	}

	if (args[1] == "--generate_indel_qq_plot") {
		generateIndelQqPlot = TRUE
	}

	if (args[1] == "--generate_snp_indel_qq_plot") {
		generateSnpIndelQqPlot = TRUE
	}

	if (args[1] == "--qq_lines") {
		qqIncludeLines = TRUE
	}

	if (args[1] == "--qq_significance_line") {
		qqIncludeSignificanceLine = TRUE
	}

	if (args[1] == "--qq_points_bg") {
		qqBgPoints = args[2]
	}

	if (args[1] == "--qq_lambda") {
		qqLambda = TRUE
	}

	if (args[1] == "--chi2_df") {
		chiDf = as.numeric(args[2])
	}

	if (args[1] == "--generate_data_table") {
		generateDataTable = TRUE
	}

	if (length(args) > 1) {
		args = args[2:length(args)]
	} else {
		loop=FALSE
	}
}

if ((generateManhattanPlot || generateQqPlot) && !(hasInFile || hasInFileTemplate || hasInFileSnp || hasInFileSnpTemplate || hasInFileIndel || hasInFileIndelTemplate)) {
	stop("No input file specified")
} else if ((generateSnpManhattanPlot || generateSnpQqPlot || generateSnpIndelManhattanPlot || generateSnpIndelQqPlot) && !(hasInFileSnp || hasInFileSnpTemplate || ((hasInFile || hasInFileTemplate) && hasVariantTypeCol))) {
	stop("No SNP input specified")
} else if ((generateIndelManhattanPlot || generateIndelQqPlot || generateSnpIndelManhattanPlot || generateSnpIndelQqPlot) && !(hasInFileIndel || hasInFileIndelTemplate || ((hasInFile || hasInFileTemplate) && hasVariantTypeCol))) {
	stop("No INDEL input specified")
} else if (hasInFile && hasInFileTemplate) {
	stop("--in and --in_template are mutually exclusive\n")
} else if (hasInFile && hasInFileSnp) {
	stop("--in and --in_snp are mutually exclusive\n")
} else if (hasInFile && hasInFileSnpTemplate) {
	stop("--in and --in_snp_template are mutually exclusive\n")
} else if (hasInFile && hasInFileIndel) {
	stop("--in and --in_indel are mutually exclusive\n")
} else if (hasInFile && hasInFileIndelTemplate) {
	stop("--in and --in_indel_template are mutually exclusive\n")
} else if (hasInFileTemplate && hasInFileSnp) {
	stop("--in_template and --in_snp are mutually exclusive\n")
} else if (hasInFileTemplate && hasInFileSnpTemplate) {
	stop("--in_template and --in_snp_template are mutually exclusive\n")
} else if (hasInFileTemplate && hasInFileIndel) {
	stop("--in_template and --in_indel are mutually exclusive\n")
} else if (hasInFileTemplate && hasInFileIndelTemplate) {
	stop("--in_template and --in_indel_template are mutually exclusive\n")
} else if (hasInFileSnp && hasInFileSnpTemplate) {
	stop("--in_snp and --in_snp_template are mutually exclusive\n")
} else if (hasInFileIndel && hasInFileIndelTemplate) {
	stop("--in_indel and --in_indel_template are mutually exclusive\n")
} else if (!hasOutPrefix) {
	stop("No output file specified")
}

if (hasInFile) {
	cat("Reading ", fileIn, "...\n", sep = "")
	if (fileInCsv) {
		inputData = read.csv(fileIn, header = fileInHeader)
	} else {
		inputData = read.table(fileIn, header = fileInHeader)
	}
	if (hasVariantTypeCol) {
    inputData = inputData[c(colId,colChr,colPos,colP,colVariantType)]
		inputData[,colVariantType] = tolower(inputData[,colVariantType])
	} else {
		inputData = inputData[c(colId,colChr,colPos,colP)]
	}
} else if (hasInFileTemplate) {
  for (currentChr in inChr) {
    fileIn = gsub("__CHR__",currentChr,fileInTemplate)
    cat("Reading ", fileIn, "...\n", sep = "")
    if (fileInCsv) {
      tmpInputData = read.csv(fileIn, header = fileInHeader)
    } else {
      tmpInputData = read.table(fileIn, header = fileInHeader)
    }
    if (hasVariantTypeCol) {
      tmpInputData = tmpInputData[c(colId,colChr,colPos,colP,colVariantType)]
      tmpInputData[,colVariantType] = tolower(tmpInputData[,colVariantType])
    } else {
      tmpInputData = tmpInputData[c(colId,colChr,colPos,colP)]
    }
    if (exists("inputData")) {
      inputData = rbind(inputData, tmpInputData)
    } else {
      inputData = tmpInputData
    }
  }
 	rm(tmpInputData)
} else if (hasInFileSnp || hasInFileIndel) {
	variantType = "snp"
	for (file in c(fileInSnp, fileInIndel)) {
		if (file != "") {
			inputData = inputData[c(colId,colChr,colPos,colP)]
			inputData$type = variantType
		}
		variantType = "indel"
	}
	colVariantType="type"
	hasVariantTypeCol = TRUE
} else {
	variantType = "snp"
	for (template in c(fileInSnpTemplate, fileInIndelTemplate)) {
		if (template != "") {
			for (currentChr in inChr) {
				fileIn = gsub("__CHR__",currentChr,template)
				cat("Reading ", fileIn, "...\n", sep = "")
				if (fileInCsv) {
					tmpInputData = read.csv(fileIn, header = fileInHeader)
				} else {
					tmpInputData = read.table(fileIn, header = fileInHeader)
				}
				tmpInputData = tmpInputData[c(colId,colChr,colPos,colP)]
				tmpInputData$type = variantType
				if (exists("inputData")) {
					inputData = rbind(inputData, tmpInputData)
				} else {
					inputData = tmpInputData
				}
			}
		}
		variantType = "indel"
	}
	rm(tmpInputData)
	colVariantType="type"
	hasVariantTypeCol = TRUE
}

if (hasHighlightList) {
	cat("Reading ", fileHighlightList, "...\n", sep = "")
	highlightList = read.table(fileHighlightList)
}

if (exists("inputData") && nrow(inputData) != 0) {
  attach(inputData)
  inputData = inputData[complete.cases(inputData),]
  inputData = inputData[inputData[,colP] != 0,]
  inputData = inputData[order(inputData[,colChr], inputData[,colPos]),]
	if (generateDataTable) {
		cat("Writing data table...\n")
		fileOut = paste(outPrefix,".table",sep="")
		write.table(inputData, file = fileOut, row.names = FALSE, quote = FALSE)
	}
	if (generateManhattanPlot || generateSnpManhattanPlot || generateIndelManhattanPlot || generateSnpIndelManhattanPlot) {
    inputData[inputData[,colChr] %% 2 == 0, "color"] = manhattanEvenChrColor
    inputData[inputData[,colChr] %% 2 != 0, "color"] = manhattanOddChrColor
    if (hasHighlightList) {
      inputData[inputData[,colId] %in% highlightList$V1, "color"] = manhattanHighlightColor
    }
    if (hasVariantTypeCol) {
      inputData[inputData[,colVariantType]=="snp","pch"] = manhattanSnpPch
      inputData[inputData[,colVariantType]=="indel","pch"] = manhattanIndelPch
    } else {
      inputData[,"pch"] = manhattanPch
    }
		snpNum = table(inputData[,colChr])
		snpStart = cumsum(snpNum)
		snpStart = c(1,snpStart[-length(snpStart)] + 1)
		snpEnd = snpStart + snpNum - 1
		chrLen = (as.numeric(inputData[snpEnd,colPos]) - as.numeric(inputData[snpStart,colPos]))
		chrStart = cumsum(chrLen)
		chrStart = c(1, chrStart[-length(chrStart)]+1)
		lobs = -(log10(as.numeric(inputData[,colP])))
    if (manhattanYLimit == 0) {
      maxLobs = max(lobs, na.rm=TRUE)
      if (maxLobs <= 8) {
        manhattanYLimit = 9
      } else {
        manhattanYLimit = ceiling(maxLobs + 1)
      }
    }
		xpos = chrStart[as.numeric(as.factor(inputData[,colChr]))] + as.numeric(inputData[,colPos])- as.numeric(inputData[snpStart[as.numeric(as.factor(inputData[,colChr]))],colPos])
    manhattanPlot = function(fileOut, hasHighlightList = FALSE, nonHighlightIndices = NULL, highlightIndices = NULL) {
      png(fileOut, width = 1440, height = 800, type="cairo")
      par(mar = c(5.1,5.1,4.1,2.1), cex.axis=manhattanCexAxis, cex.lab=manhattanCexLab)
			plot(c(min(xpos),max(xpos)),c(min(lobs),manhattanYLimit),type='n',ylab=expression(-log~""["10"]~"(P)"),xlab='Position (by chromosome)',xaxt='n',ylim=c(0,manhattanYLimit))
      points(xpos[nonHighlightIndices],lobs[nonHighlightIndices],col=inputData[nonHighlightIndices,"color"],cex=manhattanPointsCex,pch=inputData[nonHighlightIndices,"pch"])
      if (hasHighlightList) {
        points(xpos[highlightIndices],lobs[highlightIndices],col=inputData[highlightIndices,"color"],cex=manhattanPointsCex,pch=inputData[highlightIndices,"pch"])
      }
			if (manhattanPlotSigLine) {
				abline(h=7.3)
			}
      #abline(h=6, lty=3)
			loc = chrStart+chrLen/2
			mtext(as.numeric(names(snpNum)),side=1,at=loc,line=0.5,cex=manhattanCexAxis,par(las=3))
			dev.off()
    }
		if (generateManhattanPlot) {
      cat("Generating Manhattan plot...\n")
      fileOut = paste(outPrefix, ".manhattan.png", sep="")
      if (hasHighlightList) {
        nonHighlightIndices = inputData[,"color"]!= manhattanHighlightColor
        highlightIndices = inputData[,"color"]== manhattanHighlightColor
        manhattanPlot(fileOut, hasHighlightList=TRUE, nonHighlightIndices, highlightIndices)
      } else {
        nonHighlightIndices = rep(TRUE,nrow(inputData))
        manhattanPlot(fileOut, nonHighlightIndices=nonHighlightIndices)
      }
    }
		if (generateSnpIndelManhattanPlot) {
      cat("Generating SNP+INDEL Manhattan plot...\n")
      fileOut = paste(outPrefix, ".snps+indels.manhattan.png", sep="")
      if (hasHighlightList) {
        nonHighlightIndices = inputData[,"color"]!= manhattanHighlightColor
        highlightIndices = inputData[,"color"]== manhattanHighlightColor
        manhattanPlot(fileOut, hasHighlightList=TRUE, nonHighlightIndices, highlightIndices)
      } else {
        nonHighlightIndices = rep(TRUE,nrow(inputData))
        manhattanPlot(fileOut, nonHighlightIndices=nonHighlightIndices)
      }
    }
		if (generateSnpManhattanPlot) {
			cat("Generating SNP Manhattan plot...\n")
			fileOut = paste(outPrefix, ".snps.manhattan.png", sep="")
      if (hasHighlightList) {
        nonHighlightIndices = inputData[,colVariantType]=="snp" & inputData[,"color"]!=manhattanHighlightColor
        highlightIndices = inputData[,colVariantType]=="snp" & inputData[,"color"]==manhattanHighlightColor
        manhattanPlot(fileOut, hasHighlightList=TRUE, nonHighlightIndices, highlightIndices)
      } else {
        nonHighlightIndices = inputData[,colVariantType]=="snp"
        manhattanPlot(fileOut, nonHighlightIndices=nonHighlightIndices)
      }
		}
		if (generateIndelManhattanPlot) {
			cat("Generating INDEL Manhattan plot...\n")
			fileOut = paste(outPrefix, ".indels.manhattan.png", sep="")
      if (hasHighlightList) {
        nonHighlightIndices = inputData[,colVariantType]=="indel" & inputData[,"color"]!=manhattanHighlightColor
        highlightIndices = inputData[,colVariantType]=="indel" & inputData[,"color"]==manhattanHighlightColor
        manhattanPlot(fileOut, hasHighlightList=TRUE, nonHighlightIndices, highlightIndices)
      } else {
        nonHighlightIndices = inputData[,colVariantType]=="indel"
        manhattanPlot(fileOut, nonHighlightIndices=nonHighlightIndices)
      }
		}
	}
  if (generateQqPlot || generateSnpIndelQqPlot || generateSnpQqPlot || generateIndelQqPlot) {
    qqPlot = function(fileOut, pValues, qqIncludeLines, qqLambda, chiDf) {
      observed = sort(pValues)
      lobs = -(log10(observed))
      lobs = subset(lobs,lobs<Inf)
      n = length(lobs)
      expected = c(1:n)
      lexp = -(log10(expected/(n+1)))
      alpha = 0.05
      lower = qbeta(alpha/2,expected,n+1-expected)
      upper = qbeta((1-alpha/2),expected,n+1-expected)
      expect = (expected-0.5)/n
      png(fileOut, width = 1000, height = 1000, type="cairo")
      par(mar = c(5.1,5.1,4.1,2.1))
      par(cex.axis=1.5)
      par(cex.lab=1.5)
      par(cex.main=1.5)
      par(font.main=1)
      if (qqLambda) {
        lambda = round(qchisq(median(pValues[,1]),chiDf,lower.tail=FALSE)/qchisq(0.5,chiDf,lower.tail=FALSE),3)
        plot(c(0,max(lobs,lexp)+1), c(0,max(lobs,lexp)+1), col="red", lwd=3, type="l", main=paste("lambda =",lambda), xlab=expression(-log~""["10"]~"(Expected p-value)"), ylab=expression(-log~""["10"]~"(Observed p-value)"), xlim=c(0,max(lobs,lexp)+1), ylim=c(0,max(lobs,lexp)+1), las=1, xaxs="i", yaxs="i", bty="l")
      } else {
        plot(c(0,max(lobs,lexp)+1), c(0,max(lobs,lexp)+1), col="red", lwd=3, type="l", xlab=expression(-log~""["10"]~"(Expected p-value)"), ylab=expression(-log~""["10"]~"(Observed p-value)"), xlim=c(0,max(lobs,lexp)+1), ylim=c(0,max(lobs,lexp)+1), las=1, xaxs="i", yaxs="i", bty="l")
      }
      points(lexp, lobs, pch=23, cex=.5, bg=qqBgPoints)
      if (qqIncludeLines) {
        lines(-log10(expect),-log10(lower),lty=2)
        lines(-log10(expect),-log10(upper),lty=2)
      }
      if (qqIncludeSignificanceLine) {
        abline(h=7.3)
      }
      dev.off()
      cat("Checkpoint 4\n")
    }
    if (generateQqPlot) {
      cat("Generating QQ plot...\n")
      qqPlot(paste(outPrefix, ".qq.png", sep=""), as.matrix(as.numeric(na.omit(inputData[,colP]))), qqIncludeLines, qqLambda, chiDf)
    }
    if (generateSnpIndelQqPlot) {
      cat("Generating SNP+INDEL QQ plot...\n")
      qqPlot(paste(outPrefix, ".snps+indels.qq.png", sep=""), as.matrix(as.numeric(na.omit(inputData[,colP]))), qqIncludeLines, qqLambda, chiDf)
      cat("Checkpoint 5\n")
    }
    if (generateSnpQqPlot) {
      cat("Generating SNP QQ plot...\n")
      qqPlot(paste(outPrefix, ".snps.qq.png", sep=""), as.matrix(as.numeric(na.omit(inputData[inputData[,colVariantType]=="snp",colP]))), qqIncludeLines, qqLambda, chiDf)
    }
    if (generateIndelQqPlot) {
      cat("Generating INDEL QQ plot...\n")
      qqPlot(paste(outPrefix, ".indels.qq.png", sep=""), as.matrix(as.numeric(na.omit(inputData[inputData[,colVariantType]=="indel",colP]))), qqIncludeLines, qqLambda, chiDf)
    }
  }
  detach(inputData)
} else {
	stop("No input data")
}

cat("Done\n")

