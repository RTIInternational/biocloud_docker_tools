library(optparse)

############## Create CL parser
parser = OptionParser(usage = "\n%prog [options] --input_file <input_file> --pvalue_colname <pvalue_colname> --output_file <output_file>", 
                      description = "Program for adjusting pvalues for multiple test correction. Wraps around native R method p.adjust().",
                      prog="Rscript adjust_csv_pvalue.R")
parser = add_option(object=parser, opt_str=c("--input_file"), default=NULL, type="character",
                    help="[REQUIRED] CSV with header line and a column containing pvalues to be adjusted")
parser = add_option(object=parser, opt_str=c("--output_file"), default=NULL, type="character",
                    help="[REQUIRED] CSV output file which will contain adjusted p-value column appended to end")
parser = add_option(object=parser, opt_str=c("--pvalue_colname"), default=NULL, type="character",
                    help="[REQUIRED] Name of input file column containing pvalues to be adjusted.")
parser = add_option(object=parser, opt_str=c("--method"), default=NULL, type="character",
                    help="[REQUIRED] Correction method (holm, hochberg, hommel, bonferroni, BH, BY, fdr, none)")
parser = add_option(object=parser, opt_str=c("--n"), default=NULL, type="integer",
                    help="Number of comparisons, must be at least length(p_value_col); default is to length(p_value_col)")
parser = add_option(object=parser, opt_str=c("--filter_threshold"), default=NULL, type="double",
                    help="Exclude rows in output over this adjusted p-value threshold")
parser = add_option(object=parser, opt_str=c("--tab_delimited"), default=FALSE, type="logical", action="store_true",dest="tab_delimited",
                    help="Input file uses tabs as field separators instead of commas [default %default]")

############## Parse command line
argv = parse_args(parser)

# Check mandatory arguments were set
if(is.null(argv$input_file)){
  stop("Error: Please provide a value for --input_file")
}
if(is.null(argv$output_file)){
  stop("Error: Please provide a value for --output_file")
}
if(is.null(argv$pvalue_colname)){
  stop("Error: Please provide a value for --pvalue_colname")
}
if(is.null(argv$method)){
  stop("Error: Please provide a value for --method")
}


# Check to make sure method values are correct
if(!is.null(argv$method) && !(argv$method %in% c("holm", "hochberg", "hommel", "bonferroni", "BH", "BY", "fdr", "none"))){
  stop("Error: Invalid p-value correction method: ", argv$method, "\nOptions: holm, hochberg, hommel, bonferroni, BH, BY, fdr, none")
}

# Check input file exists
if(!file.exists(argv$input_file)){
  stop(paste0("Error: ",argv$input_file), " does not exist! Check your file path and name.")
}

# Make sure filter value is valid
if((!is.null(argv$filter_threshold)) && ((argv$filter_threshold < 0) || (argv$filter_threshold > 1))){
  stop(paste0("Error: filter_threshold must be between 0 and 1"))
}


# Load dataset
if(argv$tab_delimited){
  data = read.csv(argv$input_file,header=T,sep="\t")
}else{
data = read.csv(argv$input_file, header=T)
}

# Check to make sure colname exists
if(! argv$pvalue_colname %in% colnames(data)){
  stop(paste0("Error: pvalue colname ", argv$pvalue_colname), " is not a valid colname in input file. Please provide valid pvalue column name.")
}

# Check to make sure N-comparisons is larger than number of rows
if((!is.null(argv$n)) && (argv$n < nrow(data))){
  stop(paste0("Error: num comparisons (",argv$n,") must be larger than number of pvalues (",nrow(data), ") in input file!"))
}

# Adjust pvalues based
if(is.null(argv$n)){
  # Number of test corrections automatically determined based on column length
  data$pvalue_adjusted = p.adjust(data[[argv$pvalue_colname]], method=argv$method)
}else{
  # Adjust pvalues with a set number of test corrections
  data$pvalue_adjusted = p.adjust(data[[argv$pvalue_colname]], method=argv$method, n=argv$n)
}

# Filter if necessary
if(!is.null(argv$filter_threshold)){
  data = data[which(data$pvalue_adjusted <= argv$filter_threshold),]
}

# Write to output file
write.csv(data, argv$output_file)




