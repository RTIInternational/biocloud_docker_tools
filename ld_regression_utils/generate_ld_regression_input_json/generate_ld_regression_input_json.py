#!/usr/bin/env python3

import pandas as pd
import json
import logging
import string
from collections import OrderedDict
import sys

from utils import configure_logging, get_argparser

# Columns that must appear in input file
REQUIRED_COLS = ["trait", "plot_label", "sumstats_path", "category",
                 "sample_size", "id_col", "chr_col", "pos_col", "effect_allele_col", "ref_allele_col",
                 "effect_col", "pvalue_col", "sample_size_col", "effect_type", "w_ld_chr"]

# Columns that cannot have empty values
REQUIRED_VAL_COLS = ["trait", "plot_label", "sumstats_path", "category",
                     "id_col", "chr_col", "pos_col", "effect_allele_col", "ref_allele_col",
                     "effect_col", "pvalue_col", "effect_type", "w_ld_chr"]

# Columns that should be output as ints
INT_TYPE_COLS = ["id_col", "chr_col", "pos_col", "effect_allele_col",
                 "ref_allele_col", "pvalue_col", "sample_size",
                 "effect_col", "sample_size_col"]

# Null effect values for different effect types
NULL_EFFECT_VALS = {"beta"  : 0,
                    "z"     : 0,
                    "or"    : 1,
                    "log_odd" : 0}

# Maps colnames in input excel file to field names in WDL input json
OUTPUT_COLNAME_MAP = {
    "trait_name"        : "pheno_names",
    "plot_label"       : "pheno_plot_labels",
    "category"          : "pheno_plot_groups",
    "sumstats_path"     : "pheno_sumstats_files",
    "id_col"            : "pheno_id_cols",
    "chr_col"           : "pheno_chr_cols",
    "pos_col"           : "pheno_pos_cols",
    "effect_allele_col" : "pheno_effect_allele_cols",
    "ref_allele_col"    : "pheno_ref_allele_cols",
    "effect_col"        : "pheno_beta_cols",
    "pvalue_col"        : "pheno_pvalue_cols",
    "sample_size_col"   : "pheno_num_samples_cols",
    "signed_sumstats"   : "pheno_signed_sumstats",
    "sample_size"       : "pheno_num_samples",
    "w_ld_chr"          : "pheno_ld_chr_tarfiles"
}

def detect_workflow_name(input_dict):
    # Guess the workflow name that needs to be added to each workflow input
    # Workflow name should be what comes before period in each input
    # e.g.: ldsc_wf.sumstats_file the workflow name is ldsc_wf
    for key in input_dict:
        if not key.startswith("#"):
            return key.split(".")[0]

def check_pheno_input_format(pheno_df):

    # Check required input cols are present
    errors = False
    for col in REQUIRED_COLS:
        if col not in pheno_df.columns:
            logging.error("Phenotype excel missing required column: '{0}'".format(col))
            errors = True
    if errors:
        raise IOError("Phenotype excel missing one or more required columns! See logging above for details!")

    # Check whether all cols have no missing values
    for col in REQUIRED_VAL_COLS:
        if len(pheno_df[pheno_df[col].isnull()]) != 0:
            logging.error("One or more empty values in phenotype excel column '{0}'! All rows must have a value for this col!".format(col))
            errors = True
    if errors:
        raise IOError("Phenotype excel missing required values! See logging above for details")

    # Check that each pheno has either sample_size and sample_size_col
    for i in range(len(pheno_df)):
        if pheno_df["sample_size"].isnull()[i] and pheno_df["sample_size_col"].isnull()[i]:
            logging.error("Trait '{0}' has neither sample size or a sample size column. "
                          "One of these must be specified!".format(pheno_df["trait"][i]))
            errors = True

    if errors:
        raise IOError("Phenotype excel missing sample size info for one or more traits! See messages above.")

    # Check to make sure effect type is either BETA, Z, OR, or LOGOR
    for i in range(len(pheno_df)):
        effect = pheno_df["effect_type"][i].lower()
        if effect not in ["beta", "z", "or", "log_odd"]:
            logging.error("Trait '{0}' has invalid effect type '{1}'. "
                          "Effect type must be either in "
                          "[Beta, Z, OR, Log_Odd] (case-insensitive).".format(pheno_df["trait"][i], effect))
            errors = True

    if errors:
        raise IOError("Phenotype excel has invalid effect type info for one or more traits! See messages above.")

    # Make sure all column index columns have integer values > 0 (1-based index so 0 index needs to raise error)
    for col_type in INT_TYPE_COLS:
        if len(pheno_df[pheno_df[col_type] < 1]) > 0:
            logging.error("'{0}' column of phenotype excel has at least one 0 value. "
                          "Indices are 1-based!".format(col_type))
            errors = True

    if errors:
        raise IOError("One or more phenotype excel index columns (e.g. id_col, chr_col, pos_col) contains a zero. "
                      "\nThese are 1-based index columns! See messages above.")

