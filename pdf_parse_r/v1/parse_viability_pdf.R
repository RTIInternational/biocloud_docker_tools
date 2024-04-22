rm(list=ls())
init <- Sys.time(); timer <- proc.time();

#-----------------------------------------------------
# If you have a PDF from a cell counter, how to 
# extract the cell count and viability of the sample
#
# Developer: Jeran Stratford
# Project: RMIP
# Date: 27OCT2023
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
if(!require('pdftools')){install.packages('pdftools', dependencies = T); library(pdftools)}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Setup logging
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
add_to_log <- function(lvl, func, message){
	  # <Date> <function> <level> <information>
	  timestamp <- paste0("[",Sys.time(),"]")
  	  entry <- paste(timestamp, func, toupper(lvl), message, sep = " - ") 
	  cat(paste0(entry, "\n"))
}


#-----------------------------------------------------
# Setup global arguments and command line use
#-----------------------------------------------------

argString <- commandArgs(trailingOnly = T) # Read in command line arguments

usage <- paste("Usage: parse_viability_pdf.r
             -- Required Parameters --
              [-i | --pdf]          <Path to the PDF> (Required)
             -- Optional Parameters -- 
              [-o | --outfile]      <The output file name> (default = pdf_extract.tsv)
              [-p | --outpath]      <Path to the directory to save the outputs> (default = path of the input file)
             -- Optional Flags --   
              [-E | --excel]        <Export results as a MS Excel Workbook>(default=FALSE)
              [-v | --verbose]      <Display verbose logging>(default=FALSE)
             -- Help Flag --  
              [-h | --help]             <Displays this help message>
             Example:
             parse_viability_pd.r -i abc.pdf -v
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
if(is.null(args$outpath)){args$outpath <- dirname(args$pdf)}
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
  x <- findme %>% trimws(.) %>% strsplit(.," ") %>% sapply(., `[`, 1) 
  
  idx <- grep(paste0("^", x), lns[[1]], perl = T, ignore.case = T)

  if (length(idx) > 0 ){
    # The value was found
    out <- 
      lns[[1]][idx] %>% 
        substr(., start = nchar(findme)+1, stop = nchar(lns[[1]][idx])) %>% 
        trimws(.) %>% 
        gsub("[ ]+", " ", .) %>% 
        strsplit(x = , split = " ", .) %>% 
        sapply(., `[`, 1) 
  } else {
    # Could not find it 
    out <- NA
  }
  
  return(out)
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

txt <- load_pdf(fname = args$pdf)

id <- txt[[1]][length(txt[[1]])-1] %>% strsplit(., " ") %>% sapply(., `[`, 1) %>% gsub(".pdf$", "", ., perl = T, ignore.case = T) %>% strsplit(x = , split = "-", .)
date <-  id %>% sapply(., `[`, 1)
id2 <-  id %>% sapply(., `[`, 2)
id3 <-  id %>% sapply(., `[`, 3)
prefix <-  id %>% sapply(., `[`, 4)

viable <- extract_value("Viability (%)")
live <- extract_value("Live (cells/ml)")
dead <- extract_value("Dead (cells/ml)")
total <- extract_value("Total (cells/ml)")
diameter <- extract_value("Estimated cell diameter (um)")
diameter_stdev <- extract_value("Cell diameter standard deviation (um)")
agg <- extract_value("\\(%\\) of cells in aggregates with five or more cells")

final <- data.frame("Consortium" = prefix %>% substr(.,1,4),
                    "Project" = prefix %>% substr(.,5,7),
                    "Participant" = prefix %>% substr(.,8,10),
                    "Discriminator" = prefix %>% substr(.,11,11),
                    "Identifier" = prefix %>% substr(.,12,14),
                    "Vial" = prefix %>% substr(.,15,15),
                    "Date" = id %>% sapply(., `[`, 1),
                    "Viability" = viable,
                    "Live" = live,
                    "Dead" = dead,
                    "Total" = total,
                    "cell diameter" = diameter,
                    "cell diameter stdev" = diameter_stdev,
                    "pct aggregated" = agg,
                    stringsAsFactors = F)

if (args$excel){
  write.xlsx(x = final, file = file.path(args$outpath, args$outfile))
} else {
  write.table(x = final, file = file.path(args$outpath, args$outfile), row.names = F, col.names = T, sep = '\t', quote = F)  
}

#-----------------------------------------------------
# Close out the script
#-----------------------------------------------------
add_to_log(lvl="info", func="main", message = paste0("Process began at ", init, " and finished at ", Sys.time(), "\n"))
add_to_log(lvl="info", func="main", message = "Finished\n")
