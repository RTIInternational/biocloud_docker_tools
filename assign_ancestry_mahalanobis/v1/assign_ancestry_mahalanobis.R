#!/usr/local/bin/Rscript

library(scatterplot3d)
library(optparse)

option_list = list(
    make_option(
        c('--file-pcs'),
        action='store',
        default=NULL,
        type='character',
        help="Path to file with PCs (required)"
    ),
    make_option(
        c('--pc-count'),
        action='store',
        default=10,
        type='integer',
        help="# of PCs"
    ),
    make_option(
        c('--dataset'),
        action='store',
        default=NULL,
        type='character',
        help="Name of dataset, as labeled in --file-pcs (required)"
    ),
    make_option(
        c('--dataset-legend-label'),
        action='store',
        default=NULL,
        type='character',
        help="Label to use for dataset in plot legend"
    ),
    make_option(
        c('--ref-pops'),
        action='store',
        default=NULL,
        type='character',
        help="List of reference populations separated by commas, as labeled in --file-pcs (required)"
    ),
    make_option(
        c('--ref-pops-legend-labels'),
        action='store',
        default=NULL,
        type='character',
        help="Labels to use for reference populations in plot legend, separated by commas"
    ),
    make_option(
        c('--out-dir'),
        action='store',
        default=NULL,
        type='character',
        help="Directory for output files (required)"
    ),
    make_option(
        c('--use-pcs-count'),
        action='store',
        default=10,
        type='integer',
        help="# of PCs to use for ancestry determination"
    ),
    make_option(
        c('--midpoint-formula'),
        action='store',
        default='median',
        type='character',
        help="Formula to use for calculating PC midpoint (mean or median)"
    ),
    make_option(
        c('--std-dev-cutoff'),
        action='store',
        default=3,
        type='integer',
        help="StdDev threshold for filtering ancestries"
    )
)

get_arg = function(args, parameter) {
    return(args[parameter][[1]])
}

check_for_required_args = function(args) {
    requiredArgs = c(
        'file-pcs',
        'dataset',
        'ref-pops',
        'out-dir'
    )
    for (arg in requiredArgs) {
        if (is.null(get_arg(args, arg))) {
            stop(paste0('Required argument --', arg, ' is missing'))
        }
    }
}

get_plot_axis_limits = function(pc_vector) {
    max_value = max(pc_vector) * 1.02
    min_value = min(pc_vector) - (max_value - max(pc_vector))
    return(c(min_value, max_value))
}

generate_pc_plot = function(pcs, x_axis, y_axis, z_axis, xlim, ylim, zlim, legend_labels, legend_colors, out_dir, out_name) {
    if (is.null(xlim)) {
        xlim = get_plot_axis_limits(pcs[,x_axis])
    }
    if (is.null(ylim)) {
        ylim = get_plot_axis_limits(pcs[,y_axis])
    }
    if (is.null(zlim)) {
        zlim = get_plot_axis_limits(pcs[,z_axis])
    }
    file_out = paste0(out_dir, out_name, ".png")
    png(file_out, width = 1000, height = 1000, type="cairo")
    par(mar=c(5,6,4,1)+.1)
    scatterplot3d(
        pcs[, x_axis],
        pcs[, y_axis],
        pcs[, z_axis],
        color=pcs$color,
        angle= 45,
        cex.symbols=.5,
        xlab=x_axis,
        ylab=y_axis,
        zlab=z_axis,
        cex.lab = 2,
        cex.axis = 1,
        xlim = xlim,
        ylim = ylim,
        zlim = zlim
    )
    legend(
        "topleft",
        legend=legend_labels,
        fill=legend_colors,
        cex=2
    )
    dev.off()
}

calculate_mahalanobis_distance = function(pcs, use_pcs, midpoint_formula) {
    n_ind = nrow(pcs)
    for (i in 1:n_ind){
        for (ancestry in ancestries) {
            pcs_to_use = pcs[pcs$POP %in% ancestry, (1:use_pcs)+2]
            midpoint = apply(pcs_to_use, 2, midpoint_formula)
            cov = cov(pcs_to_use)
            pcs[i, ancestry] = mahalanobis(pcs[i,(1:use_pcs)+2], midpoint, cov)
        }
    }
    return(pcs)
}

# Get command line arguments
args = parse_args(OptionParser(option_list=option_list))
check_for_required_args(args)
cat("Arguments:\n")
str(args)

# Add "/" to end of --out-dir if needed
out_dir = get_arg(args, 'out-dir')
if (nchar(out_dir) > 0 && substr(out_dir, nchar(out_dir), nchar(out_dir)) != '/') {
    out_dir = paste0(out_dir, '/')
}

# Get pops
dataset = get_arg(args, 'dataset')
ancestries = unlist(strsplit(get_arg(args, 'ref-pops'), split = ","))
pops = c(ancestries, dataset)

