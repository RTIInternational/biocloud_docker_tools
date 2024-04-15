library(getopt)
library("sangeranalyseR")

####################################
###    INPUT ARGUMENTS     #########
####################################
argString <- commandArgs(trailingOnly = T) # Read in command line arguments

# This is for setting up a human readable set of documentation to display if something is amiss.
usage <- paste("Usage: convert_ab1_to_fasta.r [OPTIONS]
             -- Required Parameters --
              [-i | --input_filename]    <Path to input ab1 file> (REQUIRED)
              [-l | --linker   ]    <String identifier for sample> (REQUIRED, e.g. RMIP_001_001_A_001_A)
             -- Optional Parameters -- 
              [-v | --verbose]    <Activates verbose mode>
             -- Help Flag --  
              [-h | --help     ]    <Displays this help message>
             Example:
             convert_ab1_to_fasta.r -v -i ./my_data/Achl_ACHLO006-09_1_F.ab1 -l RMIP_001_001_A_001_A
              \n",sep="")

# Setup the matrix which consists of long flag (should be all lower case), short flag (case sensitive), parameter class (0=no-arg, 1=required-arg, 2=optional-arg) and parameter type (logical, character, numeric)
spec <- matrix(c(
          'input_filename','i', 2, "character",
          'linker',   'l', 2, "character",
          'verbose',  'v', 2, "integer",
          'help',     'h', 0, "logical"
          ), byrow=TRUE, ncol=4);

# Parse the command line parameters into R
args=getopt(spec, argString)

exitFlag <- 0

# If missing required fields then display usage and quit
if ( !is.null(args$help)) {
  cat(usage)
  q(save="no",status=1,runLast=FALSE)
}

if (is.null(args$input_filename)){
    print("MISSING INPUT FILE - input ab1 file required")
    exitFlag <- 1
}

if (!file.exists(args$input_filename)) {
    print("INPUT FILE NOT FOUND")
    print(paste0("Got input path: ",args$input_filename))
    exitFlag <- 1
}

if (!grepl(pattern="\\.ab1$",args$input_filename, ignore.case = TRUE)){
  print("INPUT FILE NOT .ab1")
  print(paste0("Got file: ", args$input_filename))
  exitFlag <- 1
}

if (is.null(args$linker)){
    print("MISSING LINKER - linker/identifier required")
    exitFlag <- 1
}

if (exitFlag) {
    cat(usage)
    q(save="no",status=1,runLast=FALSE)
}

if (!("verbose" %in% names(args))){
  args$verbose <- 0
}

if (args$verbose){
    print("Verbose mode activated")
}

# Extracting input arguments
print_verbose <- function(x) {if (args$verbose) {print(x)}}
input_filename <- args$input_filename
linker <- args$linker

####################################
###    IDENTIFIER QC       #########
####################################

print_verbose("Checking validity of linker...")

validate_linker <- function(x){
  # Function to validate input linker string.  Intended to be assigned to 'exitFlag' variable
  #  - Returns 0 if valid, i.e. don't exit if valid
  #  - Returns 1 if invalid, i.e. exit if invalid
  linker_regex <- c("RMIP","\\d{3}","\\d{3}","\\w{1}","\\d{3}","\\w{1}")
  linker_part_lengths <- c(4,3,3,1,3,1)
  
  print_verbose("Splitting linker into parts...")
  linker_parts <- unlist(strsplit(x=x,split="_"))
  print_verbose(paste0("Got '",length(linker_parts),"' parts"))
  
  if (length(linker_parts) < 5) {
    print(paste0("ERROR: Invalid linker format.  Linker has too few parts, should be 5 or 6 parts. Exiting"))
    return(1)
  } else if (length(linker_parts) > 6) {
    print(paste0("ERROR: Invalid linker format.  Linker has too many parts, should be 5 or 6 parts. Exiting"))
    return(1)
  }
  
  for (i in 1:length(linker_parts)){
    print_verbose(paste0(i,": Here is linker part '",linker_parts[i],"'"))
    print_verbose(paste0(i,": Here is regex to match '",linker_regex[i],"'"))
    if(grepl(linker_regex[i],linker_parts[i]) & nchar(linker_parts[i]) == linker_part_lengths[i]){
      print_verbose("Regex match!")
    } else{
      print_verbose("Regex match FAILED")
      print("ERROR: Invalid linker format. Part doesn't match regex. Exiting")
      return(1)
    }
  }
  
  print_verbose("Success!  All parts of linker matched with requirements")
  return(0)
}

exitFlag <- validate_linker(linker)

if (exitFlag){
    print("ERROR: check linker and error messages")
    q(save="no",status=1,runLast=FALSE)
}

print_verbose(paste0("Here is input_filename: '",input_filename,"'"))

sangerReadF <- SangerRead(readFileName = input_filenamme,
                            readFeature = "Forward Read")

output_dir <- "./temp_output"
print_verbose("Here is writeFasta:")
writeFasta(sangerReadF, outputDir = output_dir, compress = FALSE, compression_level = NA)

raw_file_name <- list.files(path = output_dir, pattern = "*.fa", full.names = F)
print_verbose(paste0("Found written SangerAlignment file(s): ", raw_file_name))

out_file_name <- paste0(linker,"_",raw_file_name)
print_verbose(paste0("Renaming SangerAlignment file(s): ", linker,"_",raw_file_name))
print_verbose(paste0("Here is out_file_name: ", out_file_name))

if(file.copy(paste0(output_dir,"/",raw_file_name),out_file_name)) {
  print_verbose(paste0("Success! Created: ",out_file_name))
} else {
  print_verbose(paste0("Failed to create: ",out_file_name," - possible file already exists"))
}

# for (i in 1:length(raw_file_name)){
#   if(file.copy(paste0(output_dir,"/",raw_file_name[i]),out_file_name[i])) {
#     print_verbose(paste0("Success! Created: ",out_file_name[i]))
#   } else {
#     print_verbose(paste0("Failed to create: ",out_file_name[i]," - possible file already exists"))
#   }
# }

unlink("./temp_output", recursive = TRUE)
