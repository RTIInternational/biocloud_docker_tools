rm(list=ls())
init <- Sys.time(); timer <- proc.time();

#-----------------------------------------------------
# The PDF outputs from an optical genome mapping run
# on the BioNano Saphyr instrument often contains 
# 1000's pages. The following script parses the PDF
# into either a set of tab-delimited files or an Excel
# spreadsheet with 3 sheets.
# 
# Developer: Mike Enger
# Project: RMIP
# Date: 22JAN2024
#
# Version of the PDF that we're working with %PDF-1.4
#
# Revisions
# v1.0 initial commit
#
#-----------------------------------------------------

#-----------------------------------------------------
# Load Required Packages
#-----------------------------------------------------
if(!require('getopt')){install.packages('getopt', dependencies = T); library(getopt)}
if(!require('dplyr')){install.packages('dplyr', dependencies = T); library(dplyr)}
if(!require('stringr')){install.packages('stringr', dependencies = T); library(stringr)}
if(!require('pdftools')){install.packages('pdftools', dependencies = T); library(pdftools)}

#-----------------------------------------------------
# Setup logging
#-----------------------------------------------------
add_to_log <- function(lvl, func, message){
	  # <Date> <function> <level> <information>
	  timestamp <- paste0("[",Sys.time(),"]")
          entry <- paste(timestamp, func, toupper(lvl), message, sep = " - ") 
	  message(paste0(entry, "\n"))
}

#-----------------------------------------------------
# Setup global arguments and command line use
#-----------------------------------------------------

argString <- commandArgs(trailingOnly = T) # Read in command line arguments
print(argString)

