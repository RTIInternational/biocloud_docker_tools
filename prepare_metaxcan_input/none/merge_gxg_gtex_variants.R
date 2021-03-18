# Title     : TODO
# Objective : TODO
# Created by: awaldrop
# Created on: 2018-12-04

# Libraries
library(plyr)

###################### Cmd line parsing ##########################

# Shows command line usage
show_usage = function(err_msg=NA){
  usage = "Usage: Rscript merge_gxg_gtex_variants.R <gxg_input> <gtex_input> <output_filename> \n"
  if(!is.na(err_msg)){
    usage = paste0(usage, "Err msg: ",err_msg)
  }
  return(usage)
}

# Parse command line args
args = commandArgs()

# Check command line args
if("-h" %in% args){
  stop(show_usage())
}else if("--help" %in% args){
  stop(show_usage())
}else if(length(args) != 8){
  err_msg = paste0("Incorrect number of args!")
  stop(show_usage(err_msg))
}

########################## Main Program #########################

##### Set input/output files from command line
meta_file = args[6]
print(paste0("GXG meta-analysis file: ", meta_file))

gtex_file = args[7]
print(paste0("GTEX file: ", gtex_file))

out_file  = args[8]
print(paste0("output file: ", out_file))


##### Main program logic
# Read in metadata
meta<-read.delim(meta_file, header=T)

# Read in gtex snps
gtex<-read.delim(gtex_file, header=T)

# Merge columns by ID
merged <- merge (gtex, meta, by.x=c("rsid"), by.y=c("MarkerName"))

# Rename columns to conform to metaxscan input format
merged <- rename(merged,c("rsid_dbSNP150"="SNP"))
merged <- subset(merged, select=c(SNP, A1, A2, BETA, StdErr, P))

# Write out merged, renamed table to output file
write.table(merged, file=out_file, col.names=TRUE, row.names=FALSE, quote=FALSE)