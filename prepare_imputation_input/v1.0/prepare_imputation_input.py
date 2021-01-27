import argparse
import pandas as pd
import numpy as np
import os

## Example
#python3 /shared/bioinformatics/software/python/prepare_imputation_input.py \
#  --bfile ${base_dir}/$study/$study \
#  --ref /shared/rti-common/ref_panels/1000G/2014.10/legend_with_chr/dbsnp_b153_ids/1000GP_Phase3.legend.gz \
#  --ref_group $group \
#  --freq_diff_threshold 0.2 \
#  --out_prefix ${processing_dir}/${study}_imputation_ready \
#  --working_dir ${processing_dir} \
#  --plink /shared/bioinformatics/software/third_party/plink-1.90-beta-6.16-x86_64/plink \
#  --bgzip /shared/bioinformatics/software/third_party/htslib-1.6/bin/bgzip \
#  --bgzip_threads 4 \
#  --keep_plink True \
#  --cohort $study

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--bfile",
    help="Prefix of plink files to check (supercedes --bed, --bim, --fam)",
    type = str
)
parser.add_argument(
    "--bed",
    help="Bed file to check (superceded by --bfile)",
    type = str
)
parser.add_argument(
    "--bim",
    help="Bim file to check (superceded by --bfile)",
    type = str
)
parser.add_argument(
    "--fam",
    help="Fam file to check (superceded by --bfile)",
    type = str
)
parser.add_argument(
    "--ref",
    help="Ref panel legend file with chr col",
    type = str
)
parser.add_argument(
    "--ref_group",
    help="Ref panel group to use for freq comparison",
    type = str,
    choices = ["AFR", "AMR", "EAS", "EUR", "SAS", "ALL"],
    default = "ALL"
)
parser.add_argument(
    "--freq_diff_threshold",
    help="Maximum allowable freq difference between study and ref group",
    type = float
)
parser.add_argument(
    "--out_prefix",
    help="Output prefix",
    type = str
)
parser.add_argument(
    "--working_dir",
    help="Working directory",
    type = str
)
parser.add_argument(
    "--plink",
    help="Path to plink",
    type = str
)
parser.add_argument(
    "--bgzip",
    help="Path to bgzip",
    type = str
)
parser.add_argument(
    "--bgzip_threads",
    help="# of threads to use for bgzip",
    type = int
)
parser.add_argument(
    "--keep_plink",
    help="Keep the data in PLINK format instead of converting to VCF.",
    type = bool,
    default = False
)
parser.add_argument(
    "--cohort",
    help="Name of the cohort. (e.g. UHS)",
    type = str,
    default = ""
)

args = parser.parse_args()
workingDir = args.working_dir if (args.working_dir[-1] == "/") else (args.working_dir + "/")

def flip(allele):
    flipMap = {
        "A": "T",
        "T": "A",
        "C": "G",
        "G": "C"
    }
    alleleComplement = ""
    for nt in reversed(allele):
        if nt in flipMap.keys():
            alleleComplement += flipMap[nt]
        else:
            alleleComplement = "ERROR"
            break
    return alleleComplement

# Generate freq file
print("Calculating study frequencies")
bfile = ""
if (args.bfile):
    bfile = " --bfile " + args.bfile
elif (args.bed and args.bim and args.fam):
    bfile = " --bed " + args.bed + " --bim " + args.bim + " --fam " + args.fam

#plinkCmd = args.plink + bfile + " --freqx --out " + workingDir + "freq"
plinkCmd = "{}{} --freqx --out {}freq{}".format(args.plink, bfile, workingDir, args.cohort)
os.system(plinkCmd + " > /dev/null 2>&1")

# Read frqx file
print("Reading study frequencies")
study = pd.read_csv(
    workingDir + "freq" + args.cohort + ".frqx",
    sep = "\t",
    header = 0,
    usecols = [0, 1, 2, 3, 4, 5, 6],
    names = ["CHR", "ID", "A1", "A2", "HOM_A1", "HET", "HOM_A2"]
)

# Calculate A1 freq
study['FREQ_A1'] = (study.HOM_A1 + (0.5 * study.HET)) / (study.HOM_A1 + study.HET + study.HOM_A2)

# Remove unneeded columns
study = study.drop(columns=['HOM_A1', 'HET', "HOM_A2"])

# Get list of all study variants
studyVariants = study.ID

# Get list of study chromosomes
studyChrs = study.CHR.unique()

