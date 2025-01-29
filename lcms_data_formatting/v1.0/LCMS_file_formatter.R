library(optparse)
library(openxlsx)
library(readxl)
library(tools)
option_list <- list(
  make_option(c("-f", "--file"), type="character", default=NULL, 
              help="LCMS file", metavar="character"),
  make_option(c("-c", "--column_converter"), type="character", default=NULL, 
              help="LCMS file column converter", metavar="character")

) 

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

if(is.null(opt$file) | is.null(opt$column_converter)){
  stop("LCMS file and column converter are required to run this workflow.")
}else{
  lcms_file <- opt$file
  column_converter_file <- opt$column_converter
}
#read in files
LCMS<-read_xlsx(lcms_file, sheet="combined")
LCMS<- as.data.frame(LCMS)
column_converter <-read.table(column_converter_file, sep=',')

#remove duplicate header columns
LCMS <- subset(LCMS, column != "Column")
LCMS <- subset(LCMS, column != "column")

#correct column names
names(LCMS)[match(column_converter$V1, names(LCMS))] <- column_converter$V2

drops<-c("# Usable QC","RSD QC Areas [%]","RT [min]", "Name")
#remove unnecessary columns
LCMS <-LCMS[, !(names(LCMS) %in% drops)]

#write out files
filename<- file_path_sans_ext(basename(lcms_file))
new_filename_csv<-paste0(filename,"_formatted.csv")
new_filename_xlsx<-paste0(filename,"_formatted.xlsx")
write.table(LCMS, new_filename_csv, sep=',',quote = FALSE)
write.xlsx(LCMS, new_filename_xlsx)

