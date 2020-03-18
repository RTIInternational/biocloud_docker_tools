#!/usr/bin/Rscript

library("vcd")

args = commandArgs(TRUE)
loop = TRUE
fileTheta = ""
fileFam = ""
filePsam = ""
fileSampleDatasetXref = ""
datasetLabel = "STUDY"
ancestryDefinitions = data.frame(
    ANCESTRY=character(),
    POP=character(),
    OPERATION=character(),
    THRESHOLD=double()
)
outPrefix = ""
refPopType = "SUPERPOP"

# Read command line arguments
while (loop) {
	# Path to terastructure theta.txt output file
	if (args[1] == "--theta") {
		fileTheta = args[2]
	}

	# Path to fam file for terastructure input
	if (args[1] == "--fam") {
		fileFam = args[2]
	}

	# Path to psam file
	if (args[1] == "--psam") {
		filePsam = args[2]
	}

	# Which reference population type to use (POP or SUPERPOP)
	if (args[1] == "--ref_pop_type") {
		refPopType = toupper(args[2])
	}

	# Dataset label (Optional)
    # Overridden by --sample_dataset_xref
	if (args[1] == "--dataset_label") {
		datasetLabel = args[2]
	}

    # Path to sample-dataset xref for non-reference samples (Optional)
    # Maps subjects to datasets
    # No header
    # Column 1 = subject ID
    # Column 2 = dataset
	if (args[1] == "--sample_dataset_xref") {
		fileSampleDatasetXref = args[2]
	}

	# Ancestry definition
    # Multiple --ancestry_definition options allowed
    # Format "[ANCESTRY]=[POP][>|<|>=|<=][THRESHOLD];...;[POP][>|<|>=|<=][THRESHOLD]"
	if (args[1] == "--ancestry_definition") {
        newAncestryDefinition = args[2]
        ancestry = gsub(".$", "", regmatches(newAncestryDefinition, regexpr("^\\S+=", newAncestryDefinition, perl=TRUE)))
        definition = gsub("^.", "", regmatches(newAncestryDefinition, regexpr("=\\S+", newAncestryDefinition, perl=TRUE)))
        definitions = strsplit(definition, ";")
        for (definition in definitions) {
            definitionPop = regmatches(definition, regexpr("^\\S\\S\\S", definition, perl=TRUE))
            definitionOperation = regmatches(definition, regexpr("[<>][=]*", definition, perl=TRUE))
            definitionThreshold = as.double(regmatches(definition, regexpr("\\d*\\.?\\d*$", definition, perl=TRUE)))
            newFilterGroupCriterion = data.frame(ancestry, definitionPop, definitionOperation, definitionThreshold, stringsAsFactors=FALSE)
            colnames(newFilterGroupCriterion) = c("ANCESTRY", "POP", "OPERATION", "THRESHOLD")
            ancestryDefinitions = rbind(ancestryDefinitions, newFilterGroupCriterion)
        }
	}

	# Output prefix
	if (args[1] == "--out_prefix") {
		outPrefix = args[2]
	}

	if (length(args) > 1) {
		args = args[2:length(args)]
	} else {
		loop=FALSE
	}
}

generateTrianglePlot = function(outPrefix, theta, refPops) {

    # Get color palette
    cohorts = unique(theta$DATASET)
    cohortCount = length(cohorts)
    colors = rainbow(cohortCount)
    colorMap = data.frame(cohorts, colors)
    colnames(colorMap) = c("DATASET", "COLOR")
    colorMap$COLOR = substr(colorMap$COLOR, 1, 7)

    # Assign colors to study results
    theta = merge(theta, colorMap, sort=FALSE)

    # Open png file
    png(
        paste0(outPrefix, "_triangle.png"),
        width=800,
        height=800,
        type="cairo"
    )

    # Generate triangle plot
    ternaryplot(
        theta[,refPops],
        col=theta$COLOR,
        scale=1,
        grid=FALSE,
        dimnames=refPops,
        cex=0.4,
        main=""
    )

    # Generate legend
    grid_legend(
        "right",
        pch=rep(19,nrow(colorMap)),
        col=colorMap$COLOR,
        labels=colorMap$DATASET
    )

    # Close png file
    dev.off()

}

# Read theta.txt
theta = read.table(fileTheta)

# Read fam file
fam = read.table(fileFam)
colnames(fam) = c("FID", "IID", "PID", "MID", "SEX", "PHENO")

# Read psam file
psam = read.table(filePsam)
colnames(psam) = c("IID", "SEX", "SUPERPOP", "POP")

# Extract ID and population columns from psam
psam = psam[,c("IID", refPopType)]

# Add IDs to theta
theta$FID = fam$FID
theta$IID = fam$IID