# Read reference
print("Reading ref")
ref = pd.read_csv(
    args.ref,
    sep = "\t",
    header = 0,
    usecols = ["id", "a0", "a1", args.ref_group]
)
ref = ref.rename(columns={"id": "ID", "a0": "A2", "a1": "A1", args.ref_group: "FREQ_A1"})

print("Comparing study and ref")

# Remove non-overlapping variants
ref = ref[ref.ID.isin(study.ID)]
study = study[study.ID.isin(ref.ID)]

# Merge input and ref
merged = study.merge(
    ref,
    left_on='ID',
    right_on='ID',
    suffixes=["_STUDY", "_REF"],
    how="inner"
)

# Get reverse complement of study alleles
merged['A1_FLIPPED_STUDY'] = merged.A1_STUDY.apply(flip)
merged['A2_FLIPPED_STUDY'] = merged.A2_STUDY.apply(flip)

# Get freq difference
conditions = [
    (merged.A1_STUDY == merged.A1_REF) & (merged.A2_STUDY == merged.A2_REF),
    (merged.A1_STUDY == merged.A2_REF) & (merged.A2_STUDY == merged.A1_REF),
    (merged.A1_FLIPPED_STUDY == merged.A1_REF) & (merged.A2_FLIPPED_STUDY == merged.A2_REF),
    (merged.A1_FLIPPED_STUDY == merged.A2_REF) & (merged.A2_FLIPPED_STUDY == merged.A1_REF)
]
choices = [
    abs(merged.FREQ_A1_STUDY - merged.FREQ_A1_REF),
    abs(merged.FREQ_A1_STUDY - (1 - merged.FREQ_A1_REF)),
    abs(merged.FREQ_A1_STUDY - merged.FREQ_A1_REF),
    abs(merged.FREQ_A1_STUDY - (1 - merged.FREQ_A1_REF))
]
merged['FREQ_DIFF'] = np.select(conditions, choices, np.nan)

# Get list of variants to flip
condition1 = (merged.A1_STUDY != merged.A2_FLIPPED_STUDY)
condition2 = ((merged.A1_FLIPPED_STUDY == merged.A1_REF) & (merged.A2_FLIPPED_STUDY == merged.A2_REF))
condition3 = ((merged.A1_FLIPPED_STUDY == merged.A2_REF) & (merged.A2_FLIPPED_STUDY == merged.A1_REF))
flip = merged[condition1 & (condition2 | condition3)]['ID']
fileFlip = workingDir + "flip" + args.cohort + ".txt"
flip.to_csv(
    fileFlip,
    index = False,
    header = False
)

# Get list of A/T and C/G variants with FREQ_DIFF > 0.2 or MAF > 0.4
condition1 = (merged.A1_STUDY == merged.A2_FLIPPED_STUDY)
condition2 = (merged.FREQ_DIFF > 0.2)
condition3 = ((merged.FREQ_A1_STUDY > 0.4) & (merged.FREQ_A1_STUDY < 0.6))
exclude = merged[condition1 & (condition2 | condition3)]['ID']
fileExclude = workingDir + "exclude" + args.cohort + ".txt"
exclude.to_csv(
    fileExclude,
    index = False,
    header = False
)


print("Generating files for imputation.")
if args.keep_plink:
    # Flip variants in flip list, remove A/T and C/G variants with FREQ_DIFF > 0.2 or MAF > 0.4
    outPrefix = args.out_prefix
    plinkCmd = args.plink + bfile + " --flip " + fileFlip + " --exclude " + fileExclude  + \
            " --make-bed  --out " + outPrefix
    os.system(plinkCmd + " > /dev/null 2>&1")
else:
    for chrom in studyChrs:
        outPrefix = args.out_prefix + "_chr" + str(chrom)
        plinkCmd = args.plink + bfile + " --flip " + fileFlip + " --exclude " + fileExclude + \
                " --chr " + str(chrom) + " --recode vcf --out " + outPrefix
        os.system(plinkCmd + " > /dev/null 2>&1")
        bgzipCmd = args.bgzip + " " + outPrefix + ".vcf --threads " + str(args.bgzip_threads)
        os.system(bgzipCmd)


# Print summary
print(str(len(studyVariants)) + " variants in study")
print(str(len(study)) + " variants overlap with ref")
print(str(len(exclude)) + " A/T and C/G variants with MAF > 0.4 or freq difference compared to ref > 0.2 (excluded in output)")
print(str(len(flip)) + " non-plus strand variants (flipped in output)")
