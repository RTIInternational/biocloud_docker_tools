#!/usr/bin/env python3

import pandas as pd
import json
import logging
import string
from collections import OrderedDict
import sys

from utils import configure_logging, get_argparser

def valid_colnames(df, required_colnames, err_msg):
    errors = True
    for colname in required_colnames:
        if colname not in list(df.columns.values):
            logging.error("{0}! Colname doesn't exist: {1}".format(err_msg, colname))
            errors = False
    return errors


def main():

    # Configure argparser
    argparser = get_argparser()

    # Parse the arguments
    args = argparser.parse_args()

    # Input files: sumstat file with rsids and snp info file that contains snp info for rsid
    input_sumstats = args.sumstats_input
    snp_info_file = args.snp_info_file

    # Output file
    output_file = args.output_file

    # Column names for lookup
    sumstat_rsid_colname = args.sumstat_rsid_colname
    snp_info_rsid_colname = args.snp_info_rsid_colname
    snp_info_chr_col = args.snp_info_chr_colname
    snp_info_pos_col = args.snp_info_pos_colname

    # Configure logging appropriate for verbosity
    configure_logging(3)

    # Read in json file and check format
    logging.info("Reading snp info file: {0}".format(snp_info_file))
    snp_info = pd.read_csv(snp_info_file, sep="\t", dtype=object)

    # Check to make sure column names are present in snp info file
    if not valid_colnames(snp_info,
                          [snp_info_rsid_colname, snp_info_pos_col, snp_info_chr_col],
                          err_msg="Unable to find required colname in snp info file!"):
        raise IOError("Unable to find colnames in snp info file!")

    logging.info("Reading sumstats file: {0}".format(input_sumstats))
    sumstats_info = pd.read_csv(input_sumstats, sep="\t", dtype=object)

    # Check to make sure column names are present in sumstats file
    if not valid_colnames(sumstats_info,
                          [sumstat_rsid_colname],
                          err_msg="Unable to find required colname in sumstats file!"):
        raise IOError("Unable to find colnames in sumstats file!")

    # Subset snp info columns
    snp_info = snp_info[[snp_info_rsid_colname, snp_info_chr_col, snp_info_pos_col]]

    logging.info("Merging snp information...")
    final_df = sumstats_info.merge(snp_info, how="inner", left_on=sumstat_rsid_colname, right_on=snp_info_rsid_colname)

    # Drop duplicate rsid column
    final_df.drop(labels=snp_info_rsid_colname, axis=1, inplace=True)

    # Remove 'chr' from beginning of chromsomes
    logging.info("Fixing chr numbering...")
    final_df[snp_info_chr_col] = final_df[snp_info_chr_col].map(lambda x: x.lstrip("chr"))

    logging.info("Writing to output file: {0}".format(output_file))
    final_df.to_csv(output_file, sep="\t", index=False, )


if __name__ == "__main__":
    sys.exit(main())
