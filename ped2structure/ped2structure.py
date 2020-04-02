#!/usr/bin/env python3

import argparse
import sys
import os
import logging

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


def get_argparser():

    def file_type(arg_string):
        if not os.path.exists(arg_string):
            err_msg = "%s does not exist! " \
                      "Please provide a valid file!" % arg_string
            raise argparse.ArgumentTypeError(err_msg)
        return arg_string


    # Configure and return argparser object for reading command line arguments
    argparser_obj = argparse.ArgumentParser(prog="ped2structure")

    # Ped file to import
    argparser_obj.add_argument("--ped",
                               action="store",
                               type=file_type,
                               dest="ped_file",
                               required=True,
                               help="Path to ped file")

    # Output file
    argparser_obj.add_argument("--output",
                               action="store",
                               type=str,
                               dest="out_file",
                               required=True,
                               help="Path to output file")


    # Pop files to specify samples belonging to each pop
    argparser_obj.add_argument("--pop-files",
                               action="store",
                               type=file_type,
                               dest="pop_files",
                               nargs="*",
                               required=False,
                               default=[],
                               help="Paths to files containing sample ids from each pop to be included in structure run")

    # Verbosity level
    argparser_obj.add_argument("-v",
                               action='count',
                               dest='verbosity_level',
                               required=False,
                               default=0,
                               help="Increase verbosity of the program."
                                    "Multiple -v's increase the verbosity level:\n"
                                    "0 = Errors\n"
                                    "1 = Errors + Warnings\n"
                                    "2 = Errors + Warnings + Info\n"
                                    "3 = Errors + Warnings + Info + Debug")

    return argparser_obj


# Map specifying how STRUCTURE alleles should be encoded
geno_map = {"A": 1, "T": 4, "G": 3, "C": 2, "0": -9}


def main():

    # Configure argparser
    argparser = get_argparser()

    # Parse the arguments
    args = argparser.parse_args()

    # Configure logging appropriate for verbosity
    verbosity = min(args.verbosity_level, 3)
    configure_logging(verbosity)

    ped_file = args.ped_file
    pop_files = args.pop_files
    out_file = args.out_file

    if pop_files:
        logging.info("Detected {0} pop files...".format(len(pop_files)))
    else:
        logging.info("No pop files detected! Structure will not use any pop information!")
    pop_ids = {}

    pop_count = 1
    # Initialize hash table of populations
    for i, pop_file in enumerate(pop_files):
        pop_samples = 0
        with open(pop_file, "r") as fh:
            for line in fh:
                # Make sure no duplicate samples being added
                sample_id = "_".join(line.strip().split()[0:2])
                if sample_id in pop_ids:
                    err_msg = "Duplicate sample id: {0}".format(sample_id)
                    logging.error(err_msg)
                    raise IOError(err_msg)
                pop_ids[sample_id] = pop_count
                pop_samples += 1

        # Increment pop count
        pop_count += 1

        logging.info("Counted {0} individuals from pop file {1}...".format(pop_samples, pop_file))

    if pop_files:
        logging.info("Count {0} samples across all input pops...".format(len(pop_ids)))

    # Create filehandle for writing
    out_fh = open(out_file, "w")

    # Convert ped file to structure file with ped encodings
    samples_out = 0
    samples_mapped = 0
    logging.info("Converting ped file: {0} >> {1}".format(ped_file, out_file))
    with open(ped_file, "r") as fh:
        for line in fh:

            # Outpupt progress
            if samples_out % 500 == 0:
                logging.info("Written {0} samples...".format(samples_out))

            split_line = line.split()

            # Get sample id
            sample_id = "{0}_{1}".format(split_line[0], split_line[1])

            # Determine whether sample is in one of the input population files
            pop_id = pop_ids[sample_id] if sample_id in pop_ids else 0

            # If pop was found, mark that the pop should be used by STRUCTURE
            pop_flag = "1" if sample_id in pop_ids else "0"

            # Initialize new lines for appending recoded genotypes
            line_1 = "{0} {1} {2}".format(sample_id, pop_id, pop_flag)
            line_2 = line_1

            # Convert plus/minus strand genotypes to structure format
            for i in range(6, len(split_line), 2):
                line_1 += " {0}".format(geno_map[split_line[i]])
                line_2 += " {0}".format(geno_map[split_line[i+1]])

            # Check to make sure lines are correct length and error out if not
            if len(line_1.split())-3 != (len(split_line) - 6)/2:
                print(len(line_1.split())-3)
                print(len(split_line)-6)
                logging.error("Line 1 is wrong length!")
                raise RuntimeError("Line 1 is wrong length for sample {0}. Not sure what happened but output is invalid".format(sample_id))

            if len(line_2.split())-3 != (len(split_line) - 6)/2:
                print(len(line_2.split()) - 3)
                print(len(split_line) - 6)
                logging.error("Line 2 is wrong length!")
                raise RuntimeError("Line 2 is wrong length for sample {0}. Not sure what happened but output is invalid".format(sample_id))

            # Write to output file
            # Need to add newlines to the beginning so that final line doesn't have a newline
            # Means you just need to skip adding leading newline to first sample
            if samples_out:
                out_fh.write("\n{0}\n{1}".format(line_1, line_2))
            else:
                # Don't include leading newline for first sample
                out_fh.write("{0}\n{1}".format(line_1, line_2))

            # Increment counters
            if sample_id in pop_ids:
                samples_mapped += 1

            samples_out += 1

    logging.info("Wrote {0} samples to STRUCTURE input file".format(samples_out))
    logging.info("{0} samples were mapped to an input population to be used by STRUCTURE".format(samples_mapped))
    out_fh.close()


if __name__ == "__main__":
    sys.exit(main())
