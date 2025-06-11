rm(list=ls())
init <- Sys.time()

#-----------------------------------------------------
# This is a tutorial script to bring your own tools
# to the BioData Catalyst Powered by Seven Bridges
# platform to process specialized data types
# 
# Developer: Jeran Stratford
# Project: RMIP
# Date: 10 JUN 2025
#
# Revisions
# v1.0 initial commit
#
#-----------------------------------------------------

#-----------------------------------------------------
# Load Required Packages
#-----------------------------------------------------
if(!require('getopt')){install.packages('getopt', dependencies = T); library(getopt)}

#-----------------------------------------------------
# Setup logging
#-----------------------------------------------------
# Initialize the logbook
logbook <- data.frame(stringsAsFactors = F)

add_to_log <- function(lvl, func, message, printmsg = T){
  # <Date> <function> <level> <information>
  timestamp <- paste0("[",Sys.time(),"]")
  entry <- paste(timestamp, func, toupper(lvl), message, sep = " - ") 
  if (printmsg){
    message(paste0(entry, "\n"))  
  }
  logbook <<- rbind(logbook, data.frame("timestamp" = timestamp, "level"= lvl, "function" = func, "message" = message, stringsAsFactors = F))
}

#-----------------------------------------------------
# Setup global arguments and command line use
#-----------------------------------------------------

argString <- commandArgs(trailingOnly = T) # Read in command line arguments
#print(argString)

