#-----------------------------------------------------
# Description: 
# This script utilizes the SevenBridges 
# API to generate a metadata manifest file for all
# files within a specified project. This manifest
# can then be used to update all files' metadata using
# the "Update Metadata using Manifest File" feature
# on the BDC user interface.
# 
# 
# Developer: Mike Enger
# Project: 
# Date: 12AUG2024
#
#
# Revisions
# v1.0 initial commit
#
#-----------------------------------------------------

if(!require('getopt')){install.packages('getopt', dependencies = T); library(getopt)}
if(!require('dplyr')){install.packages('dplyr', dependencies = T); library(dplyr)}
if(!require('httr')){install.packages('httr', dependencies = T); library(httr)}
if(!require('stringr')){install.packages('stringr', dependencies = T); library(stringr)}
if(!require('lubridate')){install.packages('lubridate', dependencies = T); library(lubridate)}
if(!require('sevenbridges2')){install.packages('sevenbridges2', dependencies = T); library(sevenbridges2)}
if(!require('jsonlite')){install.packages('jsonlite', dependencies = T); library(jsonlite)}

#-----------------------------------------------------
# Setup global arguments and command line use
#-----------------------------------------------------

# Define usage message
usage <- paste("Usage: script_name.r
             -- Required Parameters --
              [-t | --token]         <API Token> (Required)
              [-p | --project_id]    <Project ID> (Required)
              [-o | --output_path]   <Path to save the output file> (Required)
             -- Help Flag --
              [-h | --help]          <Displays this help message>
             Example:
             script_name.r -t your_token -p project_id -o /path/to/output
              \n", sep="")

# Specify command-line arguments
spec <- matrix(c(
  'token',        't', 1, "character",
  'project_id',   'p', 1, "character",
  'output_path',  'o', 1, "character",
  'help',         'h', 0, "logical"
), byrow=TRUE, ncol=4)

# Parse command-line arguments
args <- getopt(spec)

# Display help message if needed
if (!is.null(args$help) || is.null(args$token) || is.null(args$project_id) || is.null(args$output_path)) {
  cat(usage)
  q(status = 1)
}

# Assign arguments to variables
token <- args$token
project_id <- args$project_id
output_path <- args$output_path



#-----------------------------------------------------
# Setup logging
#-----------------------------------------------------

add_to_log <- function(lvl, func, message){
  timestamp <- paste0("[", Sys.time(), "]")
  entry <- paste(timestamp, func, toupper(lvl), message, sep = " - ")
  cat(paste0(entry, "\n"))
}



#-----------------------------------------------------
# Required Functions and Dataframes
#-----------------------------------------------------

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Initialize empty dataframes and lists
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

df_files_empty <- data.frame(
  id = character(0),
  name = character(0),
  upload_directory = character(0),
  upload_directory_id = character(0),
  size = integer(0),
  project = character(0),
  type = character(0)
)

df_folders_empty <- data.frame(
  id = character(0),
  name = character(0),
  parent_id = character(0),
  parent_name = character(0)
)

metadata_list <- list()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function to extract file and folder info
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

add_to_log("info", "setup", "Setting up recursive file and folder extraction function")
extract_file_folder_info <- function(project_id, parent_id=NA, parent_name="root", df_files, df_folders) {
  
  # initializing offset and combined subdirectory file listing
  offset <- 0
  subdirectory_items_list <- list()
  
  # Make an initial call to the project/directory to see if there are any files
  if (nchar(parent_id) == 0){
    subdirectory_items <- a$files$query(project = project_id, limit = 100, offset = offset)
  } else{
    subdirectory_items <- a$files$query(parent = parent_id, limit = 100, offset = offset)
  }
  
  # Loop to get all files in current directory
  while (length(subdirectory_items$items) > 0) {
    if (nchar(parent_id) == 0){
      subdirectory_items <- a$files$query(project = project_id, limit = 100, offset = offset)
    } else{
      subdirectory_items <- a$files$query(parent = parent_id, limit = 100, offset = offset)
    }
    subdirectory_items_list <- c(subdirectory_items_list,subdirectory_items$items)
    offset <- offset + length(subdirectory_items$items)
  }
  
  for(item in subdirectory_items_list){
    
    if (item$type == "file"){
      add_to_log("info", "extract", paste("Processing file:", item$name))
      file_data_row <- data.frame(
        id = item$id,
        name = item$name,
        upload_directory = parent_name,
        upload_directory_id = parent_id,
        size = ifelse(is.null(item$size), 0, item$size),
        project = item$project,
        type = item$type
      )
      df_files <- bind_rows(df_files,file_data_row)
    }
    
    # Extracting folder info AND going into folder to extract subdirectory and file info
    if (item$type == "folder") {
      add_to_log("info", "extract", paste("Processing folder:", item$name))
      folder_data_row <- data.frame(
        id = item$id,
        name = item$name,
        parent_id = item$parent,
        parent_name = parent_name
      )
      
      df_folders <- bind_rows(df_folders, folder_data_row)
      
      list_df_files_folders <- extract_file_folder_info(project_id = project_id,
                                                        parent_id = item$id,
                                                        parent_name = item$name,
                                                        df_files,df_folders)
      df_files <- list_df_files_folders[[1]]
      df_folders <- list_df_files_folders[[2]]
    }
  }
  return(list(df_files,df_folders))
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function to create the final name column
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

create_final_name <- function(new_name, parent_name) {
  if (is.na(parent_name)) {
    return(new_name)  # If parent_name is NA, return new_name
  }
  if (parent_name == "Root") {
    return(new_name)  # If parent_name is "Root", return new_name
  }
  if (startsWith(parent_name, "Root")) {
    parent_name <- sub("^Root", "", parent_name)  # Remove "Root/" prefix if present
  }
  return(paste(parent_name, new_name, sep = "/"))  # Combine parent_name and new_name
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function to get existing metadata
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
get_metadata <- function(file_id, auth_token) {
  url <- paste0("https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2/files/", file_id, "/metadata")
  
  response <- VERB(
    "GET", 
    url, 
    add_headers('X-SBG-Auth-Token' = auth_token), 
    content_type("application/json"), 
    accept("application/json")
  )
  
  # Parse the response content
  metadata <- fromJSON(content(response, "text", encoding = "UTF-8"), flatten = TRUE)
  metadata$id <- file_id
  return(metadata)
}

#-----------------------------------------------------
# Main 
#-----------------------------------------------------

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Provide required URLs and authenticate
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# URLs required for API calls
api_endpoint <- "https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2"
sb_platform_url <- "https://platform.sb.biodatacatalyst.nhlbi.nih.gov/u/"

add_to_log("info", "setup", "Starting script and setting up API endpoint and platform URL")

# Authenticate
add_to_log("info", "setup", "Authenticating with the API")
a <- Auth$new(token = token, url = api_endpoint)

# Get a specific project and list its files at the root level
add_to_log("info", "get_project", "Retrieving project information")
p <- a$projects$get(id = project_id)
p_root_folder <- p$get_root_folder()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Extract file and folder info 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

add_to_log("info", "main", "Starting extraction of files and folders")
list_df_files_folders_out <- extract_file_folder_info(project_id, p_root_folder$id, "Root", df_files_empty, df_folders_empty)
df_files <- list_df_files_folders_out[[1]]
df_folders <- list_df_files_folders_out[[2]]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Build empty Metadata Manifest
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Join df_files with df_folders to get the parent directory name
df_files <- merge(df_files, df_folders[, c("id", "parent_name")], by.x = "upload_directory_id", by.y = "id", all.x = TRUE)

# Create new name column in df_files with upload_directory appended
# Skip values with upload_directory of Root
df_files$name <- ifelse(df_files$upload_directory == "Root", 
                        df_files$name, 
                        paste(df_files$upload_directory, df_files$name, sep = "/"))

# Apply the create_final_name function to compile complete file name
df_files$name <- mapply(create_final_name, df_files$name, df_files$parent_name)

# Remove unnecessary columns
df_files <- df_files[ , !(names(df_files) %in% c("upload_directory_id", "upload_directory","parent_name", "type"))]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get existing metadata for all files and add to empty metadata manifest
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Loop through the files dataframe and get metadata for each file
for (i in 1:nrow(df_files)) {
  file_id <- df_files$id[i]
  metadata <- get_metadata(file_id, token)
  metadata_list[[i]] <- metadata
}

# Find all unique columns from all metadata
all_columns <- unique(unlist(lapply(metadata_list, names)))

# Ensure each metadata dataframe has all columns
metadata_list <- lapply(metadata_list, function(df) {
  missing_cols <- setdiff(all_columns, names(df))
  df[missing_cols] <- ""
  return(df)
})

# Combine the metadata with the original dataframe
metadata_df <- do.call(rbind, lapply(metadata_list, as.data.frame))

# Combine existing metadata with empty metadata manifest
df_combined <- left_join(df_files, metadata_df, by = "id")

# List of all required metadata fields (in correct order)
required_columns <- c(
  "id", "name", "size","project", "experimental_strategy", "library_id", "platform", "platform_unit_id",
  "file_segment_number", "quality_scale", "paired_end", "reference_genome",
  "investigation", "case_id", "case_uuid", "gender", "race", "ethnicity",
  "primary_site", "disease_type", "age_at_diagnosis", "vital_status",
  "days_to_death", "sample_id", "sample_uuid", "sample_type", "aliquote_id",
  "aliquot_uuid", "description"
)

# Add missing columns with blank (empty string) values
for (col in required_columns) {
  if (!(col %in% names(df_combined))) {
    df_combined[[col]] <- ""
  }
}

# Reorder the columns in df_combined to desired order
df_combined <- df_combined %>%
  select(all_of(required_columns))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Output final manifest to csv
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

today <- format(Sys.Date(), "%Y%m%d")
output_file_name <- paste0("manifest_", today, ".csv")
output_file_path <- file.path(output_path, output_file_name)
write.csv(df_combined, output_file_path, row.names = FALSE)

add_to_log("info", "main", paste("CSV file written to", output_file_path))
add_to_log("info", "main", "Metadata Manifest generated successfully")
