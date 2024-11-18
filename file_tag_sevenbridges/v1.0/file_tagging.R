library(readr)
library(tidyverse)
library(openxlsx)
library(sevenbridges2)
library(tools)
library(logr)
library(stringr)
library(optparse)
library(dplyr)

option_list <- list(
  make_option(c("-t", "--token"), type="character", default=NULL, 
              help="SB token", metavar="character"),
  make_option(c("-a", "--api_endpoint"), type="character", default="https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2", 
              help="SB token [default= %default]", metavar="character"),
  make_option(c("-p", "--project_id"), type="character", default=NULL, 
              help="project ID [default= %default]", metavar="character"),
  make_option(c("-f", "--folder"), type="character", default=NULL, 
              help="folder [default= %default]", metavar="character")
) 

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

if(is.null(opt$token) | is.null(opt$project_id)){
  stop("SB token and project ID are required to run file tagging.")
}else{
  token <- opt$token
  project_id <- opt$project_id
  api_endpoint <-opt$api_endpoint
}


if (!is.null(opt$folder)){
  folder_name <- opt$folder
}


### functions ###
extract_file_info <- function(project_id,parent_id=NA,parent_name="root", df_files) {
  print(paste(project_id, parent_id,parent_name))
  
  if (is.na(parent_id)){
    subdirectory_files <- a$files$query(project = project_id)
  } else{
    print(parent_id)
    subdirectory_files <- a$files$query(parent = parent_id)
    print(paste0("Starting folder search with file$id or parent_id: ", parent_id))
  }
  
  for(file in subdirectory_files$items){
    print(file$tags)
    print(file)
    data_row <- data.frame(
      name = file$name,
      type = file$type,
      id = file$id
    )
    df_files <- bind_rows(df_files,data_row)
    if (file$type == "folder") {
      df_files <- extract_file_info(project_id = project_id,
                                    parent_id = file$id,
                                    parent_name = file$name,
                                    df_files)
      print(paste0("Exiting folder: ", file$name))
      print("=====================================")
    }
  }
  return(df_files)
}
####

log_loc<-file.path("file_tagging.log")
lf <- log_open(log_loc,logdir = FALSE, show_notes = FALSE)
log_print(paste("File tagging starting...",Sys.time()))

a <- Auth$new(token = token, url = api_endpoint)
if (!is.null(opt$folder)){
  folder_id<-a$files$query(project =project_id,name = folder_name)$items[[1]]$id
}

df_files_empty <- data.frame(
  name = character(0),
  upload_directory = character(0),
  id = character(0)
)

if (!is.null(opt$folder)){
  df_files_out <- extract_file_info(project_id= project_id, parent_id = folder_id,df_files = df_files_empty)
}else{
  df_files_out <- extract_file_info(project_id= project_id, parent_name="Root",df_files=df_files_empty)
}
df_files_out<-subset(df_files_out,type=='file')

for (i in c(1:nrow(df_files_out))){
  current_tags<-unlist(a$files$get(id=df_files_out$id[i])$tags)
  file_name <- df_files_out$name[i]
  file_name_base <- file_path_sans_ext(file_name)
  file_ext <- file_ext(file_name)
  
  file_name_sep<- str_split(file_name_base,pattern = "_",simplify = TRUE)
  if (length(file_name_sep)<6 | file_name_sep[1]!="RMIP"){
    log_print(paste("File", file_name, "is not formatted correctly. This file has not been tagged."), blank_after = FALSE)
  }else{
    log_print(paste("File", file_name, "is formatted correctly. Tagging..."), blank_after = FALSE)
    participant_id <- paste(file_name_sep[1:3],collapse = "_")
    sample_id <- paste(file_name_sep[4:5],collapse = "_")
    vial <- file_name_sep[6]
    #don't tag Allo participants with participant id
    if(length(grep("Allo",participant_id)) > 0){
      new_tags <- c(sample_id, vial, file_ext)
    }else{
      new_tags <- c(participant_id, sample_id, vial, file_ext)
    }
    
    if (length(current_tags)>=1){
      tags <- unique(c(current_tags, new_tags))
    }else{
      tags <- new_tags
    }
    log_print(tags)
    a$files$get(id=df_files_out$id[i])$add_tag(as.list(tags))
  }
}

log_close()
