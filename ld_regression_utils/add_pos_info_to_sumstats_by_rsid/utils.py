import sys
import logging
import argparse
import os

def get_argparser():
    # Configure and return argparser object for reading command line arguments
    argparser_obj = argparse.ArgumentParser(prog="add_pos_info_to_sumstats_by_rsid")

    def file_type(arg_string):
        """
        This function check both the existance of input file and the file size
        :param arg_string: file name as string
        :return: file name as string
        """
        if not os.path.exists(arg_string):
            err_msg = "%s does not exist! " \
                      "Please provide a valid file!" % arg_string
            raise argparse.ArgumentTypeError(err_msg)

        return arg_string

    # Path to VCF input file
    argparser_obj.add_argument("--sumstats-file",
                               action="store",
                               type=file_type,
                               dest="sumstats_input",
                               required=True,
                               help="Path to base GWAS sumstats file that has rsid column but no allele info")

    # Path to VCF input file
    argparser_obj.add_argument("--snp-info-file",
                               action="store",
                               type=file_type,
                               dest="snp_info_file",
                               required=True,
                               help="Path to snplist file containing allele info for each rsid")

    # Path to VCF input file
    argparser_obj.add_argument("--out",
                               action="store",
                               type=str,
                               dest="output_file",
                               required=True,
                               help="Path to output file")

    argparser_obj.add_argument("--sumstat-rsid-colname",
                               action="store",
                               type=str,
                               dest="sumstat_rsid_colname",
                               required=False,
                               default="MarkerName",
                               help="Name of rsid column in sumstat file")

    argparser_obj.add_argument("--snp-info-rsid-colname",
                               action="store",
                               type=str,
                               dest="snp_info_rsid_colname",
                               required=False,
                               default="name",
                               help="Name of rsid column in snp info file file")

    argparser_obj.add_argument("--snp-info-chr-colname",
                               action="store",
                               type=str,
                               dest="snp_info_chr_colname",
                               required=False,
                               default="#chrom",
                               help="Name of chr column in snp info file file")

    argparser_obj.add_argument("--snp-info-pos-colname",
                               action="store",
                               type=str,
                               dest="snp_info_pos_colname",
                               required=False,
                               default="chromEnd",
                               help="Name of pos column in snp info file file")

    return argparser_obj

def configure_logging(verbosity):
    # Setting the format of the logs
    FORMAT = "[%(asctime)s] %(levelname)s: %(message)s"

    # Configuring the logging system to the lowest level
    logging.basicConfig(level=logging.DEBUG, format=FORMAT, stream=sys.stderr)

    # Defining the ANSI Escape characters
    BOLD = '\033[1m'
    DEBUG = '\033[92m'
    INFO = '\033[94m'
    WARNING = '\033[93m'
    ERROR = '\033[91m'
    END = '\033[0m'

    # Coloring the log levels
    if sys.stderr.isatty():
        logging.addLevelName(logging.ERROR, "%s%s%s%s%s" % (BOLD, ERROR, "ERROR", END, END))
        logging.addLevelName(logging.WARNING, "%s%s%s%s%s" % (BOLD, WARNING, "WARNING", END, END))
        logging.addLevelName(logging.INFO, "%s%s%s%s%s" % (BOLD, INFO, "INFO", END, END))
        logging.addLevelName(logging.DEBUG, "%s%s%s%s%s" % (BOLD, DEBUG, "DEBUG", END, END))
    else:
        logging.addLevelName(logging.ERROR, "ERROR")
        logging.addLevelName(logging.WARNING, "WARNING")
        logging.addLevelName(logging.INFO, "INFO")
        logging.addLevelName(logging.DEBUG, "DEBUG")

    # Setting the level of the logs
    level = [logging.ERROR, logging.WARNING, logging.INFO, logging.DEBUG][verbosity]
    logging.getLogger().setLevel(level)