import argparse
import json
from pathlib import Path

import gwaslab as gl

def add_sumstats_args(parser):
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input summary statistics file.")
    parser.add_argument("--fmt", type=str, default="auto", help="Input format identifier (e.g. 'auto', 'plink2', 'vcf', etc.).")
    parser.add_argument("--input_tab_fmt", type=str, default=None, help="Input tabular format (for example, tsv or parquet).")
    parser.add_argument("--snpid", type=str, default=None, help="Column name for variant ID.")
    parser.add_argument("--rsid", type=str, default=None, help="Column name for rsID.")
    parser.add_argument("--chrom", type=str, default=None, help="Column name for chromosome.")
    parser.add_argument("--pos", type=str, default=None, help="Column name for position.")
    parser.add_argument("--ea", type=str, default=None, help="Column name for effect allele.")
    parser.add_argument("--nea", type=str, default=None, help="Column name for non-effect allele.")
    parser.add_argument("--ref", type=str, default=None, help="Reference allele column name.")
    parser.add_argument("--alt", type=str, default=None, help="Alternative allele column name.")
    parser.add_argument("--eaf", type=str, default=None, help="Column name for effect allele frequency.")
    parser.add_argument("--neaf", type=str, default=None, help="Non-effect allele frequency column name.")
    parser.add_argument("--maf", type=str, default=None, help="Minor allele frequency column name.")
    parser.add_argument("--beta", type=str, default=None, help="Column name for beta.")
    parser.add_argument("--se", type=str, default=None, help="Column name for standard error.")
    parser.add_argument("--chisq", type=str, default=None, help="Chi-square statistic column name.")
    parser.add_argument("--z", type=str, default=None, help="Z-score column name.")
    parser.add_argument("--f", type=str, default=None, help="F-statistic column name.")
    parser.add_argument("--t", type=str, default=None, help="T-statistic column name.")
    parser.add_argument("--p", type=str, default=None, help="Column name for p-value.")
    parser.add_argument("--q", type=str, default=None, help="Q-statistic column name.")
    parser.add_argument("--mlog10p", type=str, default=None, help="Column name for -log10(p).")
    parser.add_argument("--test", type=str, default=None, help="Association test column name.")
    parser.add_argument("--info", type=str, default=None, help="Imputation INFO/RSQ column name.")
    parser.add_argument("--OR", type=str, default=None, help="Odds ratio column name.")
    parser.add_argument("--OR_95L", type=str, default=None, help="Odds ratio lower 95%% confidence limit column.")
    parser.add_argument("--OR_95U", type=str, default=None, help="Odds ratio upper 95%% confidence limit column.")
    parser.add_argument("--beta_95L", type=str, default=None, help="Beta lower 95%% confidence limit column.")
    parser.add_argument("--beta_95U", type=str, default=None, help="Beta upper 95%% confidence limit column.")
    parser.add_argument("--HR", type=str, default=None, help="Hazard ratio column name.")
    parser.add_argument("--HR_95L", type=str, default=None, help="Hazard ratio lower 95%% confidence limit column.")
    parser.add_argument("--HR_95U", type=str, default=None, help="Hazard ratio upper 95%% confidence limit column.")
    parser.add_argument("--n", type=str, default=None, help="Column name or constant for sample size.")
    parser.add_argument("--ncase", type=str, default=None, help="Case count column name or integer constant.")
    parser.add_argument("--ncontrol", type=str, default=None, help="Control count column name or integer constant.")
    parser.add_argument("--neff", type=str, default=None, help="Effective sample size column name.")
    parser.add_argument("--i2", type=str, default=None, help="I-squared heterogeneity column name.")
    parser.add_argument("--phet", type=str, default=None, help="Heterogeneity p-value column name.")
    parser.add_argument("--dof", type=str, default=None, help="Degrees of freedom column name or integer constant.")
    parser.add_argument("--snpr2", type=str, default=None, help="Per-SNP phenotypic variance explained column.")
    parser.add_argument("--status", type=str, default=None, help="Variant status code column name.")
    parser.add_argument("--direction", type=str, default=None, help="METAL-style effect direction column name.")
    parser.add_argument("--other", nargs="+", default=None, help="Additional columns to retain.")
    parser.add_argument("--exclude", nargs="+", default=None, help="Columns to exclude when loading.")
    parser.add_argument("--include", nargs="+", default=None, help="Columns to include when loading.")
    parser.add_argument("--chrom_pat", type=str, default=None, help="Chromosome parsing pattern.")
    parser.add_argument("--snpid_pat", type=str, default=None, help="SNPID parsing pattern.")
    parser.add_argument("--verbose", action=argparse.BooleanOptionalAction, default=None, help="Enable or disable GWASLab loading logs.")
    parser.add_argument("--study", type=str, default=None, help="Study name in metadata.")
    parser.add_argument("--trait", type=str, default=None, help="Trait name in metadata.")
    parser.add_argument("--build", type=str, default="99", help="Genome build version (e.g. '19', '38', '99').")
    parser.add_argument("--species", type=str, default=None, help="Species name (default: homo sapiens).")
    parser.add_argument("--readargs_json", type=str, default=None, help="JSON object of additional input-reading options.")


def load_sumstats(args):
    init_kwargs = {"sumstats": args.sumstats, "fmt": args.fmt, "build": args.build}
    if args.input_tab_fmt is not None:
        init_kwargs["tab_fmt"] = args.input_tab_fmt
    for col in [
        "snpid", "rsid", "chrom", "pos", "ea", "nea", "ref", "alt", "eaf", "neaf", "maf",
        "n", "beta", "se", "chisq", "z", "f", "t", "p", "q", "mlog10p", "test", "info",
        "OR", "OR_95L", "OR_95U", "beta_95L", "beta_95U", "HR", "HR_95L", "HR_95U",
        "ncase", "ncontrol", "neff", "i2", "phet", "dof", "snpr2", "status",
        "other", "exclude", "include", "chrom_pat", "snpid_pat", "direction",
        "verbose", "study", "trait", "species",
    ]:
        val = getattr(args, col, None)
        if val is not None:
            if col in ("n", "ncase", "ncontrol", "dof") and val.isdecimal():
                val = int(val)
            init_kwargs[col] = val
    if args.readargs_json is not None:
        readargs = json.loads(args.readargs_json)
        if not isinstance(readargs, dict):
            raise ValueError("--readargs_json must be a JSON object")
        init_kwargs["readargs"] = readargs
    return gl.Sumstats(**init_kwargs)


def save_sumstats(mysumstats, out_path, out_fmt="gwaslab", gzip=True):
    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    clean_path = out_path
    if clean_path.endswith(".gz"):
        clean_path = clean_path[:-3]
    if clean_path.endswith(".tsv") or clean_path.endswith(".txt") or clean_path.endswith(".csv"):
        clean_path = Path(clean_path).stem
    if out_fmt == "pickle":
        mysumstats.to_pickle(f'{clean_path}.pkl', gzip=gzip)
    elif out_fmt == "gsf":
        mysumstats.to_gsf(f'{clean_path}.gsf', gzip=gzip)
    else:
        mysumstats.to_format(clean_path, fmt=out_fmt, gzip=gzip)
