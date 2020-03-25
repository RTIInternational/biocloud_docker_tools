#!/usr/bin/Rscript

library("vcd")
library("ggplot2")
library("reshape2")

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

generateBarPlot = function(outPrefix, theta, refPops, refPopType) {
  
  # Get color palette
  colors = rainbow(length(refPops))

  # Replace SUPERPOP/POP with Dataset for thetaRef datasets
  if(!"DATASET" %in% colnames(theta)){
    theta$DATASET = theta[[refPopType]]
  }
  # Add a sample id column
  theta$SAMPLE = paste0(theta$FID,"_",theta$IID)
  
  # Order samples in descending order of largest ancestry
  anc_perc = sapply(refPops, function(pop){sum(theta[[pop]])})
  names(anc_perc) = refPops
  top_anc = names(anc_perc)[order(anc_perc, decreasing=T)][1]
  
  # Re-order samples based on percentage of top ancestry
  theta$SAMPLE = factor(theta$SAMPLE, levels=theta$SAMPLE[order(theta[[top_anc]], decreasing=T)])
  
  # Subset to only include columns you want
  cols_to_keep = c("SAMPLE", "DATASET", refPops)
  theta = theta[,cols_to_keep]
  # Melt to get dataset in long format 
  theta = melt(theta, id.vars=c("SAMPLE", "DATASET"))
  # Rename variable/value created melting
  colnames(theta) = c("SAMPLE", "DATASET", "ANCESTRY", "THETA")
  
  # Open png file
  png(
    paste0(outPrefix, "_barplot.png"),
    width=800,
    height=800,
    type="cairo"
  )
  
  plot = ggplot(theta, aes(y = THETA, x = SAMPLE, fill = ANCESTRY)) + geom_bar(position="fill",stat="identity") +
    scale_fill_manual(values=colors) + 
    facet_grid(~ DATASET, scales = "free", space = "free") + 
    theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank())
  print(plot)
  dev.off()
}

plot_ancestry = function(outPrefix, theta, refPops, refPopType){
  if(length(refPops) == 3){
    generateTrianglePlot(outPrefix, theta, refPops)
  }else{
    generateBarPlot(outPrefix, theta, refPops, refPopType)
  }
}

is_ancestry_class = function(sample_row, ancestry, thisThetaDataset, ancestryDefinitions){
  # Return whether sample in thisThetaDataset would be classified as an ancestry type based on ancestry definitions
  if(!ancestry %in% ancestryDefinitions$ANCESTRY){
    stop(paste0("Ancestry not defined in ancestry definitions: ", ancestry))
  }
  thisAncestryDefinition = ancestryDefinitions[ancestryDefinitions$ANCESTRY == ancestry,]
  sample_thetas = thisThetaDataset[sample_row,]
  is_ancestry = TRUE
  for (row in 1:nrow(thisAncestryDefinition)) {
    # Throw error if ancestry not in theta dataset
    if (!thisAncestryDefinition[row, "POP"] %in% colnames(thisThetaDataset)){
      stop(paste("Ancestry definition",thisAncestryDefinition[row,"ANCESTRY"],"population",thisAncestryDefinition[row,"POP"],"not valid"))
    }else if (thisAncestryDefinition[row, "OPERATION"] == ">") {
      is_ancestry = is_ancestry && thisThetaDataset[sample_row,thisAncestryDefinition[row, "POP"]] > thisAncestryDefinition[row, "THRESHOLD"]
    } else if (thisAncestryDefinition[row, "OPERATION"] == ">=") {
      is_ancestry = is_ancestry && thisThetaDataset[sample_row,thisAncestryDefinition[row, "POP"]] >= thisAncestryDefinition[row, "THRESHOLD"]
    } else if (thisAncestryDefinition[row, "OPERATION"] == "<") {
      is_ancestry = is_ancestry && thisThetaDataset[sample_row,thisAncestryDefinition[row, "POP"]] < thisAncestryDefinition[row, "THRESHOLD"]
    } else if (thisAncestryDefinition[row, "OPERATION"] == "<=") {
      is_ancestry = is_ancestry && thisThetaDataset[sample_row,thisAncestryDefinition[row, "POP"]] <= thisAncestryDefinition[row, "THRESHOLD"]
    }
  }
  return(is_ancestry)
}

