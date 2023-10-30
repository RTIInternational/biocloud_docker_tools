import argparse

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--bed',
    help='PLINK bed file to split',
    type = str
)
parser.add_argument(
    '--bim',
    help='PLINK bim file to split',
    type = str
)
parser.add_argument(
    '--fam',
    help='PLINK fam file to split',
    type = str
)
parser.add_argument(
    '--out',
    help='Basename of output files',
    type = str
)
args = parser.parse_args()

for chr in range(23):
    plink_args = [
        "plink",
        "--bed",
        args.bed,
        "--bim",
        args.bim,
        "--fam",
        args.fam,
        "--out",
        args.out + "_chr" + str(chr),
        "make-bed",
        "chr",
        chr,
        "--snps-only just-acgt"
    ]
    
    