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
              help="folder ID [default= %default]", metavar="character")
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

  # Initializing empty list for extracted directory files
  offset <- 0
  subdirectory_files_list <- list()
  
  # Initializing subdirectory_files object and checking for at least one query result
  if (is.na(parent_id)){
    subdirectory_files <- a$files$query(project = project_id, limit = 1, offset = offset)
  } else{
    print(parent_id)
    subdirectory_files <- a$files$query(parent = parent_id, limit = 1, offset = offset)
    print(paste0("Starting folder search with file$id or parent_id: ", parent_id))
  }

  # Looping through directory to get all items
  while (length(subdirectory_files$items) > 0) {
    if (nchar(parent_id) == 0){
      subdirectory_files <- a$files$query(project = project_id, limit = 100, offset = offset)
    } else{
      subdirectory_files <- a$files$query(parent = parent_id, limit = 100, offset = offset)
    }
    print(paste0("Offset: ", offset, "; Number files: ", length(subdirectory_files$items)))
    subdirectory_files_list <- c(subdirectory_files_list,subdirectory_files$items)
    offset <- offset + length(subdirectory_files$items)
  }
  
  # Extracting file info and tag list
  for(file in subdirectory_files_list){
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

get_file_folder_id <- function(project_id, name){
  # Function to get the ID of a specified file or folder
  #   -NOTE: must be full path to specified file or folder
  #          e.g. RMIP_000_Doe/Raw_Data/scRNA/FASTQs/input_fastq.gz
  # INPUT
  #   -project_id: string value of project_id to search
  #   -name: string value containing file/folder full path name
  # OUTPUT
  #   -id: sevenbridges ID of file/folder
  
  string_loop <- unlist(strsplit(x = name, split = "/"))
  
  for (i in 1:length(string_loop)){
    if(i == 1){
      folder_name <- ""
      end_flag <- FALSE
      matched_id <- ""
    }
    if(i == length(string_loop)){
      end_flag <- TRUE
    }
    part <- string_loop[i]
    
    # initializing offset and combined subdirectory file listing
    offset <- 0
    subdirectory_files_list <- list()
    
    # Make an initial call to the project/directory to see if there are any files
    if (nchar(matched_id) == 0){
      subdirectory_files <- a$files$query(project = project_id, limit = 1, offset = offset)
    } else{
      subdirectory_files <- a$files$query(parent = matched_id, limit = 1, offset = offset)
    }
    
    # Loop to get all files in current directory
    print("========================")
    print(paste0("Looping through directory '",ifelse(nchar(folder_name)==0,"root",folder_name),"' for all items"))
    while (length(subdirectory_files$items) > 0) {
      if (nchar(matched_id) == 0){
        subdirectory_files <- a$files$query(project = project_id, limit = 100, offset = offset)
      } else{
        subdirectory_files <- a$files$query(parent = matched_id, limit = 100, offset = offset)
      }
      print(paste0("Offset: ", offset, "; Number files: ", length(subdirectory_files$items)))
      subdirectory_files_list <- c(subdirectory_files_list,subdirectory_files$items)
      offset <- offset + length(subdirectory_files$items)
    }
    
    print(paste0("Searching '",ifelse(nchar(folder_name)==0,"root",folder_name),"' for '",part,"'"))
    for(item in subdirectory_files_list){
      # print(paste0("Continuing folder search in : ", folder_name))
      print(paste0("item NAME: ", item$name))
      print(paste0("item type: ",item$type))
      print(paste0("item id: ",item$id))
      print("")
      if (item$name == part){
        print(paste0("Found '",part,"' with id '",item$id,"', breaking"))
        matched_id <- item$id
        folder_name <- paste0(folder_name,"/",item$name)
        break
      }
    }
    
    if (end_flag){
      id <- matched_id
    }
    print("========================")
  }
  
  print(paste0("Found id '",id,"' for '",name,"'"))
  
  return(id)
}

###

log_loc<-file.path("file_tagging.log")
lf <- log_open(log_loc,logdir = FALSE, show_notes = FALSE)
log_print(paste("File tagging starting...",Sys.time()))

a <- Auth$new(token = token, url = api_endpoint)
if (!is.null(opt$folder)){
  #folder_id<-a$files$query(project = project_id,name = folder_name)$items[[1]]$id
  folder_id <- get_file_folder_id(project_id, folder_name)
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
  if (length(file_name_sep)>2 & file_name_sep[3]=="PL"){
    sample_id <- paste(file_name_sep[3:4],collapse = "_")
    vial <- file_name_sep[5]
    new_tags <- c(sample_id,vial)
    if (length(current_tags)>=1){
      tags <- unique(c(current_tags, new_tags))
    }else{
      tags <- new_tags
    }
    log_print(tags)
    a$files$get(id=df_files_out$id[i])$add_tag(as.list(tags))
    }else if (length(file_name_sep)<6 | file_name_sep[1]!="RMIP"){
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
