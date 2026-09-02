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

### Sumstats CLI Scripts

Each wrapper initializes the `Sumstats` object from an input file (`--sumstats`) and optional format/column mappings (`--fmt`, `--snpid`, `--chrom`, etc.):

#### Core (`sumstats/core/`)

| Script | GWASLab Method | Description |
| --- | --- | --- |
| `gwaslab_sumstats_basic_check.py` | `mysumstats.basic_check()` | All-in-one QC pipeline |
| `gwaslab_sumstats_harmonize.py` | `mysumstats.harmonize()` | Reference-based harmonization pipeline |
| `gwaslab_sumstats_liftover.py` | `mysumstats.liftover()` | UCSC chain-based genome build liftover |
| `gwaslab_sumstats_summary.py` | `mysumstats.summary()` | Generate structured QC summary report |
| `gwaslab_sumstats_lookup_status.py` | `mysumstats.lookup_status()` | Decode and summarize 7-digit STATUS codes |
| `gwaslab_sumstats_infer_build.py` | `mysumstats.infer_build()` | Infer genome build using HapMap3 SNPs |
| `gwaslab_sumstats_set_build.py` | `mysumstats.set_build()` | Set genome build in status and metadata |
| `gwaslab_sumstats_sort_coordinate.py` | `mysumstats.sort_coordinate()` | Sort variants by chromosome and position |
| `gwaslab_sumstats_sort_column.py` | `mysumstats.sort_column()` | Sort columns into standard GWAS order |
| `gwaslab_sumstats_fill_data.py` | `mysumstats.fill_data()` | Derive missing statistics (Z, P, MLOG10P, etc.) |
| `gwaslab_sumstats_check_ref.py` | `mysumstats.check_ref()` | Check NEA alignment with reference FASTA |
| `gwaslab_sumstats_infer_strand.py` | `mysumstats.infer_strand()` | Infer strand for palindromic SNPs/indels using VCF |
| `gwaslab_sumstats_flip_allele_stats.py` | `mysumstats.flip_allele_stats()` | Adjust statistics after strand/allele flipping |
| `gwaslab_sumstats_assign_rsid.py` | `mysumstats.assign_rsid()` | Assign rsIDs from reference VCF/TSV |
| `gwaslab_sumstats_rsid_to_chrpos.py` | `mysumstats.rsid_to_chrpos()` | Assign coordinates from rsIDs via HDF5/VCF |
| `gwaslab_sumstats_check_af.py` | `mysumstats.check_af()` | Check DAF difference vs reference VCF |
| `gwaslab_sumstats_infer_af.py` | `mysumstats.infer_af()` | Infer EAF from reference VCF |
| `gwaslab_sumstats_to_format.py` | `mysumstats.to_format()` | Export to LDSC, PLINK, METAL, SSF, etc. |
| `gwaslab_sumstats_report.py` | `mysumstats.report()` | Generate complete HTML QC report |

#### Fix (`sumstats/fix/`)

| Script | GWASLab Method | Description |
| --- | --- | --- |
| `gwaslab_sumstats_fix_id.py` | `mysumstats.fix_id()` | Standardize SNPID and rsID formatting |
| `gwaslab_sumstats_fix_chr.py` | `mysumstats.fix_chr()` | Standardize chromosome notations |
| `gwaslab_sumstats_fix_pos.py` | `mysumstats.fix_pos()` | Validate genomic base-pair positions |
| `gwaslab_sumstats_fix_allele.py` | `mysumstats.fix_allele()` | Validate and uppercase allele strings |
| `gwaslab_sumstats_remove_dup.py` | `mysumstats.remove_dup()` | Deduplicate variants and multi-allelic sites |
| `gwaslab_sumstats_check_sanity.py` | `mysumstats.check_sanity()` | Check statistics against reasonable ranges |
| `gwaslab_sumstats_check_data_consistency.py` | `mysumstats.check_data_consistency()` | Check consistency among related statistics |
| `gwaslab_sumstats_normalize_allele.py` | `mysumstats.normalize_allele()` | Normalize indel representations |
| `gwaslab_sumstats_flip_snpid.py` | `mysumstats.flip_snpid()` / `strip_snpid()` | Flip or strip SNPID strings |

#### Filter (`sumstats/filter/`)

| Script | GWASLab Method | Description |
| --- | --- | --- |
| `gwaslab_sumstats_filter_value.py` | `mysumstats.filter_value()` | Filter variants using query expressions |
| `gwaslab_sumstats_filter_in_out.py` | `mysumstats.filter_in()` / `filter_out()` | Filter in/out by column thresholds |
| `gwaslab_sumstats_filter_region.py` | `mysumstats.filter_region()` / `exclude_hla()` | Region, BED, and HLA filtering |
| `gwaslab_sumstats_filter_variant_types.py` | `mysumstats.filter_snp()` / `filter_indel()` / `filter_palindromic()` / `filter_hapmap3()` | Filter by variant type (SNP, indel, palindromic, HM3) |
| `gwaslab_sumstats_search.py` | `mysumstats.search()` / `filter_flanking()` / `random_variants()` / `get_proxy()` | Search variants, extract flanking windows, or find LD proxies |

#### Downstream (`sumstats/downstream/`)