# Get legend-labels
if (is.null(get_arg(args, 'dataset-legend-label'))) {
    dataset_legend_label = dataset
} else {
    dataset_legend_label = get_arg(args, 'dataset-legend-label')
}
if (is.null(get_arg(args, 'ref-pops-legend-labels'))) {
    ancestry_legend_labels = ancestries
} else {
    ancestry_legend_labels = unlist(strsplit(get_arg(args, 'ref-pops-legend-labels'), split = ","))
}
legend_labels = c(ancestry_legend_labels, dataset_legend_label)

# Set standard deviation cutoffs
if (is.null(get_arg(args, 'std-dev-cutoff'))) {
    sd_cutoffs = c(4,3,2)
} else {
    sd_cutoffs = get_arg(args, 'std-dev-cutoff')
}

# Read PCs
pcs = read.table(
    get_arg(args, 'file-pcs'),
    header=T,
    stringsAsFactors=F
)

# Concatenate FID & IID
pcs$ID = paste(pcs$FID, pcs$IID, sep="___")

# Set colors for plots
n_ref_pops = length(ancestries)
colors = c(rainbow(n_ref_pops), 'black')
plot_settings = data.frame(pops, legend_labels, colors)
colnames(plot_settings) = c('pop', 'legend_label', 'color')
for (pop in pops) {
    pcs[pcs$POP == pop, 'color'] = plot_settings[plot_settings$pop == pop, 'color']
}

# Get axis limits for plots
pc1_lim = get_plot_axis_limits(pcs[, 'PC1'])
pc2_lim = get_plot_axis_limits(pcs[, 'PC2'])
pc3_lim = get_plot_axis_limits(pcs[, 'PC3'])

# Generate plot of PC1, PC2, and PC3 for reference populations
generate_pc_plot(
    pcs[pcs$POP %in% ancestries,],
    'PC1',
    'PC2',
    'PC3',
    pc1_lim,
    pc2_lim,
    pc3_lim,
    plot_settings[plot_settings$pop %in% ancestries, 'legend_label'],
    plot_settings[plot_settings$pop %in% ancestries, 'color'],
    out_dir,
    'ref_pc1_pc2_pc3'
)

# Generate plot of PC1, PC2, and PC3 for dataset
generate_pc_plot(
    pcs[pcs$POP %in% get_arg(args, 'dataset'),],
    'PC1',
    'PC2',
    'PC3',
    pc1_lim,
    pc2_lim,
    pc3_lim,
    plot_settings[plot_settings$pop %in% dataset, 'legend_label'],
    plot_settings[plot_settings$pop %in% dataset, 'color'],
    out_dir,
    paste0(dataset, '_pc1_pc2_pc3')
)

# Generate plot of PC1, PC2, and PC3 for reference populations and dataset
generate_pc_plot(
    pcs,
    'PC1',
    'PC2',
    'PC3',
    pc1_lim,
    pc2_lim,
    pc3_lim,
    plot_settings$legend_label,
    plot_settings$color,
    out_dir,
    paste0(dataset, '_ref_pc1_pc2_pc3')
)

# Calculate Mahalanobis distance
n_pcs = 4
pcs = calculate_mahalanobis_distance(pcs, n_pcs, get_arg(args, 'midpoint-formula'))

# Remove ref population outliers
p_cut = 0.99
chi_thresh = qchisq(p_cut, n_pcs)
drop = data.frame(matrix(ncol = 2, nrow = 0))
colnames(drop) = c("POP","ID")
for (ancestry in ancestries){
    drop = rbind(drop, pcs[pcs$POP == ancestry & pcs[, ancestry] > chi_thresh, c("POP","ID")])
}
filtered_pcs = pcs[!pcs$ID %in% drop[,2],]

# Write dropped ref samples to file
ids = data.frame(do.call('rbind', strsplit(as.character(drop$ID),'___',fixed=TRUE)))
out_drop = cbind(drop$POP, ids)
colnames(out_drop) = c('POP', 'FID', 'IID')
write.table(
    out_drop,
    file=paste0(out_dir, 'ref_dropped_samples.tsv'),
    quote=FALSE,
    sep="\t",
    row.names=F
)

# Re-calculate Mahalanobis distance
filtered_pcs = calculate_mahalanobis_distance(
    filtered_pcs,
    get_arg(args, 'use-pcs-count'),
    get_arg(args, 'midpoint-formula')
)

# Assign ancestry based on smallest Mahalanobis distance
for (i in 1:nrow(filtered_pcs)){
    filtered_pcs[i, "ANCESTRY"] = ancestries[filtered_pcs[i, ancestries] %in% min(filtered_pcs[i, ancestries])]
}

# Write reference assignments with mahalanobis distances
write.table(
    filtered_pcs[!(filtered_pcs$POP == dataset), c('FID', 'IID', 'POP', ancestries, 'ANCESTRY')],
    file=paste0(out_dir, 'ref_raw_ancestry_assignments.tsv'),
    quote=FALSE,
    sep="\t",
    row.names=F
)

# Write summary of reference assignments
ref_samples = filtered_pcs[!(filtered_pcs$POP == dataset), c("POP", "ANCESTRY")]
summary = as.data.frame.matrix(table(ref_samples$POP, ref_samples$ANCESTRY))
summary = cbind(rownames(summary), summary)
colnames(summary)[1] = 'POP'
write.table(
    summary,
    file=paste0(out_dir, 'ref_raw_ancestry_assignments_summary.tsv'),
    quote=FALSE,
    sep="\t",
    row.names=F
)

