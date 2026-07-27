# DNAm Processing QC Dockerfile

This Dockerfile sets up the R environment for running the DNA methylation (DNAm)
array processing and quality control pipeline used in the
[multiomics-aud-cs](https://github.com/rti-international/multiomics-aud-cs) project.

## Overview

**What does this image do?**

This image provides the R environment required to run `dnam_processing_qc.R`, a
DNAm array preprocessing pipeline built on the
[SeSAMe](https://bioconductor.org/packages/release/bioc/html/sesame.html)
framework. The pipeline processes Illumina Infinium BeadChip IDAT files and
performs the following steps:

- IDAT file reading and sample–sheet matching
- Predicted sex inference via `sesame::inferSex`; mismatch check against reported sex (skipped if `sex` column is absent from sample sheet)
- Experiment-independent probe masking (mapping quality, SNPs, cross-reactivity)
- Low beadcount probe filtering
- Dye bias correction (non-linear, SeSAMe `CD` steps)
- Detection p-value calculation via pOOBAH and probe/sample failure filtering
- NOOB background normalization
- QC statistic calculation
- SNP allele frequency extraction and pairwise sample correlation check
- Control probe PCA and beta-value PCA for covariate generation
- Output of beta values, M-values, masking info, QC stats, and updated sample sheet

**Supported platforms:** EPICv2, EPIC, HM450, HM27

**Base image:** `bioconductor/bioconductor_docker:RELEASE_3_23` (R ≥ 4.5.0)

**Key R packages installed:**

| Package | Version | Source | Purpose |
| --- | --- | --- | --- |
| `sesame` | 1.30.1 | Bioconductor 3.23 | Core DNAm preprocessing |
| `sesameData` | 1.30.0 | Bioconductor 3.23 | SeSAMe reference data |
| `minfi` | 1.58.0 | Bioconductor 3.23 | IDAT reading for beadcount |
| `wateRmelon` | 2.18.0 | Bioconductor 3.23 | Beadcount extraction |
| `BiocParallel` | 1.46.0 | Bioconductor 3.23 | Cross-platform parallelism |
| `PCAtools` | 2.24.0 | Bioconductor 3.23 | Elbow-point PCA |
| `GGally` | 2.4.0 | CRAN | Pairs plots |
| `logr` | 1.3.9 | CRAN | Pipeline logging |
| `pacman` | 0.5.1 | CRAN | Package loading utility |
| `dplyr`, `tibble`, `tidyr` | 1.2.1, 3.3.1, 1.3.2 | CRAN | Data manipulation |

<br>

## Usage

For full details, see the
[multiomics-aud-cs repository](https://github.com/rti-international/multiomics-aud-cs).
For a quick start, mount your working directory and run:

```bash
docker run -it \
  -v $PWD:/scratch \
  dnam_processing_qc:v1.0 \
  Rscript /opt/dnam_processing_qc.R \
    <idat_dir> \
    <platform> \
    <sample_sheet> \
    <run_name>
```

### Arguments

- `<idat_dir>` — directory containing IDAT files (can be nested)
- `<platform>` — array platform: one of `EPICv2`, `EPIC`, `HM450`, `HM27`
- `<sample_sheet>` — tab-delimited file with required columns `sample_id` and `prefix` (IDAT file prefix, without `_Red` or `_Grn` suffix), and optional column `sex`. If `sex` is absent, the predicted-vs-reported mismatch check is skipped and predicted sex is used.
- `<run_name>` — label used for the output directory and log file naming

### Outputs

All outputs are written to `outputs/<run_name>/` within the mounted directory:

| File | Description |
| --- | --- |
| `beta_values.txt` | Beta-value matrix for passing CpG probes |
| `m_values.txt` | M-value matrix for passing CpG probes |
| `cpg_masking.txt` | Per-probe masking reasons |
| `poobah_pvalues.txt` | pOOBAH detection p-values per probe per sample |
| `allele_freqs.txt` | SNP allele frequencies |
| `qc_stats.txt` | Per-sample QC metrics |
| `sample_sheet_pcs.txt` | Sample sheet with control probe and beta-value PCs appended |
| `sdf_processed.rds` | Processed SigDF R object |
| `dnam_processing_qc.log` | Pipeline run log |
| `plots/` | Pairs plots for negative control, non-negative control, and beta-value PCs |

## Build

To build this Docker image, you can use the following command:

```bash
docker build --rm -t dnam_processing_qc:v1.0 -f Dockerfile .
```

Here's what each part of the command does:

`docker build`: This command tells Docker to build an image.  
`--rm`: This flag removes any intermediate containers created during the build process, helping to keep your system clean.  
`-t dnam_processing_qc:v1.0`: The `-t` flag specifies the name and tag for the image.  
`-f Dockerfile`: This flag specifies the Dockerfile to use for building the image.  
`.`: The dot indicates that the build context is the current directory, where the Dockerfile is located.

Running this command will build a Docker image with the name `dnam_processing_qc:v1.0`.
Make sure you are in the directory containing the Dockerfile before running this command.

## Perform a testrun

```bash
docker run -it dnam_processing_qc:v1.0 Rscript -e "pacman::p_load(logr, sesame, parallel, BiocParallel, minfi, wateRmelon, dplyr, tibble, tidyr, PCAtools, GGally); message('All packages loaded successfully.')"
```

<details>

```text
Loading required package: logr
Loading required package: sesame
...
All packages loaded successfully.
```

</details>

<br><br>

## Contact

For additional information or assistance, please contact Xin Wu (xwu@rti.org).
