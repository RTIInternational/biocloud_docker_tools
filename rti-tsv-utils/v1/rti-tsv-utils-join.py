import argparse
import pandas as pd
import pprint as pp
import sys

def getColumns(file, sep, keepCols=None, removeCols=None):
    allCols = list(pd.read_csv(file, sep=sep, nrows=1))
    cols = []
    if (keepCols is None):
        cols = allCols.copy()
    else:
        for col in keepCols.split(","):
            if col in allCols:
                cols.append(col)
            else:
                sys.exit("Column " + col + " not found in " + file)
    if (removeCols is not None):
        for col in removeCols.split(","):
            if col in cols:
                cols.remove(col)
            else:
                sys.exit("Column " + col + " not found in " + file)
    return cols

# Define arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--left-file",
    required = True,
    dest = "left_file",
    type = str,
    help = "Left-hand file for merge"
)
parser.add_argument(
    "--left-on",
    required = True,
    dest = "left_on",
    type = str,
    help = "Field in left file to join on"
)
parser.add_argument(
    "--left-sep",
    required = False,
    dest = "left_sep",
    default = "whitespace",
    type = str.lower,
    choices = ["whitespace", "tab", "space", "comma"],
    help = "Left-hand file field separator"
)
parser.add_argument(
    "--left-keep-cols",
    required = False,
    dest = "left_keep_cols",
    type = str,
    default = None,
    help = "Comma-separated names of columns in left-hand file to include in output"
)
parser.add_argument(
    "--left-remove-cols",
    required = False,
    dest = "left_remove_cols",
    type = str,
    default = None,
    help = "Comma-separated names of columns in left-hand file to remove from output"
)
parser.add_argument(
    "--left-suffix",
    required = False,
    dest = "left_suffix",
    type = str,
    default = "",
    help = "Suffix to add to columns in left file in joined file"
)
parser.add_argument(
    "--right-files",
    required = True,
    dest = "right_files",
    nargs = "+",
    type = str,
    help = "Right-hand file(s) for merge."
)
parser.add_argument(
    "--right-ons",
    required = True,
    dest = "right_ons",
    nargs = "+",
    type = str,
    help = "Field in right file(s) to join on"
)
parser.add_argument(
    "--right-suffixes",
    required = True,
    dest = "right_suffixes",
    nargs = "+",
    type = str,
    help = "Suffix to add to columns in right file in joined file"
)
parser.add_argument(
    "--right-seps",
    required = False,
    dest = "right_seps",
    nargs = "+",
    type = str.lower,
    default = ["whitespace"],
    help = "Right-hand file field separator(s); Choices: whitespace, tab, space, comma"
)
parser.add_argument(
    "--right-keep-cols",
    required = False,
    dest = "right_keep_cols",
    nargs = "+",
    type = str,
    default = [None],
    help = "Column-separated names of columns in right-hand file(s) to include in output"
)
parser.add_argument(
    "--right-remove-cols",
    required = False,
    dest = "right_remove_cols",
    nargs = "+",
    type = str,
    default = [None],
    help = "Column-separated names of columns in right-hand file(s) to remove from output"
)
parser.add_argument(
    "--hows",
    required = True,
    dest = "hows",
    nargs = "+",
    type = str.lower,
    help = "Type of joins for each right-hand file; Choices: left, inner"
)
parser.add_argument(
    "--out-prefix",
    required = True,
    dest = "out_prefix",
    type = str,
    help = "Prefix for output files"
)
sortGroup = parser.add_mutually_exclusive_group()
sortGroup.add_argument(
    "--sort",
    dest="sort",
    action="store_true",
    help = "Sort by join keys"
)
sortGroup.add_argument(
    "--no-sort",
    dest="sort",
    action="store_false",
    help = "Don't sort by join keys"
)
parser.set_defaults(sort=True)
parser.add_argument(
    "--chunk-size",
    required = False,
    dest = "chunk_size",
    type = int,
    default = 200000,
    help = "Size of chunks to use for reading files"
)

# Retrieve arguments
args = parser.parse_args()

# Get count of right files
rightCount = len(args.right_files)

# Set separators
sepRegex = {
    "whitespace": r'\s+',
    "tab": r'\t',
    "space": ' ',
    "comma": ','
}
args.left_sep = sepRegex[args.left_sep]
rightSepRegex = []
if len(args.right_seps) == 1 and rightCount > 1:
    for i in range(rightCount):
        rightSepRegex.append(sepRegex[args.right_seps[0]])
else:
    for rightSep in args.right_seps:
        rightSepRegex.append(sepRegex[rightSep])
args.right_seps = rightSepRegex

