# LD Score Regression (LDSC) — CBIIT Python 3 fork
GitHub page: [CBIIT/ldsc](https://github.com/CBIIT/ldsc) (`main` branch, pinned to commit `1f09cf0`)<br>
[FAQ](https://github.com/bulik/ldsc/wiki/FAQ)

This image builds CBIIT/NCI's actively maintained Python 3 fork of the original `bulik/ldsc`, directly from the upstream repo, pinned to a fixed commit. It's the same engine behind [ldlink.nih.gov/ldscore](https://ldlink.nih.gov/ldscore).

<br>

## Example Code
### h2 estimate and ldsc intercept

<details>
  <summary>expand code</summary>

```bash
# start interactive session
docker run -it -v $PWD:/data/ \
    rtibiocloud/ldsc39:v1 /bin/bash

# Download reference data
cd /data/
wget https://data.broadinstitute.org/alkesgroup/LDSCORE/eur_w_ld_chr.tar.bz2
wget https://data.broadinstitute.org/alkesgroup/LDSCORE/w_hm3.snplist.bz2
tar -jxvf eur_w_ld_chr.tar.bz2
bunzip2 w_hm3.snplist.bz2

# Munge summary statistics
/opt/ldsc/munge_sumstats.py \
	--sumstats meta_results.txt.gz \
	--N 17314 \
	--out meta_munged \
	--merge-alleles w_hm3.snplist

# Calculate h2 estimate and ldsc intercept
/opt/ldsc/ldsc.py \
	--h2 meta_munged.sumstats.gz \
	--ref-ld-chr eur_w_ld_chr/ \
	--w-ld-chr eur_w_ld_chr/ \
	--out meta_h2
```
</details>

<br>

## Relevant Papers
* [Bulik-Sullivan, et al. LD Score Regression Distinguishes Confounding from Polygenicity in Genome-Wide Association Studies. Nature Genetics, 2015.](http://www.nature.com/ng/journal/vaop/ncurrent/full/ng.3211.html)
* [Finucane, HK, et al. Partitioning heritability by functional annotation using genome-wide association summary statistics. Nature Genetics, 2015.](https://www.nature.com/articles/ng.3404)
* [LDlink/LDscore preprint, bioRxiv, 2025.](https://www.biorxiv.org/content/10.64898/2025.12.19.695639v2)

<br>

## Contact
Jesse Marks (jmarks@rti.org)
