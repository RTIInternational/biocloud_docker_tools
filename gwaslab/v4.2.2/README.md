# GWASLab Docker Tool (v4.2.2)

## Description

This Docker image provides [GWASLab](https://cloufield.github.io/gwaslab/) (v4.2.2), a comprehensive Python toolkit for processing, standardizing, quality control, harmonizing, and visualizing GWAS summary statistics.

- **Documentation**: [https://cloufield.github.io/gwaslab/](https://cloufield.github.io/gwaslab/)
- **Repository**: [https://github.com/Cloufield/gwaslab](https://github.com/Cloufield/gwaslab)

---

## Features

- **Loading and Formatting**: Auto-detects headers or converts between common GWAS formats (PLINK, REGENIE, SAIGE, METAL, LDSC, MAGMA, GWAS-SSF, VCF, etc.).
- **Standardization & Normalization**: Standardizes variant IDs, chromosome/position notations, alleles, and genome builds (including liftover).
- **Quality Control**: Checks statistics sanity, removes extreme values, converts between equivalent statistics (BETA/SE, OR, P, Z, CHISQ, MLOG10P), and filters on MAF/INFO.
- **Harmonization**: Assigns rsIDs, aligns reference alleles using FASTA/VCF reference files, and infers strand for ambiguous/palindromic variants.
- **Visualization**: Manhattan plots, QQ plots, MQQ plots, Miami plots, Brisbane plots, Regional association plots, and genetic correlation heatmaps.

---

## Build Instructions

```bash
docker build -t rtibiocloud/gwaslab:v4.2.2 biocloud_docker_tools/gwaslab/v4.2.2/
```

---

## Usage

### Interactive Python / Script Execution

Run a Python script using GWASLab in a container:

```bash
docker run --rm -v /path/to/data:/data rtibiocloud/gwaslab:v4.2.2 \
    python3 /data/run_gwaslab.py
```

### Python Example

```python
import gwaslab as gl

# Load GWAS summary statistics (auto-detects format)
mysumstats = gl.Sumstats("/data/raw_sumstats.tsv.gz", fmt="auto")

# Perform basic QC and standardization
mysumstats.basic_check()

# Standardize variant IDs and normalize alleles
mysumstats.fix_id()

# Generate Manhattan and QQ plots
mysumstats.plot_mqq(save="/data/mqq_plot.png")

# Export to standard format
mysumstats.to_format("/data/standardized_sumstats.tsv.gz", fmt="gwaslab")
```

---

## Contact

For questions or inquiries about this Docker image, please contact Nathan Gaddis at <ngaddis@rti.org>.