def normalize_trait_name(trait_name):
    # Takes a trait name and converts it to something that could be used as a file handle
    # Remove punctuation
    trait_name = trait_name.translate(str.maketrans('','',string.punctuation))

    # Lower case
    trait_name = trait_name.lower()

    # Replace spaces with underscores
    return trait_name.replace(" ", "_")

def get_signed_sumstat(effect_type):
    # Get the string to pass to munge_stats.py based on the effect type
    # Assumes all columns will be labeled as "BETA" whether or not they are indeed a beta score
    # This gets taken care of as part of the pipeline to normalize the column names and for some reason I just picked this
    return "BETA,{0}".format(NULL_EFFECT_VALS[effect_type.lower()])

def mask_na(val):
    # Convert NA values to -1
    if pd.isnull(val):
        return -1
    return val

def make_final_output_dict(workflow_name, input_dict, pheno_df):
    for output_type in OUTPUT_COLNAME_MAP:
        # Get name of field as it will appear in the WDL json
        wdl_type = "{0}.{1}".format(workflow_name, OUTPUT_COLNAME_MAP[output_type])
        # Get values, converting to int if necessary
        vals = [int(x) for x in list(pheno_df[output_type])] if output_type in INT_TYPE_COLS else pheno_df[output_type]
        # Add to input dict
        input_dict[wdl_type] = list(vals)

    return input_dict

def main():

    # Configure argparser
    argparser = get_argparser()

    # Parse the arguments
    args = argparser.parse_args()

    # Input files: json input file to be used as template and
    input_json = args.json_input
    input_excel = args.pheno_file

    # Configure logging appropriate for verbosity
    configure_logging(args.verbosity_level)

    # Read in json file and check format
    logging.info("Reading WDL input template: {0}".format(input_json))
    with open(input_json) as fh:
        input_dict = json.load(fh, object_pairs_hook=OrderedDict)

    # Guess name of workflow from input names
    workflow_name = detect_workflow_name(input_dict)
    logging.info("Workflow name detected: {0}".format(workflow_name))

    # Read in excel file and check format
    logging.info("Reading phenotype information from excel file: {0}".format(input_excel))
    pheno_df = pd.read_excel(input_excel)

    logging.info("Validating structure of excel file...")
    check_pheno_input_format(pheno_df)

    # Normalize trait names so they are machine readable
    pheno_df["trait_name"] = pheno_df["plot_label"].apply(normalize_trait_name)

    # Get signed sumstat string that will be passed to munge_sumstats.py
    pheno_df["signed_sumstats"] = pheno_df["effect_type"].apply(get_signed_sumstat)

    # Replace NA sample size values with -1
    pheno_df["sample_size"] = pheno_df["sample_size"].apply(mask_na)

    # Replace NA sample size col values with -1
    pheno_df["sample_size_col"] = pheno_df["sample_size_col"].apply(mask_na)

    # Add new data fields to existing WDL input file
    output_dict = make_final_output_dict(workflow_name, input_dict, pheno_df)

    # Output WDL to stdout
    print(json.dumps(output_dict, indent=1))


if __name__ == "__main__":
    sys.exit(main())

