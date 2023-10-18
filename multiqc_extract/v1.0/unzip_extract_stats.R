library(jsonlite)

zip_files <- list.files(path = ".", pattern = "multiqc_data\\.zip")

if(length(zip_files)==0){
  stop("No MultiQC ZIP files found. Exiting")
}

for (zip_file in zip_files){
  output_dir_name <- "output_dir"
  unzip(zip_file,exdir=output_dir_name, overwrite=TRUE)
  
  ############################################
  # EXTRACTING FROM MULTIQC JSON OUTPUT FILE
  ############################################
  
  result <- fromJSON(txt = paste0(output_dir_name,"/multiqc_data.json"))
  sample_name <- names(result$report_data_sources$FastQC$all_sections)
  total_sequences <- na.omit(result$report_general_stats_data[[sample_name]]$total_sequences)[1]
  read_length <- na.omit(result$report_general_stats_data[[sample_name]]$avg_sequence_length)[1]
  
  ############################################################################
  # EXTRACTING FROM MULTIQC OUTPUT TXT FILES
  ############################################################################
  
  multiqc_files <- list.files(path = output_dir_name, recursive = TRUE, full.names = TRUE)
  
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
  
  ##############################
  # WRITE/APPEND TO CSV
  ##############################
  
  output_data <- c(zip_file, sample_name, total_sequences, read_length, max_per_seq_qual, per_base_seq_qual, seq_dup_level, per_base_n_content)
  column_names <- c("zip_file","sample_name","total_sequences","read_length","max_per_sequence_quality_scores","per_base_seq","sd_per_base_seq","sequence_duplication_levels","sd_sequence_duplication_levels","average_per_base_n_content","sd_per_base_n_content")
  
  row <- data.frame(matrix(ncol = length(column_names), nrow=0))
  colnames(row) <- column_names
  row[1,] <- output_data
  
  write.table(x = row, file = "output.csv", append = TRUE, sep = ",", quote = FALSE, row.names = FALSE, col.names = !file.exists("output.csv"))
  
  ###############################
  # REMOVING OUTPUT DIR
  ###############################
  
  unlink(output_dir_name, recursive=TRUE)
}
