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
# v1.1 update outfile default
#
#-----------------------------------------------------

#-----------------------------------------------------
# Load Required Packages
#-----------------------------------------------------
if(!require('getopt')){install.packages('getopt', dependencies = T); library(getopt)}
if(!require('dplyr')){install.packages('dplyr', dependencies = T); library(dplyr)}
if(!require('pdftools')){install.packages('pdftools', dependencies = T); library(pdftools)}
if(!require('stringr')){install.packages('stringr', dependencies = T); library(stringr)}

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

args$outfile <- paste0((sub(".*/(.*)\\.pdf$", "\\1", args$pdf)), "_harmonized", suffix)
if(is.null(args$outpath)){args$outpath <- dirname(args$pdf)}
if(is.null(args$verbose)){args$verbose <- F}

#-----------------------------------------------------
# Required Functions
#-----------------------------------------------------
parse_filename <- function(fname) {
  f <- basename(fname)
  
  # Study: RMIP_XXX_001_A_001[_V]?_Anything.pdf
  pat_study <- "^(RMIP)_([0-9]{3})_([0-9]{3})_([A-Z])_([0-9]{3})(?:_([A-Z]))?_.+\\.pdf$"
  m1 <- str_match(f, pat_study)
  
  if (!is.na(m1[,1])) {
    return(list(
      Consortium   = m1[,2],
      Project      = m1[,3],
      Participant  = m1[,4],
      Discriminator= m1[,5],
      Identifier   = m1[,6],
      Vial         = m1[,7] # may be NA if not present
    ))
  }
  
  # Pilot: RMIP_XXX_PL_001[_V]?_Anything.pdf
  pat_pilot <- "^(RMIP)_([0-9]{3})_PL_([0-9]{3})(?:_([A-Z]))?_.+\\.pdf$"
  m2 <- str_match(f, pat_pilot)
  
  if (!is.na(m2[,1])) {
    return(list(
      Consortium   = m2[,2],
      Project      = m2[,3],
      Participant  = NA_character_, # not present in pilot
      Discriminator= "PL",              
      Identifier   = m2[,4],
      Vial         = m2[,5] # may be NA if not present
    ))
  }
  pat_allo <- "^(RMIP)_([0-9]{3})_(Allo[0-9]{1})_([A-Z])_([0-9]{3})(?:_([A-Z]))?_.+\\.pdf$"
  m3 <- str_match(f, pat_allo)
  if (!is.na(m3[,1])) {
    return(list(
      Consortium   = m3[,2],
      Project      = m3[,3],
      Participant  = m3[,4],
      Discriminator= m3[,5],
      Identifier   = m3[,6],
      Vial         = m3[,7] # may be NA if not present
    ))
  }
  stop("Filename does not match expected study, allo, or pilot sample format.")
}

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

parts <- parse_filename(args$pdf)
												
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

final <- data.frame("Consortium" = parts$Consortium,
                    "Project" = parts$Project,
                    "Participant" = parts$Participant,
                    "Discriminator" = parts$Discriminator,
                    "Identifier" = parts$Identifier,
                    "Vial" = parts$Vial,
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
