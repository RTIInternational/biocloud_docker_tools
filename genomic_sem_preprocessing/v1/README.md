# Genomic SEM Preprocessing Docker Image

## Overview

This Docker image provides a containerized environment for preprocessing summary statistics files for GenomicSEM analysis. The image includes the `genomic_sem_preprocessing.py` script which:

- Reads summary statistics files in TSV format
- Extracts and renames columns based on user-specified mappings
- Extracts rsID from variant identifiers (searches for `/rs\d+/` pattern)
- Outputs a gzipped TSV file for downstream analysis

## Quick Start

### Build the Docker Image

```bash
docker build -t genomic-sem-preprocessing:v1 /path/to/genomic_sem_preprocessing/v1/
```

### Run the Docker Container

```bash
docker run \
  -v /path/to/data:/data \
  genomic-sem-preprocessing:v1 \
  --sumstats_file /data/input.txt \
  --col_variant_id variant_id \
  --col_effect_allele a1 \
  --col_non_effect_allele a2 \
  --col_effect beta \
  --col_p pval \
  --out_file /data/output.tsv
```

## Prerequisites

- Docker installed and running
- Input summary statistics file in TSV format (or other delimited format)
- Write permissions to output directory

## Parameters

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `--sumstats_file` | string | Path to the input summary statistics file. Can be any text-based delimited format. |
| `--col_variant_id` | string | Column name in the input file containing variant identifiers. The script will extract rsID (format: rs########) from this column, or keep the value unchanged if no rsID is found. |
| `--col_effect_allele` | string | Column name containing the effect allele (typically coded as A1 or ALT). |
| `--col_non_effect_allele` | string | Column name containing the non-effect allele (typically coded as A2 or REF). |
| `--col_effect` | string | Column name containing the effect size estimate (e.g., beta, log odds ratio). |
| `--col_p` | string | Column name containing the p-value for the association. |
| `--out_file` | string | Output file path. If it does not end with `.gz`, the extension will be automatically appended. Output will be a gzipped TSV file. |

### Optional Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `--sumstats_sep` | string | Field separator/delimiter used in the input file. Can be any single character or `\t` for tab. | `\t` (tab) |
| `--col_z` | string | Column name containing Z-scores. Include if available. | None (omitted from output if not provided) |
| `--col_se` | string | Column name containing standard errors. Include if available. | None (omitted from output if not provided) |
| `--col_n` | string | Column name containing sample size. Include if available. | None (omitted from output if not provided) |
| `--col_effect_allele_freq` | string | Column name containing effect allele frequency (EAF/MAF). Include if available. | None (omitted from output if not provided) |
| `--col_info` | string | Column name containing imputation quality score (INFO). Include if available. | None (omitted from output if not provided) |
| `--col_direction` | string | Column name containing directional effect information. Include if available. | None (omitted from output if not provided) |

## Output

The script produces a single gzipped TSV file containing:

- Only the columns specified in the parameters
- Columns renamed to remove the `col_` prefix (e.g., `col_variant_id` → `variant_id`)
- Variant IDs with extracted rsIDs (e.g., `1:12345:A:G/rs123456` → `rs123456`)
- Tab-separated values
- gzip compression for reduced file size

## Examples

### Minimal Example (Only Required Columns)

```bash
docker run \
  -v /home/user/data:/data \
  genomic-sem-preprocessing:v1 \
  --sumstats_file /data/gwas.txt \
  --col_variant_id SNP \
  --col_effect_allele ALT \
  --col_non_effect_allele REF \
  --col_effect BETA \
  --col_p P \
  --out_file /data/gwas_processed.tsv
```

**Output file:** `/home/user/data/gwas_processed.tsv.gz`

### Complete Example (All Available Columns)

```bash
docker run \
  -v /home/user/data:/data \
  genomic-sem-preprocessing:v1 \
  --sumstats_file /data/gwas.txt \
  --col_variant_id SNP \
  --col_effect_allele ALT \
  --col_non_effect_allele REF \
  --col_effect BETA \
  --col_p P \
  --col_z Z \
  --col_se SE \
  --col_n N \
  --col_effect_allele_freq EAF \
  --col_info INFO \
  --col_direction DIRECTION \
  --out_file /data/gwas_processed
```

**Output file:** `/home/user/data/gwas_processed.gz` (note: `.gz` is automatically appended)

### Example with Custom Delimiter

```bash
docker run \
  -v /home/user/data:/data \
  genomic-sem-preprocessing:v1 \
  --sumstats_file /data/gwas.csv \
  --sumstats_sep "," \
  --col_variant_id variant_id \
  --col_effect_allele allele1 \
  --col_non_effect_allele allele2 \
  --col_effect effect_size \
  --col_p p_value \
  --col_se se \
  --out_file /data/gwas_processed.tsv
```

## Column Name Mapping

The script transforms column names by removing the `col_` prefix:

| Input Parameter | Output Column Name |
|-----------------|-------------------|
| `col_variant_id` | `variant_id` |
| `col_effect_allele` | `effect_allele` |
| `col_non_effect_allele` | `non_effect_allele` |
| `col_effect` | `effect` |
| `col_p` | `p` |
| `col_z` | `z` |
| `col_se` | `se` |
| `col_n` | `n` |
| `col_effect_allele_freq` | `effect_allele_freq` |
| `col_info` | `info` |
| `col_direction` | `direction` |

## rsID Extraction Logic

The script searches for rsID patterns in the `variant_id` column using the regular expression `/rs\d+/`:

- Input: `chr1:12345:A:G/rs123456` → Output: `rs123456`
- Input: `rs789012` → Output: `rs789012`
- Input: `1_12345_A_G` → Output: `1_12345_A_G` (unchanged if no rsID found)
- Input: `NA` → Output: `NA` (handles missing values)

## Error Handling

The script includes comprehensive error handling:

- **File Not Found:** Returns error if input file does not exist
- **Missing Columns:** Returns error if any specified column does not exist in the input file
- **Read Errors:** Returns error with details if file cannot be read (e.g., encoding issues)
- **Write Errors:** Returns error if output file cannot be written

All error messages are printed to stderr and the script exits with code 1.

## Container Specifications

- **Base Image:** Python 3.11-slim
- **Working Directory:** `/app`
- **Entrypoint:** `python3 /app/genomic_sem_preprocessing.py`
- **Installed Packages:** pandas (≥1.3.0), numpy (≥1.20.0)

## Tips and Best Practices

1. **Use Volume Mounts:** Mount directories containing your data with `-v` to avoid copying large files into the container.

2. **Preserve File Permissions:** If you need to ensure specific file ownership, you may want to add user specifications to your docker run command.

3. **Memory Considerations:** For very large files, ensure your Docker daemon has sufficient memory allocated.

4. **Naming Convention:** Include the output file extension explicitly in the `--out_file` parameter (e.g., `.tsv`, `.txt`) for clarity, even though it will be overridden with `.gz`.

5. **Testing:** Before running on large datasets, test with a small subset of rows to verify column names and mapping.

## Support and Troubleshooting

### Common Issues

**Issue:** `Error: Missing columns in input file`

- **Solution:** Verify the exact column names in your input file match the parameters you provided. Check for typos and case sensitivity.

**Issue:** `Error reading file: [error message]`

- **Solution:** Ensure the file is a valid text-based format. Check for encoding issues (should be UTF-8 compatible). Verify the file path is correct.

**Issue:** `ModuleNotFoundError: No module named 'pandas'`

- **Solution:** Rebuild the Docker image to ensure all dependencies are installed correctly.

### Getting Help

1. Check that all required parameters are provided
2. Verify input file format and column names
3. Ensure output directory is writable
4. Check Docker logs for detailed error messages
