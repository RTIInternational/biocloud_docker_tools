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

from argparse import Namespace
args = Namespace(
    file_in_summary_stats = "/shared/rti-midas-data/studies/wihs/imputed/v9/association_tests/0001/ea/wihs1.ea.chr1.vllog10mean~variant+basesex+site+wihscode+evs.MetaScore.assoc.gz",
    file_in_summary_stats_format = "rvtests",
    file_in_info = "/shared/rti-midas-data/studies/wihs/imputed/v9/imputations/aa/output_files/chr1.info.gz",
    file_in_pop_mafs = "/shared/rti-common/ref_panels/mis/1000g/phase3/2.0.0/pop_mafs/afr/chr1.tsv.gz",
    population = "afr",
    file_out_prefix = "/shared/temp/sum_stats_test"
)

# Open log file
fileLog = args.file_out_prefix + ".log"
log = open(fileLog, 'w')
log.write("Script: make_gwas_summary_stats.py\n")
log.write("Arguments:\n")
# Write arguments to log file
pp = pprint.PrettyPrinter(indent = 4)
log.write(pp.pprint(vars(args)))
log.write("\n\n")

# Read population MAFS
popMAFs = pd.read_table(
    args.file_in_pop_mafs,
    compression='gzip'
)
# Rename columns
popMAFs.columns = ["VARIANT_ID", "POP_MAF"]
log.write("Read \n" + popMAFs.shape[0] + " lines from " + args.file_in_pop_mafs)

# Read MAF, Rsq (IMP_QUAL), and Genotyped (SOURCE) from info file
info = pd.read_table(
    args.file_in_info,
    compression='gzip',
    usecols = ["SNP" , "MAF", "Rsq", "Genotyped"],
    dtype = {"MAF" : "float64", "Rsq": "float64", "Genotyped": "category"},
    na_values = {"-"}
)
# Rename columns
colXref = {
    'SNP': 'VARIANT_ID',
    'MAF': 'MAF',
    'Rsq': 'IMP_QUAL',
    'Genotyped': 'SOURCE'
}
info.columns = info.columns.map(colXref)
# Recode sources
sourceXref = {
    'Imputed': 'imp',
    'Genotyped': 'obs',
    'Typed_Only': 'obs'
}
info['SOURCE'] = info['SOURCE'].map(sourceXref)
log.write("Read \n" + info.shape[0] + " lines from " + args.file_in_info)

# Read summary stats file
if args.file_in_summary_stats_format == "rvtests":
    sumStats = pd.read_table(
        args.file_in_summary_stats,
        compression='gzip',
        usecols = ["CHROM", "POS", "REF", "ALT", "N_INFORMATIVE", "AF", "SQRT_V_STAT", "ALT_EFFSIZE", "PVALUE"],
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
        'AF': 'ALT_AF',
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
    log.write("Read \n" + sumStats.shape[0] + " lines from " + args.file_in_summary_stats)
elif args.file_in_summary_stats_format == "genesis":
    sumStats = pd.read_table(
        args.file_in_summary_stats,
        compression='gzip',
        usecols = ["variant.id" , "chr", "pos", "freq", "n.obs", "Est", "Est.SE", "Score.pval"]
    )

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
    sep = '\t'
)
log.write("Wrote \n" + sumStats.shape[0] + " lines to " + args.file_out_prefix + ".tsv.gz")