usage <- paste("Usage: ogm_pdf_parser.R
             -- Required Parameters --
              [-i | --pdf]          <Path to the PDF> (Required)
             -- Optional Parameters -- 
              [-o | --outfile]      <The output file name> (default = pdf_extract.tsv)
              [-p | --outpath]      <Path to the directory to save the outputs> (default = path of working directory)
             -- Optional Flags --   
              [-E | --excel]        <Export results as a MS Excel Workbook>(default=FALSE)
              [-v | --verbose]      <Display verbose logging>(default=FALSE)
             -- Help Flag --  
              [-h | --help]             <Displays this help message>
             Example:
             Rscript ogm_pdf_parser.R -i abc.pdf --excel -v
              \n",sep="")

#0=no-arg, 1=required-arg, 2=optional-arg
spec <- matrix(c(
          'excel',    'E', 0, "logical",
          'pdf',      'i', 1, "character",
          'outfile',  'o', 2, "character",
          'outpath',  'p', 2, "character",
          'verbose',  'v', 0, "logical",
          'help',     'h', 0, "logical"
          ), byrow=TRUE, ncol=4);

args=getopt( spec, argString)

if ( !is.null(args$help) | is.null(args$pdf) ) {
  add_to_log(lvl="error", func="getopt", message = "\nEither you asked for help or you are missing a required parameters: pdf\n\n")
  add_to_log(lvl="error", func="getopt", message = usage)
  q(save="no",status=1,runLast=FALSE)
}

suffix <- '.tsv'
if(is.null(args$excel)){
    args$excel <- F
} else {
  if(!require('openxlsx')){install.packages('openxlsx', dependencies = T); library(openxlsx)}
  suffix <- '.xlsx'
}

if(is.null(args$outfile)){args$outfile <- paste0("pdf_extract", suffix)}
if(is.null(args$outpath)){args$outpath <- getwd()}
if(is.null(args$verbose)){args$verbose <- F}

#-----------------------------------------------------
# Required Functions
#-----------------------------------------------------
load_pdf <- function(fname){
  
  tmp <- tryCatch(
    {
      add_to_log(lvl="info", func="load_pdf", message = "Reading in the PDF file")
      pdf_text(fname)
    },
    error=function(cond) {
      add_to_log(lvl="error", func="load_pdf", message = paste("Error reading in pdf file:", basename(fname)))
      add_to_log(lvl="error", func="load_pdf", message = "Original error message:")
      add_to_log(lvl="error", func="load_pdf", message = cond)
      return(NA)
    },
    warning=function(cond) {
      add_to_log(lvl="warn", func="load_pdf", message = paste("Warning while reading in pdf file:", basename(fname)))
      add_to_log(lvl="warn", func="load_pdf", message = "Original warning message:")
      add_to_log(lvl="warn", func="load_pdf", message = cond)
      return(NULL)
    },
    finally={
      add_to_log(lvl="info", func="load_pdf", message = paste("PDF file", fname, "processing complete"))
    }
  )    
  
  out <- strsplit(tmp, split = "\n") %>% lapply(., function(x) trimws(x))
  
  return(out)
}

extract_value <- function(findme, lns = txt){
  # Prep the string for grep with perl
  x <- findme %>% trimws(.) %>% sapply(., `[`, 1) 
  
  idx <- grep(paste0("^", x), lns, perl = T, ignore.case = T)
  
  if (length(idx) > 0 ){
    # The value was found
    out <- 
      lns[idx] %>% 
      substr(., start = nchar(findme)+1, stop = nchar(lns[idx])) %>% 
      trimws(.) %>% 
      gsub("[ ]+", " ", .) %>% 
      sapply(., `[`, 1) 
  } else {
    # Could not find it 
    out <- NA
  }
  
  return(out)
}

extract_location_value <- function(lns) {
  pattern <- "^Location\\s+(.+)$"
  
  out <- str_extract(lns, pattern)
  
  if (!is.na(out)) {
    out <- trimws(gsub("^Location\\s+(.+)$", "\\1", out))
  } else {
    out <- NA
  }
  
  return(out)
}

extract_next_line <- function(findme, lns = txt) {
  # Prep the string for grep with perl
  x <- findme %>% trimws(.) %>% sapply(., `[`, 1)  
  
  idx <- grep(paste0("^", x), lns, perl = TRUE, ignore.case = TRUE)
  
  if (length(idx) > 0 ) {
    # The value was found, and there is a next line
    out <- lns[idx + 1] %>%
	trimws(.) %>%
	gsub("[ ]+", " ", .) %>% 
	sapply(., `[`, 1)
  } else {
    # Could not find it or no next line
    out <- NA
  }
  
  return(out)
}

extract_STR_values <- function(x, lns) {
  data.frame(
    SMAP_ID = extract_value("SMAP ID:", lns[[x]]),
    Type = extract_value("Type", lns[[x]]),
    Location = extract_location_value(lns[[x]][10]),
    Size_bp = extract_value("Size \\(bp\\)", lns[[x]]),
    Zygosity = extract_value("Zygosity", lns[[x]]),
    Confidence = extract_value("Confidence", lns[[x]]),
    Algorithm = extract_value("Algorithm", lns[[x]]),
    Orientation = extract_value("Orientation", lns[[x]]),
    Present_Pct_Control_Samples = extract_value("Present % Control Samples", lns[[x]]),
    Nearest_Nonoverlap_Gene = extract_value("Nearest Non-overlap Gene", lns[[x]])[1],
    Nearest_Nonoverlap_Gene_Distance_bp = extract_value("Nearest Non-overlap Gene Distance \\(bp\\)", lns[[x]]),
    Found_in_Self_Molecules = extract_value("Found in Self Molecules", lns[[x]]),
    Overlapping_Genes = extract_value("Overlapping Genes", lns[[x]])[1],
    Overlapping_Genes_Count = extract_value("Overlapping Genes Count", lns[[x]]),
    ISCN = extract_value("ISCN:", lns[[x]]),
    Fail_Assembly_Chimeric_Score = extract_value("Fail Assembly Chimeric Score", lns[[x]]),
    Putative_Gene_Fusion = extract_value("Putative Gene Fusion", lns[[x]]),
    Molecule_Count = extract_value("Molecule Count", lns[[x]]),
    Number_Overlap_Dgv_Calls = extract_value("Number of Overlap Dgv Calls", lns[[x]]),
    UCSC_Web_Link = paste("http://genome.ucsc.edu/cgi-bin/hgTracks?db=hg38&position=", extract_location_value(lns[[x]][10])),
    Found_in_Control_Sample_Assembly = extract_value("Found in Control Sample Assembly", lns[[x]]),
    Found_in_Control_Sample_Molecules = extract_value("Found in Control Sample Molecules", lns[[x]]),
    Control_Molecule_Count = extract_value("Control Molecule Count", lns[[x]]),
    Copy_Number_Variants = extract_next_line("Copy Number Variants", lns[[x]]),
    stringsAsFactors = F
  )
}

extract_CNV_values <- function(x, lns) {
  data.frame(
    CNV_ID = extract_value("CNV ID:", lns[[x]]),
    Type = extract_value("Type", lns[[x]]),
    Location = extract_location_value(lns[[x]][10]),
    Size_bp = extract_value("Size \\(bp\\)", lns[[x]]),
    Copy_Number = extract_value("Copy Number", lns[[x]]),
    Confidence = extract_value("Confidence", lns[[x]]),
    Overlapping_Genes_Count = extract_value("Overlapping Genes Count", lns[[x]]),
    stringsAsFactors = F
  )
}


#-----------------------------------------------------
# Main
#----------------------------------------------------- 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Logging information
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
add_to_log(lvl = "info", func="main", message=paste0("User: ", Sys.info()[['effective_user']]))
add_to_log(lvl = "info", func="main", message=paste0("Running from: ", Sys.info()[['nodename']]))
add_to_log(lvl = "info", func="main", message=paste0("Platform: ", sessionInfo()["platform"]))
add_to_log(lvl = "info", func="main", message=paste0("R version: ", R.version.string ))
add_to_log(lvl = "info", func="main", message=paste0("R packages loaded: ",  paste(names(sessionInfo()$otherPkgs), collapse=", ")))
add_to_log(lvl = "info", func="main", message=paste0("Rscript: ", gsub("--file=", "", grep(pattern = "^--file", commandArgs(trailingOnly = F), value = T))))
add_to_log(lvl = "info", func="getopt", message=paste0("CommandLine: ", paste(commandArgs(trailingOnly = T), collapse=" ")))
add_to_log(lvl = "info", func="getopt", message=paste0("Arguments: ", paste(names(args), args, sep=" = ")))
add_to_log(lvl = "info", func="main", message=paste0("Current Working Directory: ", getwd()))
						
#-----------------------------------------------------
# Get the metadata about the PDF and read in PDF
#-----------------------------------------------------

# Get the metadata about the PDF
pInfo <- pdf_info(args$pdf)
pages <- pInfo$pages
# Read the PDF into memory
txt <- load_pdf(fname = args$pdf)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The first page is a cover page
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The second page is a circos plot
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# There is a handy summary table on the right but that is part of the image

#-----------------------------------------------------
# Initialize two data frames to house the extractions
#-----------------------------------------------------
extracted_STR_cols <- c("SMAP_ID",
                    "Type",
                    "Location",
                    "Size",
                    "Zygosity",
                    "Confidence",
                    "Algorithm",
                    "Orientation",
                    "Present_Pct_Control_Samples",
                    "Nearest_Nonoverlap_Gene",
                    "Nearest_Nonoverlap_Gene_Distance_bp",
                    "Found_in_Self_Molecules",
                    "Overlapping_Genes",
                    "Overlapping_Genes_Count",
                    "ISCN",
                    "Fail_Assembly_Chimeric_Score",
                    "Putative_Gene_Fusion",
                    "Molecule_Count",
                    "Number_Overlap_Dgv_Calls",
                    "UCSC_Web_Link",
                    "Found_in.Control_Sample_Assembly",
                    "Found_in_Control_Sample_Molecules",
                    "Control_Molecule_Count",
                    "Copy_Number_Variants",
                    stringsAsFactors = F)

extracted_CNV_cols <- c("SMAP_ID",
                        "Type",
                        "Location",
                        "Size",
                        "Copy_Number",
                        "Confidence",
                        "Overlapping_Genes_Count",
                        stringsAsFactors = F)

df_str <- data.frame(matrix(ncol = length(extracted_STR_cols)-1, nrow = 0), row.names = NULL)
colnames(df_str) <- extracted_STR_cols[1:length(extracted_STR_cols)-1]

df_cnv <- data.frame(matrix(ncol = length(extracted_CNV_cols)-1, nrow = 0), row.names = NULL)
colnames(df_cnv) <- extracted_CNV_cols[1:length(extracted_CNV_cols)-1]


#-----------------------------------------------------
# Loop over pages to extract data and bind to respective dataframe
#-----------------------------------------------------
for (i in 3:(pages-1)){if (i == 3){message('Initializing data extraction...')}
  else if(i %% 1000 == 0){message(paste("Page", i, "of", pages, paste0("(", round(i/pages,2)*100,"%)"), "completed"))} 
  else if (i == pages-1){add_to_log(lvl="info", func="main", message = "Data extraction completed\n")
  }
  
  if (substr(txt[[i]][8], 1,4) == "SMAP"){
    row_values <- extract_STR_values(i, txt)
    df_str <- rbind(df_str, row_values)
    rm(row_values)
  } 
  else if(substr(txt[[i]][8], 1, 3) == "CNV"){
    row_values <- extract_CNV_values(i, txt)
    df_cnv <- rbind(df_cnv, row_values)
    rm(row_values)
  }
  rownames(df_str) <- NULL
  rownames(df_cnv) <- NULL
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The last page is job details
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
operation <- extract_value(findme = "Operation", lns = txt[[pages]])
date <- extract_value(findme = "Date", lns = txt[[pages]])
job_name <- extract_value(findme = "Name", lns = txt[[pages]])
sample <- extract_value(findme = "Sample", lns = txt[[pages]])
reference <- extract_value(findme = "reference", lns = txt[[pages]])
job_id <- extract_value(findme = "Job_ID", lns = txt[[pages]])
command <- paste(extract_value(findme = "Command", lns = txt[[pages]]), txt[[pages]][16:22], collapse = " ")

#-----------------------------------------------------
# Create data frame for job details
#-----------------------------------------------------
df_job <- data.frame(
  Operation = c("Date", "Job Name", "Sample", "Reference", "Job_ID", "Command"),
  opvalue = c(date, job_name, sample, reference, job_id, command),
  row.names = NULL,
  stringsAsFactors = FALSE
)
colnames(df_job)[2] <- operation

#-----------------------------------------------------
# Transform certain columns to numeric
#-----------------------------------------------------
df_str$Size_bp <- as.numeric(gsub(",", "", df_str$Size_bp))
df_str$Nearest_Nonoverlap_Gene_Distance_bp <- as.numeric(gsub(",", "", df_str$Nearest_Nonoverlap_Gene_Distance_bp))
df_str$SMAP_ID <- as.numeric(df_str$SMAP_ID)
df_str$Confidence <- as.numeric(df_str$Confidence)
df_str$Present_Pct_Control_Samples <- as.numeric(df_str$Present_Pct_Control_Samples)
df_str$Overlapping_Genes_Count <- as.numeric(gsub(",", "", df_str$Overlapping_Genes_Count))
df_str$Molecule_Count <- as.numeric(gsub(",", "", df_str$Molecule_Count))
df_str$Number_Overlap_Dgv_Calls <- as.numeric(gsub(",", "", df_str$Size_bp))
df_str$Control_Molecule_Count <- as.numeric(gsub(",", "", df_str$Control_Molecule_Count))

df_cnv$CNV_ID <- as.numeric(df_cnv$CNV_ID)
df_cnv$Size_bp <- as.numeric(df_cnv$Size_bp)
df_cnv$Copy_Number <- as.numeric(df_cnv$Copy_Number)
df_cnv$Confidence <- as.numeric(df_cnv$Confidence)
df_cnv$Overlapping_Genes_Count <- as.numeric(df_cnv$Overlapping_Genes_Count)

#-----------------------------------------------------
# Write to xlsx or tsv
#-----------------------------------------------------
if (args$excel){
  # Make first sheet the info from the last page
  # Second sheet for structural variants
  # Third sheet for copy number variants
  write.xlsx(list("Job Details" = df_job, "Structural Variants" = df_str, "Copy Number Variants" = df_cnv), 
             file = file.path(args$outpath, args$outfile))
  add_to_log(lvl="info", func="export", message = paste0(args$outfile, " has been exported to ", args$outpath, "\n"))
} else {
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Add header columns to Strucutral Variant dataframe
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  df_str$sample <- sample
  df_str$job_name <- job_name
  df_str$date <- date
  df_str$reference <- reference
  
  df_str <- df_str %>% relocate(reference)
  df_str <- df_str %>% relocate(date)
  df_str <- df_str %>% relocate(job_name)
  df_str <- df_str %>% relocate(sample)
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Add header columns to Copy Number Variant dataframe
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  df_cnv$sample <- sample
  df_cnv$job_name <- job_name
  df_cnv$date <- date
  df_cnv$reference <- reference
  
  df_cnv <- df_cnv %>% relocate(reference)
  df_cnv <- df_cnv %>% relocate(date)
  df_cnv <- df_cnv %>% relocate(job_name)
  df_cnv <- df_cnv %>% relocate(sample)
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Outputs two files, 1 for structural variants and one for copy numbers
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  write.table(x = df_str, file = file.path(args$outpath, paste0('str_', args$outfile)),
              row.names = F, col.names = T, sep = '\t', quote = F)
  write.table(x = df_cnv, file = file.path(args$outpath, paste0('cnv_', args$outfile)),
              row.names = F, col.names = T, sep = '\t', quote = F)
  add_to_log(lvl="info", func="export", message = paste0("Files exported to ", args$outpath, "\n"))
}

#-----------------------------------------------------
# Close out the script
#-----------------------------------------------------
add_to_log(lvl="info", func="main", message = paste0("Process began at ", init, " and finished at ", Sys.time(), "\n"))
add_to_log(lvl="info", func="main", message = "Finished\n")