# Split theta into reference and dataset
thetaRef = theta[theta$IID %in% psam$IID,]
thetaDataset = theta[!(theta$IID %in% thetaRef$IID),]
if (nrow(thetaDataset) == 0) {
    stop("No subjects in dataset")
}

# Add population to thetaRef
thetaRef = merge(psam, thetaRef, by.x="IID", by.y="IID", sort=FALSE)

# Get ref group means
groupMeans = aggregate(thetaRef[, 3:(ncol(thetaRef)-1)], list(thetaRef[,refPopType]), mean)
rownames(groupMeans) = groupMeans$Group.1
groupMeans$Group.1 = NULL

# Assign column names to results
refPops = rownames(groupMeans)[apply(groupMeans,2,which.max)]
colnames(thetaDataset) = c(refPops, "FID", "IID")
colnames(thetaRef) = c("IID", refPopType, refPops, "FID")

# Add dataset labels to dataset results
if (fileSampleDatasetXref == "") {
    thetaDataset$DATASET = datasetLabel
} else {
    sampleDatasetXref = read.table(fileSampleDatasetXref)
    colnames(sampleDatasetXref) = c("IID", "DATASET")
    thetaDataset = merge(thetaDataset, sampleDatasetXref, sort=FALSE)
}

# Write reference theta results
write.table(
    thetaRef[, c("FID", "IID", refPopType, refPops)],
    file=paste0(outPrefix,"_ref_theta.tsv"),
    quote=FALSE,
    sep="\t",
    row.names=FALSE
)

# Write dataset theta results for each dataset
datasets = unique(thetaDataset$DATASET)
for (dataset in datasets) {
    write.table(
        thetaDataset[thetaDataset$DATASET == dataset, c("FID", "IID", "DATASET", refPops)],
        file=paste0(outPrefix,"_",tolower(dataset),"_theta.tsv"),
        quote=FALSE,
        sep="\t",
        row.names=FALSE
    )
}

# Generate triangle plot with all datasets
generateTrianglePlot(outPrefix, thetaDataset, refPops)

# Generate overall triangle plot for each dataset
for (dataset in datasets) {
    generateTrianglePlot(paste0(outPrefix,"_",tolower(dataset)), thetaDataset[thetaDataset$DATASET == dataset, ], refPops)
}

# Generate keep lists for each dataset and generate ancestry-specific triangle plots
for (dataset in datasets) {

    ancestries = unique(ancestryDefinitions$ANCESTRY)
    for (ancestry in ancestries) {

        # Filter
        thisAncestryDefinition = ancestryDefinitions[ancestryDefinitions$ANCESTRY == ancestry,]
        thisThetaDataset = thetaDataset[thetaDataset$DATASET == dataset, ]
        for (row in 1:nrow(thisAncestryDefinition)) {
            if (thisAncestryDefinition[row, "POP"] %in% colnames(thisThetaDataset)) {
                if (thisAncestryDefinition[row, "OPERATION"] == ">") {
                    thisThetaDataset = thisThetaDataset[thisThetaDataset[,thisAncestryDefinition[row, "POP"]] > thisAncestryDefinition[row, "THRESHOLD"],]
                } else if (thisAncestryDefinition[row, "OPERATION"] == ">=") {
                    thisThetaDataset = thisThetaDataset[thisThetaDataset[,thisAncestryDefinition[row, "POP"]] >= thisAncestryDefinition[row, "THRESHOLD"],]
                } else if (thisAncestryDefinition[row, "OPERATION"] == "<") {
                    thisThetaDataset = thisThetaDataset[thisThetaDataset[,thisAncestryDefinition[row, "POP"]] < thisAncestryDefinition[row, "THRESHOLD"],]
                } else if (thisAncestryDefinition[row, "OPERATION"] == "<=") {
                    thisThetaDataset = thisThetaDataset[thisThetaDataset[,thisAncestryDefinition[row, "POP"]] <= thisAncestryDefinition[row, "THRESHOLD"],]
                }
            } else {
                stop(paste("Ancestry definition",thisAncestryDefinition[row,"ANCESTRY"],"population",thisAncestryDefinition[row,"POP"],"not valid"))
            }
        }

        # Write keep list
        write.table(
            thisThetaDataset[, c("FID", "IID")],
            file=paste0(outPrefix,"_",tolower(dataset),"_",tolower(ancestry),".keep"),
            quote=FALSE,
            sep="\t",
            row.names=FALSE,
            col.names=FALSE
        )

        # Generate triangle plot
        thisThetaDataset$DATASET = paste(thisThetaDataset$DATASET, ancestry)
        generateTrianglePlot(paste0(outPrefix,"_",tolower(dataset),"_",tolower(ancestry)), thisThetaDataset, refPops)

    }

}
