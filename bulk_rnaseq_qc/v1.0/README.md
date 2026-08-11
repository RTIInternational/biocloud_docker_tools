# Bulk RNA-seq Quality Control (v1.0)

## Overview

This project runs a bulk RNA-seq quality control workflow that combines MultiQC-derived metrics, tximport expression data, and phenotype metadata.

The pipeline:
- Builds sample-level QC metrics.
- Generates QC plots (FastQC, trimming, mapping, PCA, diversity, mito/ribo metrics).
- Applies threshold-based pass/fail summaries.
- Writes an HTML summary report.

Main script:
- `bulk_rnaseq_quality_control.R`

Container image default command:
- `Rscript /opt/bulk_rnaseq_quality_control.R --help`

## Inputs

Required flags:
- `--multiqc_dir <path>`: Directory containing parsed/aligned outputs expected by `omixjutsu::load_paired_end_qc_data()`.
- `--txi_rds <path>`: `tximport`-like `.rds` object containing at least `counts`.
- `--pheno_tsv <path>`: Tab-delimited phenotype file with a sample ID column.
- `--annotation_gtf <path>`: GTF used to derive mitochondrial/ribosomal/chrY feature sets.
- `--sample_id_col <colname>`: Sample ID column in phenotype TSV.
- `--run_name <name>`: Prefix used for outputs and report naming.

Optional flags:
- `--output_dir <path>`: Parent output directory (default: `outputs`).
- `--rin_col <colname>`: RIN column name in phenotype TSV (default: `RIN`).
- `--sex_col <colname>`: Sex column name for chrY QC metrics (default: `Sex`).
- `--group_vars <comma-separated-colnames>`: Phenotype columns used for PCA coloring. If omitted, PCA plotting is skipped.

### Required contents of `--multiqc_dir`

The QC loader (`omixjutsu::load_paired_end_qc_data`) expects the following files to be present in the `--multiqc_dir` directory:

- `multiqc_fastqc.txt`
- `multiqc_hisat2.txt`
- `multiqc_rseqc_bam_stat.txt`
- `multiqc_rseqc_read_distribution.txt`
- `multiqc_salmon.txt`
- `multiqc_trimmomatic.txt`
- `rseqc_inner_distance_plot.tsv`
- `salmon_plot.tsv`
- `fastqc_per_base_sequence_quality_plot.tsv`
- `fastqc_per_sequence_quality_scores_plot.tsv`
- `fastqc_per_sequence_gc_content_plot.tsv`
- `fastqc_sequence_duplication_levels_plot.tsv`
- `fastqc_adapter_content_plot.tsv`
- `rseqc_known_junction_saturation_plot.tsv`
- `rseqc_novel_junction_saturation_plot.tsv`

If any of these files are missing, the script will fail when reading MultiQC-derived inputs.

## Command Usage

```bash
Rscript bulk_rnaseq_quality_control.R \
  --multiqc_dir <path> \
  --txi_rds <path> \
  --pheno_tsv <path> \
  --annotation_gtf <path> \
  --sample_id_col <colname> \
  --run_name <name> \
  [--output_dir <path>] \
  [--rin_col <colname>] \
  [--sex_col <colname>] \
  [--group_vars <comma-separated-colnames>]
```

## Build Docker Image

From this folder:

```bash
docker build -t bulk_rnaseq_qc:v1.0 .
```

## Docker Package Versions

The following versions are installed by the Dockerfile.

### Base Image and Platform

| Component | Version / Pin | Source |
|---|---|---|
| `rocker/r-ver` | `4.4.1` | Docker base image |
| Bioconductor release | `3.20` | `BiocManager::install(version = '3.20')` |

### R Package Managers

| Package | Version / Pin | Source |
|---|---|---|
| `remotes` | `2.5.0` | CRAN (`remotes::install_version`) |
| `pacman` | `0.5.1` | CRAN (`remotes::install_version`) |
| `BiocManager` | `1.30.26` | CRAN (`remotes::install_version`) |

### CRAN R Packages

| Package | Version / Pin | Source |
|---|---|---|
| `logr` | `1.3.9` | CRAN (`remotes::install_version`) |
| `dplyr` | `1.1.4` | CRAN (`remotes::install_version`) |
| `tibble` | `3.3.0` | CRAN (`remotes::install_version`) |
| `stringr` | `1.5.1` | CRAN (`remotes::install_version`) |
| `patchwork` | `1.3.1` | CRAN (`remotes::install_version`) |
| `ggplot2` | `3.5.2` | CRAN (`remotes::install_version`) |
| `RcppEigen` | `0.3.4.0.2` | CRAN (`remotes::install_version`) |

### Bioconductor R Packages

| Package | Version / Pin | Source |
|---|---|---|
| `DESeq2` | Installed from Bioconductor `3.20` | `BiocManager::install` |
| `tximport` | Installed from Bioconductor `3.20` | `BiocManager::install` |
| `IHW` | Installed from Bioconductor `3.20` | `BiocManager::install` |
| `lpsymphony` | Installed from Bioconductor `3.20` | `BiocManager::install` |

### GitHub R Packages