# Check whether arguments are logical
rightArguments = ["right_ons", "right_suffixes", "right_keep_cols", "right_remove_cols", "hows"]
for rightArgument in rightArguments:
    rightArgumentValue = getattr(args, rightArgument)
    rightArgumentCount = len(rightArgumentValue)
    if rightArgumentCount == 1 and rightCount > 1:
        setattr(args, rightArgument, [rightArgumentValue[0]] * rightCount)
    elif rightArgumentCount != rightCount:
        sys.exit(
            "Number of values for --" + rightArgument.replace("_", "-") +
            " (" + str(rightArgumentCount) + ") does not match number of right files (" + str(rightCount) + ")"
        )
    else:
        setattr(args, rightArgument, rightArgumentValue)

# Open log file
fileLog = args.out_prefix + ".log"
logHandle = open(fileLog, 'w')
logHandle.write("Script: rti-tsv-utils-join.py\n")
logHandle.write("Arguments:\n")

# Write arguments to log file
logText = pp.PrettyPrinter(indent = 4)
logHandle.write(logText.pformat(vars(args)))
logHandle.write("\n\n")
logHandle.flush()

# Get left columns to keep
leftCols = getColumns(
    args.left_file,
    args.left_sep,
    keepCols = args.left_keep_cols,
    removeCols = args.left_remove_cols
)

# Get right columns to keep
rightCols = []
for rightIndex in range(rightCount):
    rightCols.append(getColumns(
        args.right_files[rightIndex],
        args.right_seps[rightIndex],
        keepCols = args.right_keep_cols[rightIndex] if rightIndex < len(args.right_keep_cols) else None,
        removeCols = args.right_remove_cols[rightIndex] if rightIndex < len(args.right_remove_cols) else None
    ))

# Create list of output columns
outCols = leftCols.copy()
if args.left_suffix != "":
    outCols = [(outCol + '_' + args.left_suffix) for outCol in outCols]
for rightIndex in range(rightCount):
    outCols = outCols + [(rightCol + '_' + args.right_suffixes[rightIndex]) for rightCol in rightCols[rightIndex]]
    rightOn = args.right_ons[rightIndex] + '_' + args.right_suffixes[rightIndex]
    outCols.remove(rightOn)
    
# Read left file, adding columns from right files
chunkCount = 1
for left in pd.read_table(
    args.left_file,
    sep = args.left_sep,
    usecols = leftCols,
    chunksize = args.chunk_size
):
    logHandle.write("Processing chunk " + str(chunkCount) + " of " + args.left_file + "\n")
    logHandle.flush()

    # Create dataframe for output
    out = left.copy()

    # Remove duplicates
    out.drop_duplicates(subset=[args.left_on], inplace = True)

    # Add suffixes to column names
    out = out.add_suffix(args.left_suffix)
    leftOn = args.left_on + args.left_suffix

    # Loop through right files
    for rightIndex in range(rightCount):
        logHandle.write("Reading " + args.right_files[rightIndex] + "\n")
        logHandle.flush()

        # Create iterator for right file
        for right in pd.read_table(
            args.right_files[rightIndex],
            sep = args.right_seps[rightIndex],
            usecols = rightCols[rightIndex],
            chunksize = args.chunk_size
        ):
            nextRight = right[right[args.right_ons[rightIndex]].isin(out[leftOn])]
            nextRight = nextRight[rightCols[rightIndex]]
            
            # Capture rows from right file whose keys are present in the left file
            if 'dfRight' not in locals():
                dfRight = nextRight
            else:
                dfRight = pd.concat([dfRight, nextRight], ignore_index=True)

            # Remove duplicates
            dfRight.drop_duplicates(subset=[args.right_ons[rightIndex]], inplace = True)

            # Check if all keys in out accounted for
            if out[args.left_on].isin(dfRight[args.right_ons[rightIndex]]).all():
                break

        # Add suffixes to column names
        dfRight = dfRight.add_suffix('_' + args.right_suffixes[rightIndex])
        rightOn = args.right_ons[rightIndex] + '_' + args.right_suffixes[rightIndex]

        # Merge out and dfRight dataframes
        logHandle.write("Merging " + args.right_files[rightIndex] + "\n")
        logHandle.flush()
        out = out.merge(
            dfRight,
            how = args.hows[rightIndex],
            left_on= leftOn,
            right_on = rightOn,
            sort = args.sort
        )
        print(out.head())
        del dfRight

    logHandle.write("Writing chunk " + str(chunkCount) + "\n")
    logHandle.flush()
    if chunkCount == 1:
        mode = 'w'
        header = True
    else:
        mode = 'a'
        header = False
    out.to_csv(
        args.out_prefix + ".tsv.gz",
        columns = outCols,
        index = False,
        compression='gzip',
        sep = '\t',
        na_rep = 'NA',
        mode = mode,
        header = header,
        float_format='%g'
    )

    del out
    chunkCount += 1

logHandle.write("Join complete\n")
logHandle.close()
