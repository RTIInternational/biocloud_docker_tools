library(optparse)
library(openxlsx)
library(readxl)
library(tools)
option_list <- list(
  make_option(c("-f", "--file"), type="character", default=NULL, 
              help="LCMS file in .xlsx format", metavar="character"),
  make_option(c("-c", "--column_converter"), type="character", default=NULL, 
              help="LCMS file column converter in .csv format", metavar="character"),
  make_option(c("-d", "--columns_to_drop"), type="character", default=NULL, 
                help="Column names to drop other than the defaults .csv format", metavar="character")

) 

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

if(is.null(opt$file) | is.null(opt$column_converter)){
  stop("LCMS file and column converter are required to run this workflow.")
}else{
  lcms_file <- opt$file
  column_converter_file <- opt$column_converter
}
if (!is.null(opt$columns_to_drop)){
  if(file_ext(opt$columns_to_drop)!="csv"){
    stop("Columns to drop file must be in .csv format")
  }else{
    columns_to_drop_file<-opt$columns_to_drop
  }
}

if(!(file_ext(lcms_file)=="xlsx")){
  stop("LCMS file must be in .xlsx format")
}

if(file_ext(column_converter_file)!="csv"){
  stop("Column converter file must be in .csv format")
}
lcms_file_sheets<-excel_sheets(lcms_file)
if(!("combined" %in% lcms_file_sheets)){
  stop("LCMS file must contain sheet named combined for formatting")
}

#read in files
LCMS<-read.xlsx(lcms_file, sheet="combined")
LCMS<- as.data.frame(LCMS)
column_converter <-read.table(column_converter_file, sep=',')

#remove duplicate header columns
if("column" %in% names(LCMS)){
	LCMS <- subset(LCMS, column != "Column")
	LCMS <- subset(LCMS, column != "column")
}else if("Column" %in% names(LCMS)){
        LCMS <- subset(LCMS, Column != "Column")
        LCMS <- subset(LCMS, Column != "column")
}else{
  stop("LCMS file must contain a column named Column or column to drop duplicated headers")
}
#correct column names
names(LCMS)[match(column_converter$V1, names(LCMS))] <- column_converter$V2

if(!exists("columns_to_drop_file")){
drops<-c("# Usable QC","RSD QC Areas [%]","RT [min]")
}else{
  drops<-c(read.table(columns_to_drop_file, sep=','))
  print(drops)
}
#remove unnecessary columns
LCMS <-LCMS[, !(names(LCMS) %in% drops)]

#write out files
filename<- file_path_sans_ext(basename(lcms_file))
new_filename_csv<-paste0(filename,"_formatted.csv")
new_filename_xlsx<-paste0(filename,"_formatted.xlsx")
write.table(LCMS, new_filename_csv, sep=',',quote = FALSE)
write.xlsx(LCMS, new_filename_xlsx)

