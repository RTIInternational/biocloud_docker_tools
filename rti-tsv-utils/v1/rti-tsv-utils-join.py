import argparse
import pandas as pd
import pprint as pp
import sys

def getColListFromArgument(argValue, file, sep):
    argList = []
    if (argValue == "" or argValue == "all"):
        argList = list(pd.read_csv(file, sep=sep, nrows=1))
    else:
        argList = argValue.split(",")
    return argList

# Define arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--in-file-left",
    dest = "left",
    type = str,
    help = "Left-hand file for merge"
)
parser.add_argument(
    "--in-file-left-sep",
    dest = "left_sep",
    default = "whitespace",
    type = str.lower,
    choices = ["whitespace", "tab", "space", "comma"],
    help = "Left-hand file field separator"
)
parser.add_argument(
    "--in-file-left-cols",
    dest = "left_cols",
    type = str,
    default = "all",
    help = "Comma-separated names of columns in left-hand file to include in output"
)
parser.add_argument(
    "--left-on",
    dest = "left_on",
    type = str,
    help = "Field in left file to join on"
)
parser.add_argument(
    "--left-suffix",
    dest = "left_suffix",
    type = str,
    default = "",
    help = "Suffix to add to columns in left file in joined file"
)
parser.add_argument(
    "--in-file-right",
    dest = "right",
    nargs = "+",
    type = str,
    help = "Right-hand file(s) for merge."
)
parser.add_argument(
    "--in-file-right-sep",
    dest = "right_sep",
    nargs = "+",
    type = str.lower,
    default = ["whitespace"],
    help = "Right-hand file field separator(s); Choices: whitespace, tab, space, comma"
)
parser.add_argument(
    "--in-file-right-cols",
    dest = "right_cols",
    nargs = "+",
    type = str,
    default = ["all"],
    help = "Column-separated names of columns in right-hand file(s) to include in output"
)
parser.add_argument(
    "--right-on",
    dest = "right_on",
    nargs = "+",
    type = str,
    help = "Field in right file(s) to join on"
)
parser.add_argument(
    "--right-suffix",
    dest = "right_suffix",
    nargs = "+",
    type = str,
    default = [""],
    help = "Suffix to add to columns in right file in joined file"
)
parser.add_argument(
    "--how",
    dest = "how",
    nargs = "+",
    type = str.lower,
    default = ["inner"],
    help = "Type of joins for each right-hand file; Choices: left, inner"
)
parser.add_argument(
    "--out-file-prefix",
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
    dest = "chunk_size",
    type = int,
    default = 200000,
    help = "Size of chunks to use for reading files"
)

# Retrieve arguments
args = parser.parse_args()

# Get count of right files
rightCount = len(args.right)

# Set separators
sepRegex = {
    "whitespace": r'\s+',
    "tab": r'\t',
    "space": ' ',
    "comma": ','
}
args.left_sep = sepRegex[args.left_sep]
rightSepRegex = []
for rightSep in args.right_sep:
    rightSepRegex.append(sepRegex[rightSep])
args.right_sep = rightSepRegex

# Check whether arguments are logical
rightArguments = ["right_cols", "right_on", "right_sep", "how", "right_suffix"]
for rightArgument in rightArguments:
    rightArgumentValue = getattr(args, rightArgument)
    rightArgumentCount = len(rightArgumentValue)
    if rightArgumentCount != rightCount:
        if rightArgumentCount == 1:
            setattr(args, rightArgument, [rightArgumentValue[0]] * rightCount)
        else:
            sys.exit("Number of arguments provided for " + rightArgument + " do not match number of right files")

# Convert comma-separated arguments to lists
commaSepArguments = ["left_cols"]
for commaSepArgument in commaSepArguments:
    setattr(args, commaSepArgument, getColListFromArgument(getattr(args, commaSepArgument), args.left, args.left_sep))

commaSepArguments = ["right_cols"]
for commaSepArgument in commaSepArguments:
    argLists = []
    for rightIndex in range(rightCount):
        arg = getattr(args, commaSepArgument)[rightIndex]
        argLists.append(getColListFromArgument(arg, args.right[rightIndex], args.right_sep[rightIndex]))
    setattr(args, commaSepArgument, argLists)

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

# Create list of columns to output
outCols = [leftCol + args.left_suffix for leftCol in args.left_cols]
for rightIndex in range(rightCount):
    outCols = outCols + [rightCol + args.right_suffix[rightIndex] for rightCol in args.right_cols[rightIndex]]
    rightOn = args.right_on[rightIndex] + args.right_suffix[rightIndex]
    outCols.remove(rightOn)

# Read left file, adding columns from right files
chunkCount = 1
for left in pd.read_table(
    args.left,
    sep = args.left_sep,
    usecols = args.left_cols,
    chunksize = args.chunk_size
):
    logHandle.write("Processing chunk " + str(chunkCount) + " of " + args.left + "\n")
    logHandle.flush()

    # Create dataframe for output
    out = left.copy()

    # Remove duplicates
    out.drop_duplicates(subset=[args.left_on], inplace = True)

    # Get count of rows in out dataframe
    outCount = out.shape[0]

    # Add suffixes to column names
    out = out.add_suffix(args.left_suffix)
    leftOn = args.left_on + args.left_suffix

    # Loop through right files
    firstMerge = True
    for rightIndex in range(rightCount):
        logHandle.write("Reading " + args.right[rightIndex] + "\n")
        logHandle.flush()

        # Create dataframe for right file rows to save
        dfRight = pd.DataFrame(columns=args.right_cols[rightIndex])

        # Create iterator for right file
        for right in pd.read_table(
            args.right[rightIndex],
            sep = args.right_sep[rightIndex],
            usecols = args.right_cols[rightIndex],
            chunksize = args.chunk_size
        ):
            # Capture rows from right file whose keys are present in the left file
            dfRight = dfRight.append(right[right[args.right_on[rightIndex]].isin(out[leftOn])])

            # Remove duplicates
            dfRight.drop_duplicates(subset=[args.right_on[rightIndex]], inplace = True)

            # Check if all keys in out accounted for
            dfRightCount = dfRight.shape[0]

        # Add suffixes to column names
        dfRight = dfRight.add_suffix(args.right_suffix[rightIndex])
        rightOn = args.right_on[rightIndex] + args.right_suffix[rightIndex]

        # Merge out and dfRight dataframes
        logHandle.write("Merging " + args.right[rightIndex] + "\n")
        logHandle.flush()
        out = out.merge(
            dfRight,
            how = args.how[rightIndex],
            left_on = leftOn,
            right_on = rightOn,
            sort = args.sort
        )

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