# Calculate scaled Mahalanobis distance for dataset samples
dataset_samples = filtered_pcs[filtered_pcs$POP == dataset,]
scaled = data.frame(matrix(ncol = 2, nrow = 0))
colnames(scaled) = c("ID","SCALED_MAHAL")
for (ancestry in ancestries) {
    tempScaled = dataset_samples[dataset_samples$ANCESTRY == ancestry, c("ID", ancestry)]
    tempScaled$SCALED_MAHAL = abs(scale(tempScaled[, ancestry], center=median(tempScaled[, ancestry]), scale=sd(tempScaled[, ancestry])))
    tempScaled = tempScaled[, c("ID", "SCALED_MAHAL")]
    scaled = rbind(scaled, tempScaled)
}
dataset_samples = merge(dataset_samples, scaled, sort=FALSE)
dataset_samples = dataset_samples[order(dataset_samples$ANCESTRY,dataset_samples$SCALED_MAHAL),]

# Write raw dataset ancestry assignments with mahalanobis distances
write.table(
    dataset_samples[, c('FID', 'IID', 'POP', ancestries, 'SCALED_MAHAL', 'ANCESTRY')],
    file=paste0(out_dir, dataset, '_raw_ancestry_assignments.tsv'),
    quote=FALSE,
    sep="\t",
    row.names=F
)

# Get summary of raw dataset ancestry assignments
summary = as.data.frame.matrix(table(dataset_samples$POP, dataset_samples$ANCESTRY))
summary = cbind(c('Raw'), summary)
colnames(summary)[1] = 'FILTER'

# Generate plots of raw dataset ancestry assignments
for (ancestry in ancestries) {
    dataset_samples[dataset_samples$ANCESTRY == ancestry, 'color'] = plot_settings[plot_settings$pop == ancestry, 'color']
}
generate_pc_plot(
    dataset_samples,
    'PC1',
    'PC2',
    'PC3',
    pc1_lim,
    pc2_lim,
    pc3_lim,
    plot_settings[plot_settings$pop %in% ancestries, 'pop'],
    plot_settings[plot_settings$pop %in% ancestries, 'color'],
    out_dir,
    paste0(dataset, '_raw_ancestry_assignment')
)

# Create lists for each ancestry, summary, and plots for different # of standard deviations
for (sd in sd_cutoffs) {
    # Write lists
    for (ancestry in ancestries) {
        out = dataset_samples[dataset_samples$ANCESTRY == ancestry & dataset_samples$SCALED_MAHAL <= sd,]
        write.table(
            out[, c('FID', 'IID')],
            file=paste0(out_dir, dataset, '_', tolower(ancestry), '_', sd, '_stddev_keep.tsv'),
            quote=FALSE,
            sep="\t",
            row.names=F
        )
    }
    # Get summary of ancestry assignments
    out = dataset_samples[dataset_samples$SCALED_MAHAL <= sd,]
    newSummary = as.data.frame.matrix(table(out$POP, out$ANCESTRY))
    newSummary = cbind(c(paste0(sd, '_StdDev')), newSummary)
    colnames(newSummary)[1] = 'FILTER'
    summary = rbind(summary, newSummary)
    # Generate plots
    plot_data = data.frame(dataset_samples)
    plot_data[plot_data$SCALED_MAHAL > sd, 'color'] = 'black'
    generate_pc_plot(
        out,
        'PC1',
        'PC2',
        'PC3',
        pc1_lim,
        pc2_lim,
        pc3_lim,
        plot_settings[plot_settings$pop %in% ancestries, 'pop'],
        plot_settings[plot_settings$pop %in% ancestries, 'color'],
        out_dir,
        paste0(dataset, '_', sd, '_stddev_ancestry_assignments')
    )
}

# Write dataset ancestry assignment summary for different std devs
write.table(
    summary,
    file=paste0(out_dir, dataset, '_ancestry_assignments_summary.tsv'),
    quote=FALSE,
    sep="\t",
    row.names=F
)

# Generate plots of ancestry outliers using different stddev thresholds
for (ancestry in ancestries) {
    plot_data = dataset_samples[dataset_samples$ANCESTRY == ancestry,]
    plot_data$color = "green"
    plot_data[plot_data$SCALED_MAHAL > 2,'color'] = "yellow"
    plot_data[plot_data$SCALED_MAHAL > 3,'color'] = "orange"
    plot_data[plot_data$SCALED_MAHAL > 4,'color'] = "red"
    generate_pc_plot(
        plot_data,
        'PC1',
        'PC2',
        'PC3',
        pc1_lim,
        pc2_lim,
        pc3_lim,
        c("StdDev <2","StdDev 2-3","StdDev 3-4","StdDev >4"),
        c("green","yellow","orange","red"),
        out_dir,
        paste0(dataset, '_', tolower(ancestry), '_outliers')
    )
}
