import argparse
import pandas as pd

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--bim",
    help="Bim file to check",
    type = str
)
parser.add_argument(
    "--ref",
    help="Legend file with chr column added",
    type = str
)
args = parser.parse_args()

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

study = pd.read_csv(
    args.bim,
    sep = "\t",
    header = None,
    usecols = [0, 3, 4, 5],
    names = ["CHR", "POS", "A1", "A2"],
    dtype = str
)

ref = pd.read_csv(
    args.ref,
    sep = "\t",
    header = 0,
    usecols = [1, 2, 3, 4],
    names = ["CHR", "POS", "A1", "A2"],
    dtype = str
)

# Filter study by ref chr
study = study[study.CHR.isin(ref.CHR)]

# Get count of study variants
print(str(len(study)) + " variants in bim on chromosomes in ref")

# Drop A/T and C/G variants from study
study = study.drop(study[(study.A1 == "A") & (study.A2 == "T")].index)
study = study.drop(study[(study.A1 == "T") & (study.A2 == "A")].index)
study = study.drop(study[(study.A1 == "C") & (study.A2 == "G")].index)
study = study.drop(study[(study.A1 == "G") & (study.A2 == "C")].index)

# Drop monomorphic variants from study
study = study.drop(study[(study.A1 == "0") | (study.A2 == "0")].index)

# Remove non-overlapping positions
study = study[study.POS.isin(ref.POS)]
ref = ref[ref.POS.isin(study.POS)]

# Create IDs for study
study["ID"] = study.CHR + "_" + study.POS + "_" + study.A1 + "_" + study.A2

# Create 4 variations of ID for ref
ref["A1_COMP"] = ref.A1.apply(flip)
ref["A2_COMP"] = ref.A2.apply(flip)
refTmp = ref.copy()
ref["ID"] = ref.CHR + "_" + ref.POS + "_" + ref.A1 + "_" + ref.A2
refTmp["ID"] = refTmp.CHR + "_" + refTmp.POS + "_" + refTmp.A2 + "_" + refTmp.A1
ref = pd.concat([ref, refTmp])
refTmp["ID"] = refTmp.CHR + "_" + refTmp.POS + "_" + refTmp.A1_COMP + "_" + refTmp.A2_COMP
ref = pd.concat([ref, refTmp])
refTmp["ID"] = refTmp.CHR + "_" + refTmp.POS + "_" + refTmp.A2_COMP + "_" + refTmp.A1_COMP
ref = pd.concat([ref, refTmp])

# Merge study and ref by ID
merged = study.merge(
    ref,
    left_on='ID',
    right_on='ID',
    suffixes=('_STUDY', '_REF'),
    how="inner"
)

# Get total count of merged variants
print(str(len(merged)) + " non-A/T, non-C/G, non-monomorphic variants in common with reference")

# Get count of study variants that are plus strand orientation
plus = merged[
    ((merged.A1_STUDY == merged.A1_REF) & (merged.A2_STUDY == merged.A2_REF)) |
    ((merged.A1_STUDY == merged.A2_REF) & (merged.A2_STUDY == merged.A1_REF))
]
print(str(len(plus)) + " plus strand variants")

# Get count of study variants that are not plus strand, but which can be flipped to plus strand
flipped = merged[
    ((merged.A1_STUDY == merged.A1_COMP) & (merged.A2_STUDY == merged.A2_COMP)) |
    ((merged.A1_STUDY == merged.A2_COMP) & (merged.A2_STUDY == merged.A1_COMP))
]
print(str(len(flipped)) + " non-plus strand variants fixed by strand flip")
