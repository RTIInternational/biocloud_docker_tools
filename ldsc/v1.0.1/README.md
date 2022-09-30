# LD Score Regression (LDSC)
GitHub page: [ldsc](https://github.com/bulik/ldsc)<br>
[FAQ](https://github.com/bulik/ldsc/wiki/FAQ)

<br>

## Automated Workflow
[RTIInternational/ld-regression-pipeline](https://github.com/RTIInternational/ld-regression-pipeline) 

<br><br>

## Example Code
### h2 estimate and ldsc intercept
Also see the TL;DR section in [Heritability and Genetic Correlation](https://github.com/bulik/ldsc/wiki/Heritability-and-Genetic-Correlation).

<details>
  <summary>expand code</summary>
  
```
# start interactive session
docker run -it -v $PWD:/data/ \
    rtibiocloud/ldsc:v1.0.1_0bb574e /bin/bash

# Download data
cd /data/
wget https://data.broadinstitute.org/alkesgroup/LDSCORE/eur_w_ld_chr.tar.bz2
wget https://data.broadinstitute.org/alkesgroup/LDSCORE/w_hm3.snplist.bz2
tar -jxvf eur_w_ld_chr.tar.bz2
bunzip2 w_hm3.snplist.bz2

# Munge data
/opt/ldsc/munge_sumstats.py \
	--sumstats meta_results.txt \
	--N 17314 \
	--out meta_munged \
	--merge-alleles w_hm3.snplist

# calculate h2 estimate and ldsc intercept 
/opt/ldsc/ldsc.py \
	--h2 meta_munged.sumstats.gz \
	--ref-ld-chr eur_w_ld_chr/ \
	--w-ld-chr eur_w_ld_chr/ \
	--out meta_h2
```
</details>

<br>

### LDSC-SEG
LDSC regression applied to specifically expressed genes (LDSC-SEG).
The code below was used in [this analysis in GitHub issue 166](https://github.com/RTIInternational/bioinformatics/issues/166#issuecomment-816057301).

<details>
  <summary>expand code</summary>

```bash
# interactive session
docker run -it -v $PWD:/data/ \
    rtibiocloud/ldsc:v1.0.1_0bb574e bash

window=100000
for fdr in {"0.05","0.10"}; do # loop through each BED file
    coord_file=/data/deg_bedfiles/meta_analysis_sumstats_no_singletons_20220727_fdr${fdr}_coord.tsv 
    geneset_file=/data/deg_bedfiles/meta_analysis_sumstats_no_singletons_20220727_fdr${fdr}_geneset.tsv

    # store processing files for each meta in separate dir
    mkdir -p /data/{annotations_ldscores,results}/fdr$fdr/

    for j in {1..22}; do # loop through each chromosome
        python /opt/ldsc/make_annot.py \ # create annotation files
            --gene-set-file $geneset_file \
            --gene-coord-file $coord_file \
            --windowsize $window \
            --bimfile /data/1000g/1000G_EUR_Phase3_plink/1000G.EUR.QC.$j.bim \
            --annot-file /data/annotations_ldscores/fdr$fdr/oa_twas_meta_fdr${fdr}genes_window${window}_chr$j.annot.gz

        python /opt/ldsc/ldsc.py \ # compute LD scores
            --l2 \
            --thin-annot \
            --ld-wind-cm 1 \
            --print-snps /data/1000g/1000G_EUR_Phase3_baseline/print_snps.txt \
            --bfile /data/1000g/1000G_EUR_Phase3_plink/1000G.EUR.QC.$j \
            --annot /data/annotations_ldscores/fdr$fdr/oa_twas_meta_fdr${fdr}genes_window${window}_chr$j.annot.gz \
            --out /data/annotations_ldscores/fdr$fdr/oa_twas_meta_fdr${fdr}genes_window${window}_chr$j
    done # end chr loop


    for trait in {"age_of_initiation","alcohol_dependence","drinks_per_week","alzheimers_disease","als","anorexia","adhd","autism","bipolar","cannabus_use_disorder","cigarettes_per_day","cotinine_levels","depressive_symptoms","ftnd","heaviness_smoking_index","lifetime_cannabis_use","major_depressive_disorder","neuroticism","opioid_addiction_gsem","parkinsons","ptsd","schizophrenia","smoking_cessation","smoking_initiation"}; do  # loop through all traits
        case $trait in  # use sumstats files that corresponds to the trait name for the h2 estimate
        
            "age_of_initiation") stats=/data/sumstats/AgeOfInitiation.txt.munged.merged.txt.gz ;;
            "alcohol_dependence") stats=/data/sumstats/pgc_alcdep.eur_discovery.aug2018_release.txt.munged.merged.txt.gz ;;
            "drinks_per_week") stats=/data/sumstats/DrinksPerWeek.txt.munged.merged.txt.gz ;;
            "alzheimers_disease") stats=/data/sumstats/alzheimers_disease_lambert2013_nat_genet.sumstats.gz ;;
            "als") stats=/data/sumstats/amyotrophic_lateral_sclerosis_rheenen2016_nat_genet.sumstats.gz ;;
            "anorexia") stats=/data/sumstats/anorexia_watson2019_workflow_ready.txt.munged.merged.txt.gz ;;
            "adhd") stats=/data/sumstats/daner_meta_filtered_NA_iPSYCH23_PGC11_sigPCs_woSEX_2ell6sd_EUR_Neff_70.meta.munged.merged.txt.gz ;;
            "autism") stats=/data/sumstats/iPSYCH-PGC_ASD_Nov2017.munged.merged.txt.gz ;;
            "bipolar") stats=/data/sumstats/daner_PGC_BIP32b_mds7a_0416a.munged.merged.txt.gz ;;
            "cannabis_use_disorder") stats=/data/sumstats/CUD_GWAS_iPSYCH_June2019.munged.merged.txt.gz ;;
            "cigarettes_per_day") stats=/data/sumstats/CigarettesPerDay.txt.munged.merged.txt.gz ;;
            "cotinine_levels") stats=/data/sumstats/cotinine_ware2016_workflow_ready.txt.munged.merged.txt.gz ;;
            "depressive_symptoms") stats=/data/sumstats/DS_Full.txt.munged.merged.txt.gz ;;
            "ftnd") stats=/data/sumstats/ftnd_wave3_eur_quach2020_workflow_ready.txt.munged.merged.txt.gz ;;
            "heaviness_smoking_index") stats=/data/sumstats/ukb_gwa_003_workflow_ready.txt.munged.merged.txt.gz ;;
            "lifetime_cannabis_use") stats=/data/sumstats/cannabis_icc_ukb_workflow_ready.txt.munged.merged.txt.gz ;;
            "major_depressive_disorder") stats=/data/sumstats/pgc_ukb_depression_gwas_workflow_ready.txt.munged.merged.txt.gz ;;
            "neuroticism") stats=/data/sumstats/neuroticism_okbay2016_nat_genet.sumstats.gz ;;
            "opioid_addiction_gsem") stats=/data/sumstats/genomicSEM_GWAS.oaALL.MVP1_MVP2_YP_SAGE.PGC.Song.table.sumstats.gz ;;
            "parkinsons") stats=/data/sumstats/parkinsons_disease_sanchez2009_nat_genet.sumstats.gz ;;
            "ptsd") stats=/data/sumstats/pts_eur_freeze2_overall.results.munged.merged.txt.gz ;;
            "schizophrenia") stats=/data/sumstats/daner_natgen_pgc_eur.munged.merged.txt.gz ;;
            "smoking_cessation") stats=/data/sumstats/SmokingCessation.txt.munged.merged.txt.gz ;;
            "smoking_initiation") stats=/data/sumstats/SmokingInitiation.txt.munged.merged.txt.gz ;;
        esac

        # computed partitioned heritability estimate
        python /opt/ldsc/ldsc.py \
            --h2 $stats \
            --overlap-annot \
            --print-coefficients \
            --w-ld-chr "/data/weights_hm3_no_hla/weights." \
            --frqfile-chr "/data/1000g/1000G_Phase3_frq/1000G.EUR.QC." \
            --ref-ld-chr "/data/annotations_ldscores/fdr$fdr/oa_twas_meta_fdr${fdr}genes_window${window}_chr,/data/1000g/1000G_EUR_Phase3_baseline/baseline." \
            --out "/data/results/fdr$fdr/${trait}_with_oa_twas_meta_analysis_deg_genes_fdr${fdr}_window${window}"
    done # end trait loop
done # end DEG loop
```
	
combine results
```bash
for fdr in {"0.05","0.10"}; do
    outfile=fdr${fdr}/all_phenotypes_oa_twas_meta_analysis_deg_fdr${fdr}_window100000_final_results.tsv
    touch $outfile
    head -1 fdr${fdr}/smoking_initiation_with_oa_twas_meta_analysis_deg_genes_fdr${fdr}_window100000.results > $outfile
        
    for file in   fdr${fdr}/*_fdr${fdr}_window100000.results; do
        trait=$(echo $file |  sed "s/_with_oa_twas_meta_analysis_deg_genes_fdr.*//") # remove suffix
        trait=$(echo $trait |  sed "s/fdr$fdr\///") # remove directory prefix
        #echo $trait
        awk -v trait=$trait \
        '$1 = trait {print $0}' OFS="\t" <(tail -n +2 $file | head -1) >> $outfile
    done
done
```	
  </details>

<br><br>

## Relevant Papers
* [Bulik-Sullivan, et al. LD Score Regression Distinguishes Confounding from Polygenicity in Genome-Wide Association Studies. Nature Genetics, 2015.](http://www.nature.com/ng/journal/vaop/ncurrent/full/ng.3211.html)
* [Finucane, HK, et al. Partitioning heritability by functional annotation using genome-wide association summary statistics. Nature Genetics, 2015.](https://www.nature.com/articles/ng.3404)
* [Finucane, HK, et al. Heritability enrichment of specifically expressed genes identifies disease-relevant tissues and cell types. Nature Genetics, 2018.](https://www.nature.com/articles/s41588-018-0081-4)