| Package | Version / Pin | Source |
|---|---|---|
| `omixjutsu` | `bryancquach/omixjutsu@d530c725c18567c69f00a3476388d6c8839b720f` | GitHub (`remotes::install_github`) |

### System Packages Installed via apt-get

These are installed from Debian/Ubuntu repositories in the base image and are explicitly version-pinned in the Dockerfile.

| Package | Version / Pin |
|---|---|
| `build-essential` | `12.9ubuntu3` |
| `gfortran` | `4:11.2.0-1ubuntu1` |
| `coinor-libsymphony-dev` | `5.6.17+dfsg-1` |
| `libglpk-dev` | `5.0-1` |
| `libuv1-dev` | `1.43.0-1ubuntu0.1` |
| `libcurl4-openssl-dev` | `7.81.0-1ubuntu1.25` |
| `libssl-dev` | `3.0.2-0ubuntu1.26` |
| `libxml2-dev` | `2.9.13+dfsg-1ubuntu0.12` |
| `libgit2-dev` | `1.1.0+dfsg.1-4.1ubuntu0.1` |
| `libfontconfig1-dev` | `2.13.1-4.2ubuntu5` |
| `libfreetype6-dev` | `2.11.1+dfsg-1ubuntu0.3` |
| `libfribidi-dev` | `1.0.8-2ubuntu3.1` |
| `libharfbuzz-dev` | `2.7.4-1ubuntu3.2` |
| `libjpeg-dev` | `8c-2ubuntu10` |
| `libpng-dev` | `1.6.37-3ubuntu0.5` |
| `libtiff5-dev` | `4.3.0-6ubuntu0.13` |
| `zlib1g-dev` | `1:1.2.11.dfsg-2ubuntu9.2` |
| `libbz2-dev` | `1.0.8-5build1` |
| `liblzma-dev` | `5.2.5-2ubuntu1.1` |
| `r-cran-rcppeigen` | `0.3.3.9.1-1` |
| `ca-certificates` | `20260601~22.04.1` |
| `git` | `1:2.34.1-1ubuntu1.17` |

## Run with Docker

This image uses `CMD` (not `ENTRYPOINT`).

- Running the image with no arguments shows help.
- To run QC, pass the full `Rscript` command explicitly.

Show help:

```bash
docker run --rm -it bulk_rnaseq_qc:v1.0
```

Run QC:

```bash
docker run --rm -it \
  -v "$PWD":/data \
  bulk_rnaseq_qc:v1.0 \
  Rscript /opt/bulk_rnaseq_quality_control.R \
  --multiqc_dir /data/path/to/multiqc_dir \
  --txi_rds /data/path/to/txi.rds \
  --pheno_tsv /data/path/to/pheno.tsv \
  --annotation_gtf /data/path/to/annotation.gtf \
  --sample_id_col RNum \
  --run_name study_run_001 \
  --output_dir /data/outputs
```

## Run Locally (without Docker)

```bash
Rscript bulk_rnaseq_quality_control.R \
  --multiqc_dir path/to/multiqc_dir \
  --txi_rds path/to/txi.rds \
  --pheno_tsv path/to/pheno.tsv \
  --annotation_gtf path/to/annotation.gtf \
  --sample_id_col RNum \
  --run_name study_run_001
```

## Output Structure

The script creates:

- `<output_dir>/<run_name>_quality_control/`
  - `bulk_rnaseq_qc.log`
  - `<run_name>_qc_summary.html`
  - `plots/`
  - `tables/`

Key tables:
- `tables/<run_name>_bulk_rnaseq_qc_metrics.tsv`: phenotype + QC metrics per sample.
- `tables/<run_name>_bulk_rnaseq_qc_threshold_summary.tsv`: threshold pass/fail counts.

Key report:
- `<run_name>_qc_summary.html`: links to tables/log and embeds all generated QC plots.

Typical plot outputs include:
- FastQC sequence depth, unique read percentage, phred per base, GC content.
- Trimmomatic retained/excluded reads summary.
- Salmon/HISAT2 mapping summaries.
- RSeQC mapping category summaries.
- RIN, mitochondrial RNA %, ribosomal RNA %, Shannon diversity.
- PCA panels for available `group_vars`.

## Notes and Validation Rules

- Sample IDs must overlap between `colnames(txi$counts)` and phenotype row IDs derived from `--sample_id_col`.
- Duplicate or missing sample IDs in phenotype input will stop execution.
- If `--rin_col` is not `RIN`, the script renames that column to `RIN` internally.
- chrY-based QC metrics are skipped if the `--sex_col` column is absent.

Threshold summary in the report includes rules such as:
- RIN > 5
- Effective sequencing depth > 10 million reads
- Retained reads percentage > 60%
- Mean read GC% between 35 and 65
- Salmon mapping% > 30
- Gene mapping% > 80
- Intergenic/genic ratio < 0.9
- Shannon index IQR rule OR transcriptome mapping% > 50
- Mitochondrial mapping% < 50
- Ribosomal RNA mapping% < 1

## Repository Files

- `Dockerfile`: container definition and dependency installation.
- `bulk_rnaseq_quality_control.R`: main QC pipeline script.
- `README.md`: usage and output documentation.

## Contact

For questions or feedback:

- Caryn Willis (cdwillis@rti.org)