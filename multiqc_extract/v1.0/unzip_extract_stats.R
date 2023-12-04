library(jsonlite)
library(getopt)

argString <- commandArgs(trailingOnly = T) # Read in command line arguments

# This is for setting up a human readable set of documentation to display if something is amiss. 
usage <- paste("Usage: unzip_extract_stats.R
             -- Required Parameters --
              NONE
             -- Optional Parameters -- 
              [-i | --inputpath]    <Name of input working directory> (default = .)
              [-o | --outfile  ]    <The output file name> (default = output.csv)
              [-p | --outpath  ]    <Path to the directory to save the outputs> (default = input path)
             -- Help Flag --  
              [-h | --help     ]    <Displays this help message>
             Example:
             unzip_extract_stats.R -i results_2023_01_01 -o my_test_results.csv -p my_test_run
              \n",sep="")

# Setup the matrix which consists of long flag (should be all lower case), short flag (case sensitive), parameter class (0=no-arg, 1=required-arg, 2=optional-arg) and parameter type (logical, character, numeric)
spec <- matrix(c(
          'inputpath','i', 2, "character",
          'outfile',  'o', 2, "character",
          'outpath',  'p', 2, "character",
          'help',     'h', 0, "logical"
          ), byrow=TRUE, ncol=4);

# Parse the command line parameters into R
args=getopt(spec, argString)


# If missing required fields then display usage and quit
if ( !is.null(args$help)) {
  cat(usage)
  q(save="no",status=1,runLast=FALSE)
}

# If values aren't supplied by the user then assign the default values
if(is.null(args$inputpath)){args$inputpath <- "."}
if(!file.exists(args$inputpath)){
  stop(paste0("Input path '",args$inputpath,"' not found"))
}
if(is.null(args$outpath)){args$outpath <- args$inputpath}
if(!file.exists(args$outpath)){
  print(paste0("Output directory '",args$outpath, "' not found, creating..."))
  dir.create(args$outpath)
}
if(is.null(args$outfile)){args$outfile <- paste0(args$outpath,"/output.csv")}else{args$outfile <- paste0(args$outpath,"/",args$outfile)}

# The output file must be saved as a .csv file.  If the value supplied doesn't end in .csv, it will be appended below
if(!grepl("\\.csv$",args$outfile)){
  print("File must be .csv, appending .csv to name given")
  args$outfile <- paste0(args$outfile,".csv")
  }

zip_files <- list.files(path = args$inputpath, pattern = "multiqc_data\\.zip")
fastq_files <- list.files(path = args$inputpath, pattern = "\\.fastq$")

if(length(zip_files)==0){
  stop("No MultiQC ZIP files found. Exiting")
}

if(length(zip_files) != length(fastq_files)){
  stop("Not all FASTQ files have completed WGS workflow")
}

for (zip_file in zip_files){
  tmp_unzip_dir_name <- "output_dir"
  unzip(zip_file,exdir=tmp_unzip_dir_name, overwrite=TRUE)
  
  ############################################
  # EXTRACTING FROM MULTIQC JSON OUTPUT FILE
  ############################################
  
  result <- fromJSON(txt = paste0(tmp_unzip_dir_name,"/multiqc_data.json"))
  sample_name <- names(result$report_data_sources$FastQC$all_sections)
  total_sequences <- na.omit(result$report_general_stats_data[[sample_name]]$total_sequences)[1]
  read_length <- na.omit(result$report_general_stats_data[[sample_name]]$avg_sequence_length)[1]
  
  ############################################################################
  # EXTRACTING FROM MULTIQC OUTPUT TXT FILES
  ############################################################################
  
  multiqc_files <- list.files(path = tmp_unzip_dir_name, recursive = TRUE, full.names = TRUE)
  
  per_sequence_quality_scores_file <- multiqc_files[grepl('per_sequence_quality_scores.*.txt',multiqc_files)]
  per_base_seq_quality_file <- multiqc_files[grepl('per_base_sequence_quality.*.txt',multiqc_files)]
  sequence_duplication_levels_file <- multiqc_files[grepl('sequence_duplication_levels.*.txt',multiqc_files)]
  per_base_n_content_file <- multiqc_files[grepl('per_base_n_content.*.txt',multiqc_files)]
  
  extract_max_per_seq_quality_score <- function(input_file){
    dat = t(read.table(input_file,row.names = 1))
    out_dat = max(dat[,2])
    return(out_dat)
  }
  
  extract_per_base_seq_quality <- function(input_file){
    dat = t(read.table(input_file,row.names = 1))
    out_dat_mean = mean(dat[dat[,1] >= 30,2])
    out_dat_sd = sd(dat[dat[,1] >= 30,2])
    return(c(out_dat_mean,out_dat_sd))
  }
  
  extract_seq_duplication_level <- function(input_file){
    dat = t(read.table(input_file,row.names = 1, fill = TRUE))
    out_dat_mean = mean(as.numeric(as.vector(dat[!is.na(dat[,2]) & nchar(dat[,2])>0,2])))
    out_dat_sd = sd(as.numeric(as.vector(dat[!is.na(dat[,2]) & nchar(dat[,2])>0,2])))
    return(c(out_dat_mean,out_dat_sd))
  }
  
  extract_per_base_n_content <- function(input_file){
    dat = t(read.table(input_file,row.names = 1))
    out_dat_mean = mean(dat[,2])
    out_dat_sd = sd(dat[,2])
    return(c(out_dat_mean,out_dat_sd))
  }
  
  
  max_per_seq_qual <- extract_max_per_seq_quality_score(per_sequence_quality_scores_file)
  per_base_seq_qual <- extract_per_base_seq_quality(per_base_seq_quality_file)
  seq_dup_level <- extract_seq_duplication_level(sequence_duplication_levels_file)
  per_base_n_content <- extract_per_base_n_content(per_base_n_content_file)
  
  #############################################
  # GETTING ROW NUMBER OF EXISTING CSV
  #############################################
  if(file.exists(args$outfile)){
    data <- read.csv(args$outfile)
    max_row = nrow(data)
  } else{
    max_row = 0
    }
  
  ###############################
  # WRITE/APPEND TO CSV
  ###############################
  output_data <- c(max_row + 1,zip_file, sample_name, total_sequences, read_length, max_per_seq_qual, per_base_seq_qual, seq_dup_level, per_base_n_content)
  column_names <- c("row_number","zip_file","sample_name","total_sequences","read_length","max_per_sequence_quality_scores","per_base_seq","sd_per_base_seq","sequence_duplication_levels","sd_sequence_duplication_levels","average_per_base_n_content","sd_per_base_n_content")
  
  row <- data.frame(matrix(ncol = length(column_names), nrow=0))
  colnames(row) <- column_names
  row[1,] <- output_data
  
  write.table(x = row, file = args$outfile, append = TRUE, sep = ",", quote = FALSE, row.names = FALSE, col.names = !file.exists(args$outfile))
  
  ###############################
  # REMOVING OUTPUT DIR
  ###############################
  
  unlink(tmp_unzip_dir_name, recursive=TRUE)
}