usage <- paste("Usage: aa_translator
             -- Required Parameters --
              
             -- Optional Parameters -- 
              [-i | --input]        <input RNA sequence to translate to amino acid> (string, default = 'CAUAUCUAA')
              [-o | --outfile]      <The output file name> (string, default = tutorial_output.tsv)
             -- Optional Flags --   
              [-3 | --three]        <Write the output using three letter amino acid abbreviations> (default = FALSE)
              [-w | --write]        <Write the results to file> (default=FALSE)
              [-v | --verbose]      <Display verbose logging> (default=FALSE)
             -- Help Flag --  
              [-h | --help]         <Displays this help message>
             Example:
             Rscript aa_translator -i ATGTAUCTAUCT -v -3 -w
              \n",sep="")

#0=no-arg, 1=required-arg, 2=optional-arg
spec <- matrix(c(
  'input',    'i', 2, "character",
  'outfile',  'o', 2, "character",
  'verbose',  'v', 0, "logical",
  'write',    'w', 0, "logical",
  'three',    '3', 0, "logical",
  'help',     'h', 0, "logical"
), byrow=TRUE, ncol=4);

args=getopt( spec, argString)

if ( !is.null(args$help) ) {
  add_to_log(lvl="error", func="getopt", message = "\nEither you asked for help or you are missing a required parameters: \n\n")
  add_to_log(lvl="error", func="getopt", message = usage)
  q(save="no",status=1,runLast=FALSE)
}

# Assign the default values
if(is.null(args$input)){args$input <- "CAUAUCUAA"}
if(is.null(args$three)){args$three <- F}
if(is.null(args$verbose)){args$verbose <- F}
if(is.null(args$write)){args$write <- F}
if(is.null(args$outfile)){
  args$outfile <- "tutorial_output.txt"
} else {
  # check the extension and update if necessary
  ext <- substr(args$outfile, nchar(args$outfile) - 3, nchar(args$outfile))
  if (ext %in% c(".csv", ".tsv", ".txt")){
    args$outfile <- paste0(substr(args$outfile, 1, nchar(args$outfile)-4), ".txt")
  } else {
    args$outfile <- paste0(args$outfile, ".txt")
  }
}

#-----------------------------------------------------
# Required Functions
#-----------------------------------------------------
format_seq <- function(x=args$input){
  
  # Must include complete codons
  if(nchar(x) %% 3 != 0){
    add_to_log(lvl="error", func="format_seq", message = "Provided input contains an incomplete codon, check the sequence and rerun.")
    safe_exit()
  }
  
  # Must only consist of ACGT
  if(grepl("[^ACGU$]+", toupper(x))){
    add_to_log(lvl="error", func="format_seq", message = "Provided input contains characters other than ACGU, check the sequence and rerun.")
    safe_exit()
  }
  
  return(split2codons(x))
}

split2codons <- function(x){
  return(strsplit(x, '(?<=.{3})', perl=TRUE)[[1]])
}

translate_codons <- function(x){
  switch(x,
         "AAA" = "Lys",
         "AAC" = "Asn",
         "AAG" = "Lys",
         "AAU" = "Asn",
         "ACA" = "Thr",
         "ACC" = "Thr",
         "ACG" = "Thr",
         "ACU" = "Thr",
         "AGA" = "Arg",
         "AGC" = "Ser",
         "AGG" = "Arg",
         "AGU" = "Ser",
         "AUA" = "Ile",
         "AUC" = "Ile",
         "AUG" = "Met",
         "AUU" = "Ile",
         
         "CAA" = "Gln",
         "CAC" = "His",
         "CAG" = "Gln",
         "CAU" = "His",
         "CCA" = "Pro",
         "CCC" = "Pro",
         "CCG" = "Pro",
         "CCU" = "Pro",
         "CGA" = "Arg",
         "CGC" = "Arg",
         "CGG" = "Arg",
         "CGU" = "Arg",
         "CUA" = "Leu",
         "CUC" = "Leu",
         "CUG" = "Leu",
         "CUU" = "Leu",
         
         "GAA" = "Glu",
         "GAC" = "Asp",
         "GAG" = "Glu",
         "GAU" = "Asp",
         "GCA" = "Ala",
         "GCC" = "Ala",
         "GCG" = "Ala",
         "GCU" = "Ala",
         "GGA" = "Gly",
         "GGC" = "Gly",
         "GGG" = "Gly",
         "GGU" = "Gly",
         "GUA" = "Gly",
         "GUC" = "Gly",
         "GUG" = "Gly",
         "GUU" = "Gly",
         
         "UAA" = "STOP",
         "UAC" = "Tyr",
         "UAG" = "STOP",
         "UAU" = "Tyr",
         "UCA" = "Ser",
         "UCC" = "Ser",
         "UCG" = "Ser",
         "UCU" = "Ser",
         "UGA" = "STOP",
         "UGC" = "Cys",
         "UGG" = "Trp",
         "UGU" = "Cys",
         "UUA" = "Leu",
         "UUC" = "Phe",
         "UUG" = "Leu",
         "UUU" = "Phe",
         
         NA)
  
}

three2one <- function(x){
  switch(toupper(x), 
         "ALA" = "A",
         "ARG" = "R",
         "ASN" = "N",
         "ASP" = "D",
         "CYS" = "C",
         "GLU" = "E",
         "GLN" = "Q",
         "GLY" = "G",
         "HIS" = "H",
         "ILE" = "I",
         "LEU" = "L",
         "LYS" = "K",
         "MET" = "M",
         "PHE" = "F",
         "PRO" = "P",
         "SER" = "S",
         "THR" = "T",
         "TRP" = "W",
         "TYR" = "Y",
         "VAL" = "V",
         "STOP" = "•",
         NA)
}

write.log <- function(f = args$outfile){
  logname <- gsub(".txt$", ".log", f, perl = T)
  write.table(x = logbook, file = logname, row.names = F, col.names = T, sep = '\t', quote = F)
}

safe_exit <- function(){
  write.log()
  q(save="no",status=1,runLast=FALSE)
}

#-----------------------------------------------------
# Main
#----------------------------------------------------- 
#---------------------------------
# Gather System Information
#---------------------------------
add_to_log(lvl = "info", func="main", message=paste0("User: ", Sys.info()[['effective_user']]), printmsg = args$verbose)
add_to_log(lvl = "info", func="main", message=paste0("Running from: ", Sys.info()[['nodename']]), printmsg = args$verbose)
add_to_log(lvl = "info", func="main", message=paste0("Platform: ", sessionInfo()["platform"]), printmsg = args$verbose)
add_to_log(lvl = "info", func="main", message=paste0("R version: ", R.version.string ), printmsg = args$verbose)
add_to_log(lvl = "info", func="main", message=paste0("R packages loaded: ",  paste(names(sessionInfo()$otherPkgs), collapse=", ")), printmsg = args$verbose)
add_to_log(lvl = "info", func="main", message=paste0("Rscript: ", gsub("--file=", "", grep(pattern = "^--file", commandArgs(trailingOnly = F), value = T))), printmsg = args$verbose)
add_to_log(lvl = "info", func="getopt", message=paste0("CommandLine: ", paste(commandArgs(trailingOnly = T), collapse=" ")), printmsg = args$verbose)
add_to_log(lvl = "info", func="getopt", message=paste0("Arguments: ", paste(names(args), args, sep=" = ")), printmsg = args$verbose)
add_to_log(lvl = "info", func="main", message=paste0("Current Working Directory: ", getwd()), printmsg = args$verbose)

#---------------------------------
# Check the input string for validity
#---------------------------------
x <- format_seq(x = args$input)

#---------------------------------
# Translate
#---------------------------------
x <- sapply(x, function(x) translate_codons(x))

#---------------------------------
# Apply output formatting
#---------------------------------
if (!args$three){
  x <- sapply(x, function(x) three2one(x))  
  final <- paste(x, collapse = "")
} else {
  final <- paste(x, collapse = "-")
}

msg <- paste("The RNA sequence", args$input, "translates to the protein sequence:", final)
add_to_log(lvl = "info", func="main", message=msg)

#-----------------------------------------------------
# Close out the script
#-----------------------------------------------------
add_to_log(lvl="info", func="main", message = paste0("Process began at ", init, " and finished at ", Sys.time()))

#---------------------------------
# Write the output to disk
#---------------------------------
if (args$write){
  fname <- file.path(args$outfile) 
  write(final, fname)
  add_to_log(lvl="info", func="export", message = paste0("Translation exported to ", fname))
}

#---------------------------------
# Write the log to file
#---------------------------------
write.log(f = args$outfile)

add_to_log(lvl="info", func="main", message = "Finished\n")
