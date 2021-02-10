library(ggplot2)
library(optparse)
library(viridis)


############## Create CL parser
parser = OptionParser(usage = "\n%prog [options] --input_file <input_file> --rg_colname <rg_colname> --se_colname <se_colname> --label_colname <label_colname> --group_colname <group_colname> --output_file <output_file>", 
                      description = "Program for plotting genetic correlation results between a single trait and set of traits of interest using LDSC.",
                      prog="Rscript plot_ld_regression_results.R")
parser = add_option(object=parser, opt_str=c("--input_file"), default=NULL, type="character",
                    help="[REQUIRED] TSV with header line and a columns containing the correlation coefficient, standard error, trait labels, and trait groups")
parser = add_option(object=parser, opt_str=c("--output_file"), default=NULL, type="character",
                    help="[REQUIRED] path to PDF output")
parser = add_option(object=parser, opt_str=c("--rg_colname"), default="rg", type="character",
                    help="Name of column containing correlation coefficient [default %default].")
parser = add_option(object=parser, opt_str=c("--se_colname"), default="se", type="character",
                    help="Name of column containing standard error of rg [default %default].")
parser = add_option(object=parser, opt_str=c("--label_colname"), default="Trait_Label", type="character",
                    help="Name of column containing names of each trait [default %default].")
parser = add_option(object=parser, opt_str=c("--group_colname"), default="Trait_Group", type="character",
                    help="Name of column containing phenotype group for each trait [default %default].")
parser = add_option(object=parser, opt_str=c("--pvalue_colname"), default="p", type="character",
                    help="Name of column containing correlation p-value [default %default].")
parser = add_option(object=parser, opt_str=c("--comma_delimited"), default=FALSE, type="logical", action="store_true",dest="comma_delimited",
                    help="Input file uses commas as field separators instead of tabs [default %default]")
parser = add_option(object=parser, opt_str=c("--pvalue_threshold"), default=1.0, type="double",
                    help="Exclude traits from figure with pvalues above a given threshold [default %default]")
parser = add_option(object=parser, opt_str=c("--group_order_file"), default=NULL, type="character",
                    help="csv containing group orders as they will appear on plot (one group per row, no header)")
parser = add_option(object=parser, opt_str=c("--bold_p"), default="yes", type="character",
                    help=" Bold all of the phenotypes that have a significant P-value (bonferroni corrected).")
parser = add_option(object=parser, opt_str=c("--title"), default="", type="character",
		    help="Title of the plot. Make sure to wrap in quotes.")
parser = add_option(object=parser, opt_str=c("--xmin"), default=-10.001, type="double",
		    help="xminimum during the plot.")
parser = add_option(object=parser, opt_str=c("--xmax"), default=10.001, type="double",
		    help="xmaximum during the plot.")
parser = add_option(object=parser, opt_str=c("--vertical_rg"), default=10000, type="double",
		    help="Plot a vertical line at any value of rg (e.g. at rg=1 )")
parser = add_option(object=parser, opt_str=c("--colorblind"), default=FALSE, type="logical", action="store_true",dest="colorblind",
		    help="Use colorblind-conscience colors for the plot.")
############## Parse command line
argv = parse_args(parser)

# Check mandatory arguments were set
if(is.null(argv$input_file)){
  stop("Error: Please provide a value for --input_file")
}
if(is.null(argv$output_file)){
  stop("Error: Please provide a value for --output_file")
}

# Check input file exists
if(!file.exists(argv$input_file)){
  stop(paste0("Error: ",argv$input_file), " does not exist! Check your file path and name.")
}

# Check input file exists
if(!is.null(argv$group_order_file) && !file.exists(argv$group_order_file)){
  stop(paste0("Error: ",argv$group_order_file), " does not exist! Check your file path and name.")
}

# Make sure filter value is valid
if((!is.null(argv$pvalue_threshold)) && ((argv$pvalue_threshold < 0) || (argv$pvalue_threshold > 1))){
  stop(paste0("Error: pvalue_threshold must be between 0 and 1"))
}

# Bold significant phenotypes (bonferroni corrected) should be "yes" or "no"
if( !(argv$bold_p %in% list("yes", "no"))){
  stop(paste0("Error: bold_p must be either yes or no (in quotes)."))
}

# Set input file delimiter character
if(argv$comma_delimited){
  delim = ","
}else{
  delim = "\t"
}


