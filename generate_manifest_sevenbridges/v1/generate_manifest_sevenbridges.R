library(dplyr)
library(stringr)
library(lubridate)
library(openxlsx)
library("sevenbridges2")
library(getopt)

#########################################
########    INPUT ARGUMENTS     ########
#########################################
argString <- commandArgs(trailingOnly = T) # Read in command line arguments

# This is for setting up a human readable set of documentation to display if something is amiss.
usage <- paste("Usage: convert_ab1_to_fasta.r [OPTIONS]
             -- Required Parameters --
              [-t | --token         ]    <Seven Bridges Developer token> (REQUIRED)
              [-p | --project_id    ]    <Project ID, e.g. \"username/test-project\"> (REQUIRED)
             -- Optional Parameters -- 
              [-v | --verbose       ]    <Activates verbose mode>
             -- Help Flag --  
              [-h | --help          ]    <Displays this help message>
             Example:
             convert_ab1_to_fasta.r -v -t <token-here> -p <project_id-here>
              \n",sep="")

# Setup the matrix which consists of long flag (should be all lower case), short flag (case sensitive), parameter class (0=no-arg, 1=required-arg, 2=optional-arg) and parameter type (logical, character, numeric)
spec <- matrix(c(
  'token',            't', 1, "character",
  'project_id',       'p', 1, "character",
  'verbose',          'v', 0, "logical",
  'help',             'h', 0, "logical"
), byrow=TRUE, ncol=4);

# Parse the command line parameters into R
args=getopt(spec, argString)

# If missing required fields then display usage and quit
exitFlag <- 0

if ( !is.null(args$help)) {
  cat(usage)
  q(save="no",status=1,runLast=FALSE)
}

if (is.null(args$token)){
  print("MISSING DEVELOPER TOKEN - Seven Bridges developer token required")
  exitFlag <- 1
}

if (is.null(args$project_id)){
  print("MISSING PROJECT ID - project id required")
  exitFlag <- 1
}

if (exitFlag) {
  cat(usage)
  q(save="no",status=1,runLast=FALSE)
}

print_verbose <- function(x) {if (args$verbose) {print(x)}}

# Extracting inputs
token <- args$token
project_id <- args$project_id

print_verbose(paste0("Received input project_id: ", project_id))


####################################
###    CODE SETUP          #########
####################################
# Setup and such
api_endpoint <- "https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2"
sb_platform_url <- "https://platform.sb.biodatacatalyst.nhlbi.nih.gov/u/"

# Authenticate
a <- Auth$new(token = token, url = api_endpoint)

# Getting a specific project and listing its files at root level
p <- a$projects$get(id = project_id)
p_root_folder <- p$get_root_folder()

# Initializing file and folder dataframes
df_files_empty <- data.frame(
  name = character(0),
  size = integer(0),
  upload_date = as_datetime(character(0)),
  upload_directory = character(0),
  upload_directory_id = character(0),
  sb_uri = character(0),
  type = character(0)
)

df_folders_empty <- data.frame(
  id = character(0),
  name = character(0),
  parent_id = character(0),
  parent_name = character(0)
)

# Function to recursively query the SB API and extract file and folder info
extract_file_folder_info <- function(project_id,parent_id=NA,parent_name="root", df_files, df_folders) {
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
  print_verbose(paste0("Looping through directory '",parent_name,"' for all items"))
  while (length(subdirectory_items$items) > 0) {
    if (nchar(parent_id) == 0){
      subdirectory_items <- a$files$query(project = project_id, limit = 100, offset = offset)
    } else{
      subdirectory_items <- a$files$query(parent = parent_id, limit = 100, offset = offset)
    }
    print_verbose(paste0("Offset: ", offset, "; Number files: ", length(subdirectory_items$items)))
    subdirectory_items_list <- c(subdirectory_items_list,subdirectory_items$items)
    offset <- offset + length(subdirectory_items$items)
  }
  
  for(item in subdirectory_items_list){
    print_verbose(paste0("Continuing folder search with item$id or parent_id: ", parent_id))
    print_verbose(paste0("item NAME: ", item$name))
    print_verbose(paste0("item type: ",item$type))
    print_verbose(paste0("item created_on: ",item$created_on))
    print_verbose(paste0("item size: ",ifelse(is.null(item$size), 0, item$size)))
    print_verbose(paste0("item secondary_files: ",item$secondary_files))
    print_verbose(paste0("item parent: ",item$parent))
    print_verbose(paste0("item id: ",item$id))
    print_verbose("=====================================")
    # print_verbose(item)
    if (item$type == "file"){
      file_data_row <- data.frame(
        name = item$name,
        size = ifelse(is.null(item$size), 0, item$size),
        upload_date = as_datetime(item$created_on),
        upload_directory = parent_name,
        upload_directory_id = parent_id,
        sb_uri = item$href,
        type = item$type
      )
      df_files <- bind_rows(df_files,file_data_row)
    }
    
    # Extracting folder info AND going into folder to extract subdirectory and file info
    if (item$type == "folder") {
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
      print_verbose(paste0("Exiting folder: ", item$name))
      print_verbose("=====================================")
    }
  }
  return(list(df_files,df_folders))
}

list_df_files_folders_out <- extract_file_folder_info(project_id, p_root_folder$id, "Root", df_files_empty, df_folders_empty)
df_files <- list_df_files_folders_out[[1]]
df_folders <- list_df_files_folders_out[[2]]

traverse_to_root <- function(folder_id, df_folders){
  # Initializing build path and parent folder name as empty strings
  build_path <- ""
  parent_name <- ""
  
  # Loop upward through folders until parent directory is "Root"
  while (tolower(parent_name) != "root"){
    # Filter for given folder ID
    row <- df_folders %>%
      filter(id == folder_id)
    
    # Extract info
    folder_name <- row$name
    parent_id <- row$parent_id
    parent_name <- row$parent_name
    build_path <- paste0(folder_name,"/",build_path)
    
    # NEW FOLDER ID IS PARENT ID
    folder_id <- parent_id
  }
  
  # Return the build path when complete
  return(build_path)
}

df_folders$full_path <- lapply(X = df_folders$id, FUN = traverse_to_root, df_folders)
df_folders <- df_folders %>%
  arrange(full_path) %>%
  mutate(depth = str_count(full_path, "\\/"))
df_folders$count <- lapply(X = df_folders$id, FUN = function(x){sum(df_files$upload_directory_id %in% x)})

df_files <- df_files %>%
  mutate(path = df_folders$full_path[match(upload_directory_id,df_folders$id)]) %>%
  mutate(path = ifelse(path=="NULL","Root",path))

##############################################
###    ORGANIZING DATA FOR EXCEL     #########
##############################################
# Getting project id and project_url
project_id
project_url <- paste0(sb_platform_url,project_id)

# Getting file counts in each folder
df_files_root <- df_files %>%
  filter(tolower(path) == "root", tolower(type) == "file") %>%
  mutate(count = n()) %>%
  distinct(path,count) %>%
  mutate(units = ifelse(count==1, "File", "Files"),
         depth = 0,
         count = as.integer(count)) %>%
  select(path,count,units,depth) %>%
  mutate(units = as.character(units))

df_directory_file_counts_no_root <- df_folders %>%
  select(path = full_path, count, depth) %>%
  distinct(path,count,depth) %>%
  mutate(units = ifelse(count==1, "File", "Files"),
         count = as.integer(count)) %>%
  select(path,count,units,depth) %>%
  arrange(sub("\\/.*$","",path)) %>%
  mutate(units = as.character(units))

df_directory_file_counts <- bind_rows(df_files_root,df_directory_file_counts_no_root)

depth_one_indexes <- which(df_directory_file_counts$depth==1)
depth_two_plus_indexes <- which(df_directory_file_counts$depth>1)

## Getting project summary metrics and file manifest dataframes
# Calculating total file counts, size, and most recently uploaded
total_number_files <- sum(df_directory_file_counts$count)
# 1 B to GiB: 9.313225746E-10 GiB / B
byte_to_gigabyte <- 9.313225746E-10
total_size_files_gb <- sum(df_files$size)*byte_to_gigabyte # GiB
date_most_recent <- max(df_files$upload_date[df_files$type == "file"])

summary_metrics_init <- data.frame(metric=character(),value=character(), units=character())
summary_metrics_matrix <- matrix(c("Report Date", as.character(format(Sys.time(), "%Y-%m-%d %H:%M:%S")), NA,
                                   "Project ID", as.character(project_id), NA,
                                   "Project URL", as.character(project_url), NA,
                                   "Total Number of files uploaded", sum(df_directory_file_counts$count), ifelse(sum(df_directory_file_counts$count)==1, "File", "Files"),
                                   "Total Size of uploaded files", total_size_files_gb, "GB",
                                   "Most recent Upload", as.character(date_most_recent), NA),
                                 ncol=3, byrow = TRUE
)
summary_metrics_df <- as.data.frame(summary_metrics_matrix, stringsAsFactors = FALSE)
names(summary_metrics_df) <- names(summary_metrics_init)
summary_metrics <- bind_rows(summary_metrics_init,summary_metrics_df)

df_file_manifest <- df_files %>%
  mutate(size = size*byte_to_gigabyte) %>%
  filter(type=="file") %>%
  select(`File Name` = name, `File Size (GB)` = size, `Upload Date` = upload_date, `Path` = path, `SB URI` = sb_uri) %>%
  arrange(`File Name`)

#####################################
###    WRITING TO EXCEL     #########
#####################################
# Setting up Style objects
hs1 <- createStyle(fontColour = "#000000", fgFill = "#D8D8D8",
                   halign = "center", valign = "center", textDecoration = "Bold")

hs2 <- createStyle(halign = "left", textDecoration = "Bold")
hs3 <- createStyle(halign = "left", textDecoration = c("Bold","underline"))
hs4 <- createStyle(halign = "left", indent = 1)

# write_sheet <- "test_RMIP_inventory"
write_sheet <- gsub("^.*\\/","",project_id)

# Creating the workbook and worksheet
print_verbose(paste0("Writing to workbook: ", write_sheet))
wb <- createWorkbook()
addWorksheet(wb, sheetName = write_sheet)

# Adding headers and data
writeData(wb, sheet = write_sheet,x = "Summary Metrics", startRow = 1, headerStyle = hs1)
mergeCells(wb, sheet= write_sheet, cols=1:5, rows=1)
addStyle(wb, sheet = write_sheet, cols=1:5, rows=1, style = hs1)
writeData(wb, sheet = write_sheet,x = summary_metrics, startCol = 1, startRow = 2, colNames = FALSE, rowNames = FALSE)
writeData(wb, sheet = write_sheet,x = df_directory_file_counts[,1:3], startCol = 1, startRow = 2 + nrow(summary_metrics), colNames = FALSE, rowNames = FALSE )
writeData(wb, sheet = write_sheet,x = "File Manifest", startCol = 1, startRow = 2 + nrow(summary_metrics) + nrow(df_directory_file_counts) + 1, headerStyle = hs1)
mergeCells(wb, sheet = write_sheet, cols=1:5, rows=2 + nrow(summary_metrics) + nrow(df_directory_file_counts) + 1)
addStyle(wb, sheet = write_sheet, cols=1, rows=1 + nrow(summary_metrics) + 1, style = hs3)
addStyle(wb, sheet = write_sheet, cols=1, rows=1 + nrow(summary_metrics) + depth_one_indexes, style = hs2)
addStyle(wb, sheet = write_sheet, cols=1, rows=1 + nrow(summary_metrics) + depth_two_plus_indexes, style = hs4)
addStyle(wb, sheet = write_sheet, cols=1:5, rows=2 + nrow(summary_metrics) + nrow(df_directory_file_counts) + 1, style = hs1)
writeData(wb, sheet = write_sheet,x = df_file_manifest, startCol = 1, startRow = 2 + nrow(summary_metrics) + nrow(df_directory_file_counts) + 2, headerStyle = hs2)
setColWidths(wb, sheet = write_sheet, cols = 1:5, widths = c("30","25","25","25","25"))

# Saving workbook
saveWorkbook(wb, paste0(write_sheet,".xlsx"),overwrite = TRUE)
