# GenomicSEM Docker Tool (v0.0.5c)

This folder contains command-line R wrappers around GenomicSEM functions ([GitHub](https://github.com/GenomicSEM/GenomicSEM).
Each script takes `optparse` arguments, performs basic validation, runs one GenomicSEM function, and writes output as `.rds` (except `gsem_munge.R`, which writes munged `.sumstats.gz` files).

## Quick Mapping

| Script | Primary GenomicSEM function |
| --- | --- |
| `gsem_munge.R` | `munge()` |
| `gsem_ldsc.R` | `ldsc()` |
| `gsem_s_ldsc.R` | `s_ldsc()` |
| `gsem_sumstats.R` | `sumstats()` |
| `gsem_commonfactor.R` | `commonfactor()` |
| `gsem_commonfactorgwas.R` | `userGWAS()` |
| `gsem_usergwas.R` | `userGWAS()` |
| `gsem_usermodel.R` | `usermodel()` |
| `gsem_enrich.R` | `enrich()` |
| `gsem_merge_rds.R` | Merges split RDS outputs (`userGWAS` / `usermodel`) |

## 1) gsem_munge.R

### Purpose

- Munges raw GWAS summary statistics into GenomicSEM/LDSC-ready files.

### Function call

- `munge(files, hm3, trait.names, N, info.filter, maf.filter, parallel, cores, overwrite)`

### CLI parameters

| Flag | Required | Type | Default | Description |
| --- | --- | --- | --- | --- |
| `--sumstats_files` | Yes | character (CSV) | none | Comma-separated input GWAS summary statistic files. |
| `--trait_names` | Yes | character (CSV) | none | Comma-separated trait names. |
| `--sample_sizes` | Yes | character (CSV -> numeric) | none | Comma-separated sample sizes. |
| `--ref_snp_list` | Yes | character | none | Path to reference SNP list (HM3). |
| `--out_dir` | Yes | character | none | Output directory for munged files. |
| `--info_filter` | No | double | `0.9` | INFO/R2 filter. |
| `--maf_filter` | No | double | `0.01` | Minor allele frequency filter. |
| `--parallel` | No | flag | `FALSE` | Enable parallel processing. |
| `--cores` | No | integer | `1` | Number of cores when `--parallel` is set. |
| `--no_overwrite` | No | flag | `FALSE` | If set, existing files are not overwritten. |

### Validation/behavior

- Required fields are checked for `NULL`.
- `--sample_sizes` is converted to numeric.
- `overwrite` passed to `munge()` is `!no_overwrite`.

## 2) gsem_ldsc.R

### Purpose

- Runs LDSC using munged sumstats and saves covariance structure to RDS.

### Function call

- `ldsc(traits, sample.prev, population.prev, ld, wld, trait.names, ldsc.log)`

### CLI parameters

| Flag | Required | Type | Default | Description |
| --- | --- | --- | --- | --- |
| `--sumstats_files` | Yes | character (CSV) | none | Comma-separated munged sumstats files. |
| `--trait_names` | Yes | character (CSV) | none | Comma-separated trait names. |
| `--sample_prevs` | Yes | character (CSV -> numeric) | none | Comma-separated sample prevalences. |
| `--population_prevs` | Yes | character (CSV -> numeric) | none | Comma-separated population prevalences. |
| `--ld_dir` | Yes | character | none | LD score directory. |
| `--wld_dir` | Yes | character | none | LD weights directory. |
| `--output_prefix` | Yes | character | none | Prefix for `.rds` and `.log` outputs. |

### Validation/behavior

- Required fields are checked for `NULL`.
- `sample_prevs` and `population_prevs` are converted to numeric.
- Script renames `*_ldsc.log` to `.log` after run if present.

## 3) gsem_s_ldsc.R (**untested**)

### Purpose

- Runs stratified LDSC.

### Function call

- `s_ldsc(traits, sample.prev, population.prev, ld, wld, frq, trait.names, n.blocks, ldsc.log, exclude_cont)`

### CLI parameters

| Flag | Required | Type | Default | Description |
| --- | --- | --- | --- | --- |
| `--sumstats_files` | Yes | character (CSV) | none | Comma-separated munged sumstats files. |
| `--trait_names` | Yes | character (CSV) | none | Comma-separated trait names. |
| `--sample_prevs` | Yes | character (CSV -> numeric) | none | Comma-separated sample prevalences. |
| `--population_prevs` | Yes | character (CSV -> numeric) | none | Comma-separated population prevalences. |
| `--ld_dir` | Yes | character | none | Partitioned LD score directory. |
| `--wld_dir` | Yes | character | none | Weight LD directory. |
| `--frq` | Yes | character | none | Frequency-file directory for MAF filtering. |
| `--output_prefix` | Yes | character | none | Prefix for `.rds` and `.log` outputs. |
| `--n_blocks` | No | integer | `200` | Jackknife block count. |
| `--ldsc_log` | No | character | none | Declared option, but not used in function call. |
| `--include_cont` | No | flag | `FALSE` | Include continuous annotations (`exclude_cont = !include_cont`). |

### Validation/behavior

- Required fields are checked for `NULL`.
- `sample_prevs` and `population_prevs` are converted to numeric.
- Log filename is always set to `paste0(output_prefix, ".log")`.

## 4) gsem_sumstats.R

### Purpose

- Prepares summary statistics for SEM downstream steps.

### Function call

- `sumstats(files, ref, trait.names, se.logit, N, OLS, linprob, betas, info.filter, maf.filter, keep.indel, parallel, cores)`

### CLI parameters

| Flag | Required | Type | Default | Description |
| --- | --- | --- | --- | --- |
| `--sumstats_files` | Yes | character (CSV) | none | Comma-separated GWAS input files. |
| `--trait_names` | Yes | character (CSV) | none | Comma-separated trait names. |
| `--sample_sizes` | Yes | character (CSV -> numeric) | none | Comma-separated sample sizes. |
| `--se_logit` | Yes | character (CSV -> logical) | none | Comma-separated `T/F` per trait for logistic-scale SE. |
| `--ref_snp_list` | Yes | character | none | HM3 SNP list file. |
| `--output_prefix` | Yes | character | none | Prefix for output `.rds`. |
| `--ols` | No | character (CSV -> logical) | `NULL` | Optional OLS indicator per trait. |
| `--linprob` | No | character (CSV -> logical) | `NULL` | Optional linear-probability indicator per trait. |
| `--betas` | No | character (CSV) | `NULL` | Optional beta column names for standardized continuous traits. |
| `--info_filter` | No | double | `0.9` | INFO/R2 filter. |
| `--maf_filter` | No | double | `0.01` | MAF filter. |
| `--keep_indel` | No | flag | `FALSE` | Keep indels if set. |
| `--parallel` | No | flag | `FALSE` | Enable parallel processing. |
| `--cores` | No | integer | `1` | Number of cores when parallelized. |

### Validation/behavior

- Required fields are checked for `NULL`.
- Several CSV inputs are converted (`numeric`, `logical`, or character vector as needed).

## 5) gsem_commonfactor.R (**untested**)

### Purpose

- Fits a common-factor model from LDSC output.

### Function call

- `commonfactor(covstruc, estimation)`

### CLI parameters

| Flag | Required | Type | Default | Description |
| --- | --- | --- | --- | --- |
| `--ldsc_rds` | Yes | character | none | RDS containing LDSC output. |
| `--estimation_method` | Yes | character | `"DWLS"` | Estimation method passed to GenomicSEM. |
| `--output_prefix` | Yes | character | none | Prefix for output `.rds`. |

### Validation/behavior

- Required fields are checked for `NULL`.

## 6) gsem_commonfactorgwas.R (**untested**)

### Purpose

- Runs common-factor GWAS with `userGWAS()` using LDSC structure and summary statistics.

### Function call

- `userGWAS(covstruc, SNPs, estimation, toler, SNPSE, GC, MPI, smooth_check, TWAS, parallel, cores)`

### CLI parameters

| Flag | Required | Type | Default | Description |
| --- | --- | --- | --- | --- |
| `--ldsc_rds` | Yes | character | none | RDS containing LDSC output. |
| `--sumstats` | Yes | character | none | Summary statistics file from `sumstats()` (RDS or text table). |
| `--estimation_method` | Yes | character | `"DWLS"` | Estimation method for GWAS model. |
| `--output_prefix` | Yes | character | none | Prefix for output `.rds`. |
| `--toler` | No | float | `FALSE` | Matrix inversion tolerance. |
| `--snpse` | No | float | `FALSE` | SNP SE override. |
| `--gc` | No | character | `"standard"` | Genomic control mode: `standard`, `conserv`, or `none`. |
| `--mpi` | No | flag | `FALSE` | Use MPI/multi-node processing. |
| `--smooth_check` | No | flag | `FALSE` | Save smoothing diagnostics. |
| `--twas` | No | flag | `FALSE` | TWAS mode. |
| `--parallel` | No | flag | `FALSE` | Enable parallel processing. |
| `--cores` | No | integer | `1` | Number of cores when parallelized. |

### Validation/behavior

- Required fields are checked for `NULL`.
- `--gc` is explicitly validated (`standard|conserv|none`).

## 7) gsem_usergwas.R

### Purpose

- Runs model-based GWAS (`userGWAS`) using a lavaan model and selected output components.

### Function call

- `userGWAS(covstruc, SNPs, model, estimation, printwarn, sub, toler, SNPSE, GC, MPI, smooth_check, TWAS, std.lv, fix_measurement, Q_SNP, parallel, cores)`

### CLI parameters

| Flag | Required | Type | Default | Description |
| --- | --- | --- | --- | --- |
| `--ldsc_rds` | Yes | character | none | RDS containing LDSC output. |
| `--sumstats` | Yes | character | none | Summary statistics file from `sumstats()` (RDS or text table). |
| `--model_lavaan` | Yes | character | none | Lavaan model file path. |
| `--estimation_method` | Yes | character | `"DWLS"` | Estimation method for user GWAS model. |
| `--output_prefix` | Yes | character | none | Prefix for output `.rds`. |
| `--not_printwarn` | No | flag | `FALSE` | If set, suppress per-SNP lavaan warnings/errors. |
| `--sub` | No | character (CSV) | `NULL` | Comma-separated subset of model lines to return. |
| `--toler` | No | float | `FALSE` | Matrix inversion tolerance. |
| `--snpse` | No | float | `FALSE` | SNP SE override. |
| `--gc` | No | character | `"standard"` | Genomic control mode: `standard`, `conserv`, or `none`. |
| `--mpi` | No | flag | `FALSE` | Use MPI/multi-node processing. |
| `--smooth_check` | No | flag | `FALSE` | Save smoothing diagnostics. |
| `--twas` | No | flag | `FALSE` | TWAS mode. |
| `--std_lv` | No | flag | `FALSE` | Use unit-variance latent variable scaling. |
| `--not_fix_measurement` | No | flag | `FALSE` | If set, do not constrain measurement model across SNPs. |
| `--q_snp` | No | flag | `FALSE` | Compute Q_SNP statistics. |
| `--parallel` | No | flag | `FALSE` | Enable parallel processing. |
| `--cores` | No | integer | `1` | Number of cores when parallelized. |

### Validation/behavior

- Required fields are checked for `NULL`.
- `--gc` is explicitly validated (`standard|conserv|none`).
- If `--sub` is provided, each value must exactly match a line in `model_lavaan`; otherwise the script stops.

## 8) gsem_usermodel.R (**untested**)

### Purpose

- Fits a user-specified SEM model using LDSC-derived covariance structure.

### Function call

- `usermodel(covstruc, model, estimation, CFIcalc, std.lv, imp_cov, fix_resid, toler, Q_Factor)`

### CLI parameters

| Flag | Required | Type | Default | Description |
| --- | --- | --- | --- | --- |
| `--ldsc_rds` | Yes | character | none | RDS containing LDSC output. |
| `--model_lavaan` | Yes | character | none | Lavaan model file path. |
| `--estimation_method` | Yes | character | none | Estimation method for usermodel. |
| `--output_prefix` | Yes | character | none | Prefix for output `.rds`. |
| `--cficalc` | No | flag | `FALSE` | Compute CFI. |
| `--std_lv` | No | flag | `FALSE` | Standardize latent variables with unit variance ID. |
| `--imp_cov` | No | flag | `FALSE` | Return implied model and residual covariance output. |
| `--fix_resid` | No | flag | `FALSE` | Constrain residual variances > 0 to aid convergence. |
| `--toler` | No | float | `FALSE` | Matrix inversion tolerance for sandwich SE. |
| `--q_factor` | No | flag | `FALSE` | Compute heterogeneity statistic for factor correlations. |

### Validation/behavior

- Required fields are checked for `NULL`.

## 9) gsem_enrich.R (**untested**)

### Purpose

- Estimates enrichment for selected lavaan parameters using stratified LDSC output.

### Function call

- `enrich(covstruc, model, params, fix, std.lv, rm.flank, tau, base, toler, fixparam)`

### CLI parameters

| Flag | Required | Type | Default | Description |
| --- | --- | --- | --- | --- |
| `--s_ldsc_rds` | Yes | character | none | RDS containing stratified LDSC output. |
| `--model_lavaan` | Yes | character | none | Lavaan model file path. |
| `--params` | Yes | character | none | File containing target parameter(s), one per line (lavaan syntax). |
| `--output_prefix` | Yes | character | none | Prefix for output `.rds`. |
| `--fix` | No | character | `"regressions"` | Parameter type to fix: typically `regressions`, `variances`, `covariances`. |
| `--std_lv` | No | flag | `FALSE` | Use unit-variance latent variable scaling. |
| `--not_rm_flank` | No | flag | `FALSE` | If set, keep flanking-window and continuous annotations in output. |
| `--tau` | No | flag | `FALSE` | Use tau matrices instead of zero-order matrices. |
| `--not_base` | No | flag | `FALSE` | If set, do not include baseline-model estimates in output. |
| `--toler` | No | float | `NULL` | Matrix inversion tolerance. |
| `--fixparam` | No | character | `NULL` | File with parameters to fix in annotation-level estimation. |

### Validation/behavior

- Required fields are checked for `NULL`.
- `params` and optional `fixparam` are read as line-based text files.
- `rm.flank` is set to `!not_rm_flank`; `base` is set to `!not_base`.

## 10) gsem_merge_rds.R

### Purpose

- Merges split RDS outputs from partitioned/chunked runs (such as per-chromosome or split runs of `userGWAS()` or `usermodel()`) into a single consolidated `.rds` file (and `.txt` if the output is a data frame or matrix).

### CLI parameters

| Flag | Required | Type | Default | Description |
| --- | --- | --- | --- | --- |
| `--rds_files` | Conditional | character (CSV) | none | Comma-separated list of RDS files to merge. |
| `--rds_file_list` | Conditional | character | none | File containing paths to RDS files to merge, one per line. |
| `--output_prefix` | Conditional | character | none | Output prefix for merged `.rds` and `.txt` files. |
| `--output_rds` | Conditional | character | none | Explicit path for the merged `.rds` output file. |

### Validation/behavior

- Requires either `--rds_files` or `--rds_file_list` (with existing files).
- Requires either `--output_prefix` or `--output_rds`.
- Supports merging data frames/matrices (via row-binding), lists of data frames/matrices (element-wise row-binding across lists), and vectors.
- Automatically saves merged results to RDS and creates a tab-delimited `.txt` table when the merged object is a data frame or matrix.

## General implementation behavior across scripts

- All scripts parse options with `optparse` and print parsed arguments using `str(opt)`.
- Output directory is created automatically when missing.
- For wrappers writing structured outputs, result objects are saved to `paste0(output_prefix, ".rds")`.