| Script | GWASLab Method | Description |
| --- | --- | --- |
| `gwaslab_sumstats_get_lead.py` | `mysumstats.get_lead()` | Extract lead variants with sliding window |
| `gwaslab_sumstats_get_top.py` | `mysumstats.get_top()` / `get_novel()` / `get_density()` | Extract top variants, GWAS Catalog novel variants, or density |
| `gwaslab_sumstats_anno_gene.py` | `mysumstats.anno_gene()` | Annotate nearest gene names |
| `gwaslab_sumstats_get_per_snp_r2.py` | `mysumstats.get_per_snp_r2()` / `get_ess()` | Calculate per-SNP R2, F-stats, and effective N |
| `gwaslab_sumstats_get_gc.py` | `mysumstats.get_gc()` | Calculate Genomic Inflation Factor (Lambda GC) |
| `gwaslab_sumstats_infer_ancestry.py` | `mysumstats.infer_ancestry()` | Infer ancestry using Fst comparisons |
| `gwaslab_sumstats_abf_finemapping.py` | `mysumstats.abf_finemapping()` | Approximate Bayes Factor fine-mapping |
| `gwaslab_sumstats_clump.py` | `mysumstats.clump()` | PLINK2-based LD clumping |
| `gwaslab_sumstats_ldsc.py` | `mysumstats.estimate_h2_by_ldsc()` / `estimate_rg_by_ldsc()` | Heritability (h2) and genetic correlation (rg) via LDSC |

### Plotting CLI Scripts

This Docker image includes dedicated command-line plotting wrappers located in `/opt/` (and on `PATH`):

| Script | GWASLab function | Description |
| --- | --- | --- |
| `gwaslab_plot_mqq.py` | `mysumstats.plot_mqq()` | Manhattan, QQ, Manhattan-QQ, regional, and Brisbane density plots |
| `gwaslab_plot_compare_effect.py` | `gl.compare_effect()` | Compare effect sizes between two GWAS datasets |
| `gwaslab_plot_miami2.py` | `gl.plot_miami2()` | Mirrored Manhattan (Miami) plot comparing two traits |
| `gwaslab_plot_forest.py` | `gl.plot_forest()` | Forest plot for meta-analysis study effects |
| `gwaslab_plot_ld_block.py` | `gl.plot_ld_block()` | Inverted triangular LD matrix plot |
| `gwaslab_plot_lead_overlap.py` | `gl.plot_lead_overlap()` | Venn / UpSet diagram of lead variant overlap across studies |
| `gwaslab_plot_power.py` | `gl.plot_power()` / `gl.plot_power_x()` | Theoretical GWAS power curves (quantitative or binary) |
| `gwaslab_plot_rg.py` | `gl.plot_rg()` | Genetic correlation heatmap from LDSC results |
| `gwaslab_plot_sankey.py` | `gl.plot_sankey()` | Sankey / alluvial diagram across categorical columns |
| `gwaslab_plot_scatter.py` | `gl.scatter()` | Scatter plot comparing two sumstats columns |
| `gwaslab_plot_stacked_mqq.py` | `gl.plot_stacked_mqq()` | Multi-study stacked Manhattan / QQ / regional panels |
| `gwaslab_plot_trumpet.py` | `mysumstats.plot_trumpet()` | Trumpet plot (MAF vs effect size with power curves) |
| `gwaslab_plot_phenogram.py` | `mysumstats.plot_phenogram()` | Karyotype-style phenogram plot with cytobands |
| `gwaslab_plot_daf.py` | `mysumstats.plot_daf()` | Allele frequency comparison (DAF/EAF vs RAF) |
| `gwaslab_plot_gwheatmap.py` | `mysumstats.plot_gwheatmap()` | Genome-wide association heatmap |
| `gwaslab_plot_effect.py` | `mysumstats.plot_effect()` | Effect sizes with optional EAF/SNPR2 side panels |
| `gwaslab_plot_pipcs.py` | `mysumstats.plot_pipcs()` | Fine-mapping credible sets and PIP regional plot |
| `gwaslab_plot_associations.py` | `mysumstats.plot_associations()` | Trait association heatmap |
| `gwaslab_sumstats_ldsc.py` | `mysumstats.estimate_h2_by_ldsc()` / `estimate_rg_by_ldsc()` | Heritability (h2) and genetic correlation (rg) via LDSC |

### Reference Data CLI Scripts (`reference/`)

| Script | GWASLab Function | Description |
| --- | --- | --- |
| `gwaslab_download_ref.py` | `gl.download_ref()` | Download reference files (HapMap3, 1000G, FASTA, chain, etc.) |
| `gwaslab_get_path.py` | `gl.get_path()` | Retrieve local path for reference keyword identifier |
| `gwaslab_check_format.py` | `gl.check_format()` | Inspect predefined header mappings for GWAS format presets |
| `gwaslab_download_sumstats.py` | `gl.download_sumstats()` | Download GWAS Catalog summary statistics by GCST accession |
| `gwaslab_get_power.py` | `gl.get_power()` | Calculate statistical power for association studies |

### I/O CLI Scripts (`io/`)

| Script | GWASLab Function | Description |
| --- | --- | --- |
| `gwaslab_read_ldsc.py` | `gl.read_ldsc()` | Parse LDSC heritability (`h2`) and genetic correlation (`rg`) outputs |
| `gwaslab_load_pickle.py` | `gl.load_pickle()` | Load GWASLab object from pickle and export |
| `gwaslab_load_gsf.py` | `gl.load_gsf()` | Load GWAS sumstats from GSF format with predicate pushdown |
| `gwaslab_read_gtf.py` | `gl.read_gtf()` | Fast GTF gene annotation file parser and filter |
| `gwaslab_read_bed.py` | `gl.read_bed()` | Read and parse genomic BED interval files |

#### CLI Example

```bash
docker run --rm -v /path/to/data:/data rtibiocloud/gwaslab:v4.2.2 \
    gwaslab_plot_mqq.py \
        --sumstats /data/gwas_summary_stats.tsv.gz \
        --mode mqq \
        --sig_level 5e-8 \
        --anno \
        --out /data/manhattan_qq.png
```

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
