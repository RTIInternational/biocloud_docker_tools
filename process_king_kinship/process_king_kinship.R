library(igraph)
library(optparse)
options(stringsAsFactors = F)

parser = OptionParser(usage = "\n%prog [options] --kinship <kinship_file> --output_basename <output_basename> --output_delim <delim>",
                      description = "Program for identifying/classifying sample relations based on output from KING's --kinship module",
                      prog="Rscript process_king_kinship.R")
parser = add_option(object=parser, opt_str=c("--kinship"), default=NULL, type="character",
                    help="[REQUIRED] Path to KING kinship output file")
parser = add_option(object=parser, opt_str=c("--output_basename"), default=NULL, type="character",
                    help="[REQUIRED] Basename to prefix output files.")
parser = add_option(object=parser, opt_str=c("--output_delim"), default="space", type="character",
                    help="[REQUIRED] Output file delimiter (Options: space, tab, comma)")
############## Parse command line
argv = parse_args(parser)

# User-specified arguments
input.file <- argv$kinship # KING across-family results table from --kinship
print(paste0("Using input file: ", input.file))
output_basename <- argv$output_basename
output_delim  <- tolower(argv$output_delim)

# Check and set output delimiter
if(!output_delim %in% c("space", "tab", "comma")){
  stop("Invalid output delim: '", output_delim, "'! Valid options [space | tab | delim]")
}
delim_options = c(" ", "\t", ",")
names(delim_options) = c("space", "tab", "comma")
output_delim = delim_options[output_delim]

# Create output filenames from basename
exclusion_recommendations_file <- paste0(output_basename,".related.remove")
print(paste0("Exlusion recommendations output file: ", exclusion_recommendations_file))
annotated_kin_file <- paste0(output_basename, ".annotated.k0")
print(paste0("Annotated kinship output file: ", annotated_kin_file))

# Read in KING --kinship output table
king.stats <- read.table(input.file, header = T)
print(paste0("Read in kinship table with ", nrow(king.stats), " rows..."))

# Make sure file is actually king kinship (based on colnames)
expected_colnames = paste(c("FID1", "ID1", "FID2", "ID2", "N_SNP", "HetHet", "IBS0", "Kinship"), collapse=" ")
actual_colnames = paste(colnames(king.stats), collapse=" ")
if(expected_colnames != actual_colnames){
  err = paste0("Error: Incorrect Input kinship colnames! Expected colnames are:\n", 
               expected_colnames,"\nInput colnames:\n", actual_colnames)
  stop(err)
}

# Just touch empty files if 0 rows
if(nrow(king.stats) == 0){
  print("Empty kinship file! No related sample pairs detected!")
  file.create(exclusion_recommendations_file)
  # Write annotated kinship stats to output file
  write.table(king.stats, file = annotated_kin_file, 
              sep = "\t", row.names = F, col.names = T, quote = F)
  print("Finished successfully!")
  quit(status=0, save='no')
}

# Combine FID and IIDs into single ID for first component of a pair
edge.heads <- paste0(king.stats$FID1, ":::", king.stats$ID1)
# Combine FID and IIDs into single ID for second component of a pair
edge.tails <- paste0(king.stats$FID2, ":::", king.stats$ID2)
sample.pairs = cbind(edge.heads, edge.tails)

# Create undirected sample graph
sample.graph <- graph.data.frame(sample.pairs, directed = F)

# Data structure to track which samples to exclude
remove.list <- c()

# Get the number of relationships per sample
sample.degrees <- sort(degree(sample.graph), decreasing = T)

# Apply greedy graph pruning approach
# Remove highest degree samples until none are left or
#   the highest degree sample has degree 1
print("Starting to prune graph...")
current.graph <- sample.graph
while(length(sample.degrees) > 0 & sample.degrees[1] > 1) {
  remove.list <- c(remove.list, names(sample.degrees[1]))
  current.graph <- current.graph - names(sample.degrees[1])
  sample.degrees = sort(degree(current.graph), decreasing = T)
}

# Update sample pairs post-pruning
unpruned.sample.pairs <- sample.pairs[!(sample.pairs[,1] %in% remove.list) & !(sample.pairs[,2] %in% remove.list),]

# Randomly select one from each pair to remove
if(nrow(unpruned.sample.pairs) > 0){
  print("Randomply excluding members of remaining sample pairs...")
  if(nrow(king.stats) > 1){
    random.exclusions <- sapply(1:nrow(unpruned.sample.pairs),
                                function(i){unpruned.sample.pairs[i, sample(x = 1:2, size = 1)]})
    remove.list <- c(remove.list, as.vector(random.exclusions))
  }else{
    # Need to handle case where only one sample pair exists
    # This sample pair would NOT have been touched in the while loop above bc both samples have degree == 1
    remove.list <- unpruned.sample.pairs[sample(x=1:2, size=1)]
  }
}else{
  print("No unpruned sample pairs remain after graph pruning! No need to do random pair exclusion!")
}

# Update remove list
print(paste0("Total related samples recommended for exclusion: ", length(remove.list)))

# Final check that no sample pairs remain
if(sum(!(sample.pairs[,1] %in% remove.list) & !(sample.pairs[,2] %in% remove.list)) != 0){
  stop("Error: Not all sample pairs filtered during graph pruning!")
}

# Export PLINK compatible remove list
print("Writing removal candidates file...")
final.remove.list <- do.call(rbind, strsplit(remove.list, split = ":::"))
write.table(final.remove.list, file = exclusion_recommendations_file, 
            sep = output_delim, row.names = F, col.names = F, quote = F)

# Annotate relationships with level of relatedness
classify_kinship = function(kin){
  if(kin > 0.354){
    return("MZ_twin_or_duplicate")
  }else if(kin > 0.177){
    return("1st_degree_relative")
  }else if(kin > 0.0884){
    return("2nd_degree_relative")
  }else{
    return("3+_degree_relative")
  }
}

print("Annotating input kinship file")
king.stats$Classification = sapply(king.stats$Kinship, classify_kinship)

# Write annotated kinship stats to output file
write.table(king.stats, file = annotated_kin_file, 
            sep = "\t", row.names = F, col.names = T, quote = F)

print("Finished successfully!")