# Set parameters from command line
rg_colname = argv$rg_colname
se_colname = argv$se_colname
trait_label_colname = argv$label_colname
group_label_colname = argv$group_colname
pvalue_colname = argv$pvalue_colname
pvalue_threshold = argv$pvalue_threshold
plot_title = argv$title
xmin = argv$xmin
xmax = argv$xmax
vline = argv$vertical_rg
colorblind = argv$colorblind


# Read data from CSV
data = read.table(argv$input_file, header=T, stringsAsFactors=F, sep=delim)

# Check to make sure required columns actually exist
check_col_exists = function(param_name, value){
  if(!argv[[param_name]] %in% colnames(data)){
    stop(paste0("Error: ", param_name, " ", value, " is not a valid colname in input file. Please provide valid column name."))
  }
}
check_col_exists("rg_colname", argv$rg_colname)
check_col_exists("se_colname", argv$se_colname)
check_col_exists("label_colname", argv$label_colname)
check_col_exists("group_colname", argv$group_colname)
check_col_exists("pvalue_colname", argv$pvalue_colname)

# Convert to standard colnames
colnames(data)[which(colnames(data) == rg_colname)] = "rg"
colnames(data)[which(colnames(data) == se_colname)] = "se"
colnames(data)[which(colnames(data) == trait_label_colname)] = "trait"
colnames(data)[which(colnames(data) == group_label_colname)] = "group"
colnames(data)[which(colnames(data) == pvalue_colname)] = "p"

# Read in group order file if necessary
if(!is.null(argv$group_order_file)){
  group_order_df = read.csv(argv$group_order_file, header=F, stringsAsFactors=F)
  colnames(group_order_df) = c("GroupOrder")
  
  # Make sure group order file has same number of groups
  if(nrow(group_order_df) != length(unique(data$group))){
    stop(paste0("Error: Different number of groups in group order file and data file!"))
  }
  
  # Make sure they have the same groups
  if(length(intersect(group_order_df$GroupOrder, unique(data$group))) != nrow(group_order_df)){
    stop(paste0("Error: Group order file contains different groups than data file"))
  }
  
  # Set group order for plotting
  data$group = factor(data$group, levels=rev(group_order_df$GroupOrder))
}

# Remove NA rg rows
data = data[!is.na(data$rg),]

# Add error bar min/max
data$xmin = data$rg - data$se * 1.96
data$xmax = data$rg + data$se * 1.96


# If the user
if (xmax==10.001){
    xmax = max(data$xmax)
}
if (xmin==-10.001){
    xmin = min(data$xmin)
}

# clip data if necessary

# Sort by correlation coefficient
data = data[order(data$group, data$rg), ]


if (argv$bold_p == "yes") {
	pvalue_bold <- 0.05 / length(data$p)   # bonferroni corrected p-value. 
} else {
	pvalue_bold <- 0   # don't bold any phenotype
}



# Subset by pvalue
data = data[data$p < pvalue_threshold,]

if(nrow(data) == 0){
  stop("No columns remains after filtering on pvalue threshold! Choose a better threshold.")
}

data$group_color = factor(data$group, levels=rev(levels(data$group)))
# Order factors for plotting
data$trait = factor(data$trait, levels=data$trait)
bold_vector <- (data$p < pvalue_bold)
bold_vector[which(bold_vector == TRUE)] <- "bold"
bold_vector[which(bold_vector == FALSE)] <- "plain"

pdf(argv$output_file, width=11, height=8)
my_plot <- ggplot(data, aes(x = rg, y = trait, color=group)) +
  geom_vline(aes(xintercept = 0), size = 0.25, linetype = "dashed") +
  geom_errorbarh(aes(xmin = xmin, xmax = xmax), size = .5, height = .2) +
  geom_point(size = 3.5) + theme_bw() +
  ylab("") + theme(legend.title=element_blank(), 
  plot.title = element_text(hjust = 0.5)) +
  guides(color = guide_legend(reverse=T)) + ggtitle(plot_title) + geom_vline(xintercept = vline) + coord_cartesian(xlim = c(xmin,xmax), clip = "on") 


if (colorblind){
    my_plot + theme(
        axis.text.y = element_text(face=bold_vector)) + scale_colour_viridis_d()
} else {
    my_plot + theme(
        axis.text.y = element_text(face=bold_vector)) 
}

dev.off()