classify_sample = function(sample_row, thisThetaDataset, ancestryDefinitions){
  # Apply ancestry definitions and determine sample classification
  ancestries = unique(ancestryDefinitions$ANCESTRY)
  classifications = sapply(ancestries, function(anc) is_ancestry_class(sample_row, anc, thisThetaDataset, ancestryDefinitions))
  class = ancestries[which(classifications)]
  if(length(class) == 0){
    return("UNCLASSIFIED")
  }else if(length(class) > 1){
    return("MULTI_CLASSIFIED")
  }else{
    return(class[1])
  }
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

# Ancestries to classify
ancestries = unique(ancestryDefinitions$ANCESTRY)

# Log some info
print(paste0("Total ref samples: ", nrow(thetaRef)))
print(paste0("Total study samples: ", nrow(thetaDataset)))
ancestry_string = paste(ancestries)
print(paste0("Ancestries considered: ", ancestry_string))
print("Ancestry definitions:")
print(ancestryDefinitions)

# Classify reference samples
thetaRef$CLASS = sapply(1:nrow(thetaRef), function(row){
  classify_sample(row, thetaRef, ancestryDefinitions)
})
# Include dummy column to make the plotting work for ref dataset
thetaRef$DATASET = thetaRef[[refPopType]]

# Classify dataset samples
thetaDataset$CLASS = sapply(1:nrow(thetaDataset), function(row){
  classify_sample(row, thetaDataset, ancestryDefinitions)
})

# Indicate ref samples that were missclassified
thetaRef$MISCLASSIFIED = thetaRef[[refPopType]] != thetaRef$CLASS 
print(paste0("Unsclassified reference samples: ", length(which(thetaRef$CLASS == "UNCLASSIFIED"))))
print(paste0("Multi-classified reference samples: ", length(which(thetaRef$CLASS == "MULTI_CLASSIFIED"))))
print(paste0("Total Misclassified reference samples: ", length(which(thetaRef$MISCLASSIFIED))))

# Generate triangle plot for ref samples
plot_ancestry(paste0(outPrefix,"_ref"), thetaRef, refPops, refPopType)

# Write reference theta results
write.table(
    thetaRef[, c("FID", "IID", refPopType, refPops, "CLASS", "MISCLASSIFIED")],
    file=paste0(outPrefix,"_ref_theta.tsv"),
    quote=FALSE,
    sep="\t",
    row.names=FALSE
)

# Generate trianlge plots for ref data samples that were missclassified
if(length(which(thetaRef$MISCLASSIFIED)) > 0){
  plot_ancestry(paste0(outPrefix,"_ref_misclassified"), thetaRef[thetaRef$MISCLASSIFIED,], refPops, refPopType)
}

# Write misclassified ref samples
write.table(
  thetaRef[thetaRef$MISCLASSIFIED, c("FID", "IID")],
  file=paste0(outPrefix,"_ref_misclassified.txt"),
  quote=FALSE,
  sep="\t",
  row.names=FALSE,
  col.names=FALSE
)

# Write dataset theta results for each dataset
datasets = unique(thetaDataset$DATASET)
for (dataset in datasets) {
    thetaDS = thetaDataset[thetaDataset$DATASET == dataset,]
    
    # Generate triangle plot for dataset
    plot_ancestry(paste0(outPrefix,"_",tolower(dataset)), thetaDS, refPops, refPopType)
    
    # Write datset theta results
    write.table(
        thetaDS[,c("FID", "IID", "DATASET", refPops, "CLASS")],
        file=paste0(outPrefix,"_",tolower(dataset),"_theta.tsv"),
        quote=FALSE,
        sep="\t",
        row.names=FALSE
    )
    
    # Make dataset unclassified triangle plot
    thetaDS = thetaDS[thetaDS$CLASS %in% c("UNCLASSIFIED", "MULTI_CLASSIFIED"),]
    print(paste0("Total unclassified data samples (",dataset,"): ", nrow(thetaDS)))
    if(nrow(thetaDS) > 0){
      plot_ancestry(paste0(outPrefix,"_",tolower(dataset),"_unclassified"), thetaDS, refPops, refPopType)
    }
    
    # Write unclassified theta results
    write.table(
      thetaDS[, c("FID", "IID")],
      file=paste0(outPrefix,"_",tolower(dataset),"_unclassified.txt"),
      quote=FALSE,
      sep="\t",
      row.names=FALSE,
      col.names=FALSE
    )
}


# Generate keep lists for each dataset and generate ancestry-specific triangle plots
for (dataset in datasets) {
    for (ancestry in ancestries) {
        thisThetaDataset = thetaDataset[(thetaDataset$DATASET == dataset) & (thetaDataset$CLASS == ancestry),]
        
        # Write keep list
        write.table(
            thisThetaDataset[, c("FID", "IID")],
            file=paste0(outPrefix,"_",tolower(dataset),"_",tolower(ancestry),".keep"),
            quote=FALSE,
            sep="\t",
            row.names=FALSE,
            col.names=FALSE
        )

        # Generate triangle plot for the data samples
        if(nrow(thisThetaDataset) > 0){
          thisThetaDataset$DATASET = paste(thisThetaDataset$DATASET, ancestry)
          plot_ancestry(paste0(outPrefix,"_",tolower(dataset),"_",tolower(ancestry)), thisThetaDataset, refPops, refPopType)
        }else{
          print(paste0("Not generating plots for ancestry '", ancestry, "' as no samples were classified!"))
        }
        
        # Plot triangle or barplot for reference samples known to be of this ancestry
        plot_ancestry(paste0(outPrefix,"_ref_",tolower(ancestry)), thetaRef[thetaRef$DATASET == ancestry,], refPops, refPopType)
    }
}



