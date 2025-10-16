import argparse
import pandas as pd
import os

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--metal_prefix",
    help="Prefix of metal output files",
    type = str
)
parser.add_argument(
    "--metal_suffix",
    help="Suffix of metal output files",
    type = str
)
args = parser.parse_args()

metal_results = "{}1{}".format(args.metal_prefix, args.metal_suffix)
processed_metal_results = "{}.{}".format(args.metal_prefix, args.metal_suffix)
metal_info = "{}.info".format(metal_results)
processed_metal_info = "{}.info".format(args.metal_prefix)

# Rename metal info file
print("Renaming {} to {}".format(metal_info, processed_metal_info))
os.system("mv {} {}".format(metal_info, processed_metal_info))

# Read metal results file
print("Processing metal results file {} to {}".format(metal_results, processed_metal_results))
results = pd.read_csv(
    "/shared/ngaddis/data/temp/metal/metal1tsv",
    sep="\t"
)

# Reorder columns to put variant ID first
cols = list(results)
cols.insert(0, cols.pop(cols.index('MarkerName')))
results = results[cols]

# Rename p-value column
results = results.rename(columns={'P-value': 'P'})

# Capitalize alleles
results['Allele1'] = results['Allele1'].str.upper()
results['Allele2'] = results['Allele2'].str.upper()

# Sort by p-value
results = results.sort_values(by=['P'])

# Write processed results file
results.to_csv(
    processed_metal_results,
    sep="\t",
    index=False
)
