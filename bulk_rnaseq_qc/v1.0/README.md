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
- `--run_name <name>`: Prefix used for outputs and report naming.

Optional flags:
- `--output_dir <path>`: Parent output directory (default: `outputs`).
- `--sample_id_col <colname>`: Sample ID column in phenotype TSV (default: `RNum`).
- `--rin_col <colname>`: RIN column name in phenotype TSV (default: `RIN`).
- `--sex_col <colname>`: Sex column name for chrY QC metrics (default: `Sex`).
- `--group_vars <comma-separated-colnames>`: Phenotype columns used for PCA coloring. If omitted, PCA plotting is skipped.

## Command Usage

```bash
Rscript bulk_rnaseq_quality_control.R \
  --multiqc_dir <path> \
  --txi_rds <path> \
  --pheno_tsv <path> \
  --annotation_gtf <path> \
  --run_name <name> \
  [--output_dir <path>] \
  [--sample_id_col <colname>] \
  [--rin_col <colname>] \
  [--sex_col <colname>] \
  [--group_vars <comma-separated-colnames>]
```

## Build Docker Image

From this folder:

```bash
docker build -t bulk_rnaseq_qc:v1.0 .
```

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
- Mitochondrial mapping% < 10
- Ribosomal RNA mapping% < 1

## Repository Files

- `Dockerfile`: container definition and dependency installation.
- `bulk_rnaseq_quality_control.R`: main QC pipeline script.
- `README.md`: usage and output documentation.

## Contact

For questions or feedback:

- Caryn Willis (cdwillis@rti.org)