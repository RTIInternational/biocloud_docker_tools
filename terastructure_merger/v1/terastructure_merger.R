# Created by: awaldrop
# Created on: 2020-03-25
library(optparse)

# Command line program for standardizing output from terastructure so that multiple files
# With the same K and overlapping samples can be concatenated meaningfully
# Aligns columns by setting the position of each column in a file to the template column with the highest R2 value

# Create command line parser
parser = OptionParser(usage = "\n%prog [options] --template_theta <template_theta_file> --template_fam <template_fam_file> --theta <theta_file> --fam <fam_file> --output_filename <output_filename>",
                      description = "Program for aligning theta columns output by terastructure to a template",
                      prog="Rscript process_king_kinship.R")
parser = add_option(object=parser, opt_str=c("--template_theta"), default=NULL, type="character",
                    help="[REQUIRED] Path to template theta file you want to align against")
parser = add_option(object=parser, opt_str=c("--template_fam"), default=NULL, type="character",
                    help="[REQUIRED] Path to template fam file with sample names for template theta file")
parser = add_option(object=parser, opt_str=c("--theta"), default=NULL, type="character",
                    help="[REQUIRED] Theta file you want to align against template")
parser = add_option(object=parser, opt_str=c("--fam"), default=NULL, type="character",
                    help="[REQUIRED] Fam file with sample names for theta file")
parser = add_option(object=parser, opt_str=c("--output_filename"), default=NULL, type="character",
                    help="[REQUIRED] Output filename.")

############## Parse command line
argv = parse_args(parser)

# Parse command args
template_fam_file = argv$template_fam
template_theta_file = argv$template_theta
fam_file = argv$fam
theta_file = argv$theta
output_filename = argv$output_filename

get_theta_df = function(theta_file, fam_file){
  theta = read.table(theta_file)
  fam = read.table(fam_file)
  if(ncol(fam) != 6){
    stop("Fam file doesn't have 6 columns! Are you sure this is a fam file?")
  }
  
  colnames(fam) = c("FID", "IID", "PID", "MID", "SEX", "PHENO")
  
  if(nrow(theta) != nrow(fam)){
    stop("Theta and fam file have different number of samples!")
  }
  # Add rownames that are unique to sample
  rownames(theta) = paste0(fam$FID,"_",fam$IID)
  return(theta)
}

map_theta_col = function(col, theta, template_theta){
  # Compute correlation between theta column of interest and all template theta cols
  col_r2 = sapply(1:ncol(template_theta), function(template_col){
    df = data.frame(x=theta[,col], y=template_theta[,template_col])
    return(summary(lm(y ~ x, df))$r.squared)
  })
  # Get index of template column with highest r-squared
  return(which(col_r2 == max(col_r2)))
}

# Read thetas and associate sample names from fam files
template_theta = get_theta_df(template_theta_file, template_fam_file)
theta = get_theta_df(theta_file, fam_file)

# Save this for later
original_theta = theta

# Error out if they don't have the same number of columns
if(ncol(template_theta) != ncol(theta)){
  stop("Template thetas and input thetas have differing column number! These can't be merged.")
}

# Get intersection of samples to perform alignment with
sample_intersect = intersect(rownames(template_theta), rownames(theta))

# Error out if not samples intersect
if(length(sample_intersect) == 0){
  stop("Cannot align input theta file to template because no overlapping samples detected!")
}

# Subset samples to intersect
template_theta = template_theta[sample_intersect,]
theta = theta[sample_intersect,]
print(paste0("Found ", nrow(theta), " overlapping samples between input and template"))

# Go through each column in theta and find the column that it maps best to
output_col_order = rep(0, ncol(theta))
for(i in 1:ncol(theta)){
  # Get index of template column that corresponds to theta column
  mapped_col = map_theta_col(i, theta, template_theta)
  # Set current column to be put in the same position as the template theta
  output_col_order[mapped_col] = i
}

# Throw error if any template columns weren't uniquely mapped
if(length(output_col_order[output_col_order == 0]) > 0){
  stop("Input theta columns could not be uniquely mapped to template theta!")
}

# Else re-order your theta 
print("Writing output file!")
original_theta = original_theta[,output_col_order]
write.table(
  original_theta,
  file=output_filename,
  quote=FALSE,
  sep="\t",
  row.names=FALSE,
  col.names=FALSE
)

