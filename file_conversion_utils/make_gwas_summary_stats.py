import argparse
import pandas as pd
import pprint

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--file_in_summary_stats",
    help="summary stats file to be converted"
)
parser.add_argument(
    "--file_in_summary_stats_format",
    help="format of the summary stats file to be converted",
    type = str.lower,
    choices=["rvtests", "genesis"]
)
parser.add_argument(
    "--file_in_info",
    help="info file from genotype imputation"
)
parser.add_argument(
    "--file_in_pop_mafs",
    help="file containing mafs for relevant 1000G population"
)
parser.add_argument(
    "--population",
    help="1000G population",
    type = str.lower,
    choices=["afr", "eas", "eur", "amr", "eas", "amr"]
)
parser.add_argument(
    "--file_out_prefix",
    help="prefix for output files"
)
args = parser.parse_args()

# Open log file
fileLog = args.file_out_prefix + ".log"
log = open(fileLog, 'w')
log.write("Script: make_gwas_summary_stats.py\n")
log.write("Arguments:\n")
# Write arguments to log file
pp = pprint.PrettyPrinter(indent = 4)
log.write(pp.pformat(vars(args)))
log.write("\n\n")
log.flush()

# Read population MAFS
popMAFs = pd.read_table(
    args.file_in_pop_mafs,
    compression='gzip'
)
# Rename columns
popMAFs.columns = ["VARIANT_ID", "POP_MAF"]
log.write("Read " + str(popMAFs.shape[0]) + " lines from " + args.file_in_pop_mafs + "\n")
popMAFs.drop_duplicates(subset = "VARIANT_ID", keep = "first", inplace = True)
log.write(str(popMAFs.shape[0]) + " remain after duplicate removal\n")
log.flush()

# Read MAF, Rsq (IMP_QUAL), and Genotyped (SOURCE) from info file
info = pd.read_table(
    args.file_in_info,
    compression='gzip',
    usecols = ["SNP" , "ALT_Frq", "MAF", "Rsq", "Genotyped"],
    dtype = {"Genotyped": "category"},
    na_values = {"-"}
)
# Rename columns
colXref = {
    'SNP': 'VARIANT_ID',
    'ALT_Frq': 'ALT_AF',
    'MAF': 'MAF',
    'Rsq': 'IMP_QUAL',
    'Genotyped': 'SOURCE'
}
info.columns = info.columns.map(colXref)
# Recode sources
sourceXref = {
    'Imputed': 'IMP',
    'Genotyped': 'GEN',
    'Typed_Only': 'GEN'
}
info['SOURCE'] = info['SOURCE'].map(sourceXref)
log.write("Read " + str(info.shape[0]) + " lines from " + args.file_in_info + "\n")
info.drop_duplicates(subset = "VARIANT_ID", keep = "first", inplace = True)
log.write(str(info.shape[0]) + " remain after duplicate removal\n")
log.flush()

# Read summary stats file
if args.file_in_summary_stats_format == "rvtests":
    sumStats = pd.read_table(
        args.file_in_summary_stats,
        compression='gzip',
        usecols = ["CHROM", "POS", "REF", "ALT", "N_INFORMATIVE", "SQRT_V_STAT", "ALT_EFFSIZE", "PVALUE"],
        dtype = {"CHROM": "category", "REF": "category", "ALT": "category"},
        comment = "#"
    )
    # Rename columns
    colXref = {
        'CHROM': 'CHR',
        'POS': 'POS',
        'REF': 'REF',
        'ALT': 'ALT',
        'N_INFORMATIVE': 'N',
        'SQRT_V_STAT': 'SQRT_V_STAT',
        'ALT_EFFSIZE': 'ALT_EFFECT',
        'PVALUE': 'P',
    }
    sumStats.columns = sumStats.columns.map(colXref)
    # Create VARIANT_ID field
    sumStats['VARIANT_ID'] = sumStats['CHR'].astype(str) + ':' + sumStats['POS'].astype(str) + ':' + \
        sumStats['REF'].astype(str) + ':' + sumStats['ALT'].astype(str)
    # Add SE
    sumStats['SE'] = 1 / sumStats['SQRT_V_STAT']
    log.write("Read " + str(sumStats.shape[0]) + " lines from " + args.file_in_summary_stats + "\n")
    log.flush()
elif args.file_in_summary_stats_format == "genesis":
    sumStats = pd.read_table(
        args.file_in_summary_stats,
        compression='gzip',
        usecols = ["variant.id" , "chr", "pos", "freq", "n.obs", "Est", "Est.SE", "Score.pval"]
    )
sumStats.drop_duplicates(subset = "VARIANT_ID", keep = "first", inplace = True)
log.write(str(sumStats.shape[0]) + " remain after duplicate removal\n")

# Merge population MAFs into summary stats
sumStats = pd.merge(
    left = sumStats,
    right = popMAFs,
    how = 'left',
    left_on = 'VARIANT_ID',
    right_on = 'VARIANT_ID'
)

# Merge MAF, IMP_QUAL, and SOURCE into summary stats
sumStats = pd.merge(
    left = sumStats,
    right = info,
    how = 'left',
    left_on = 'VARIANT_ID',
    right_on = 'VARIANT_ID'
)

# Write summary stats file
columnsToWrite = [
    "VARIANT_ID",
    "CHR",
    "POS",
    "REF",
    "ALT",
    "ALT_AF",
    "MAF",
    "POP_MAF",
    "SOURCE",
    "IMP_QUAL",
    "N",
    "ALT_EFFECT",
    "SE",
    "P"
]
sumStats.to_csv(
    args.file_out_prefix + ".tsv.gz",
    columns = columnsToWrite,
    index = False,
    compression='gzip',
    sep = '\t',
    na_rep = 'NA'
)
log.write("Wrote " + str(sumStats.shape[0]) + " lines to " + args.file_out_prefix + ".tsv.gz" + "\n")
log.flush()

