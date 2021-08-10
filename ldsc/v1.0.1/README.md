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

# loop through all traits
for trait in {"hiv_acquisition","alzheimers_disease","amyotrophic_lateral_sclerosis","asthma","atopic_dermatitis","crohns_disease","inflammatory_bowel_disease","neuroticism","parkinsons_disease","platelet_count","primary_biliary_cirrhosis","primary_sclerosing_cholangitis","red_blood_cell_count","rheumatoid_arthritis","systemic_lupus_erythematosus","type2_diabetes","ulcerative_colitis","white_blood_cell_count"}; do

    # store processing files for each meta in separate dir
    mkdir -p /data/annotations_ldscores/${trait}/
    
    # use sumstats files that corresponds to the trait name for the h2 estimate
    case $trait in 
        "hiv_acquisition") stats=/data/sumstats/hiv_acquisition_gwas_meta_eur.sumstats.gz
        "alzheimers_disease")  stats=/data/sumstats/alzheimers_disease_lambert2013_nat_genet.sumstats.gz ;;
        "amyotrophic_lateral_sclerosis") stats=/data/sumstats/amyotrophic_lateral_sclerosis_rheenen2016_nat_genet.sumstats.gz ;;
        "asthma") stats=/data/sumstats/asthma_han2020_nat_commun.sumstats.gz ;;
        "atopic_dermatitis") stats=/data/sumstats/eczema_paternoster2015_nat_genet.sumstats.gz ;;
        "crohns_disease") stats=/data/sumstats/crohns_disease_liu2015_nat_genet.sumstats.gz ;;
        "inflammatory_bowel_disease") stats=/data/sumstats/inflammatory_bowel_disease_liu2015_nat_genet.sumstats.gz ;;
        "neuroticism") stats=/data/sumstats/neuroticism_okbay2016_nat_genet.sumstats.gz ;;
        "parkinsons_disease") stats=/data/sumstats/parkinsons_disease_sanchez2009_nat_genet.sumstats.gz ;;
        "platelet_count") stats=/data/sumstats/platelet_count_vuckovic2020_cell.sumstats.gz ;;
        "primary_biliary_cirrhosis") stats=/data/sumstats/PASS_Primary_biliary_cirrhosis.sumstats.gz ;;
        "primary_sclerosing_cholangitis") stats=/data/sumstats/primary_sclerosing_cholangitis_ji2017_nat_genet.sumstats.gz ;;
        "red_blood_cell_count") stats=/data/sumstats/red_blood_cell_count_vuckovic2020_cell.sumstats.gz ;;
        "rheumatoid_arthritis") stats=/data/sumstats/rheumatoid_arthritis_okada2014_nature.sumstats.gz ;;
        "systemic_lupus_erythematosus") stats=/data/sumstats/PASS_Lupus.sumstats.gz ;;
        "type2_diabetes") stats=/data/sumstats/type2_diabetes_xue2018_nat_commun.sumstats.gz ;;
        "ulcerative_colitis") stats=/data/sumstats/ulcerative_colitis_liu2015_nat_genet.sumstats.gz ;;
        "white_blood_cell_count") stats=/data/sumstats/white_blood_cell_count_vuckovic2020_cell.sumstats.gz ;;
    esac
    
    # loop through each BED file
    for window in {cis10k,cis100k,cis400k}; do
        case $window in
            cis10k) deg_file=/data/deg_bedfiles/hiv_status_vl_suppressed_degs_cis10k.bed.gz ;;
            cis100k) deg_file=/data/deg_bedfiles/hiv_status_vl_suppressed_degs_cis100k.bed.gz ;;
            cis400k) deg_file=/data/deg_bedfiles/hiv_status_vl_suppressed_degs_cis400k.bed.gz ;;
        esac 
        
        # loop through each chromosome
        for j in {1..22}; do
        
            # create annotation files
            python /opt/ldsc/make_annot.py \
                --bed-file $deg_file \
                --bimfile "/data/1000g/1000G_EUR_Phase3_plink/1000G.EUR.QC.$j.bim" \
                --annot-file "/data/annotations_ldscores/$trait/${trait}_degs_${window}.$j.annot.gz"

            # compute LD scores
            python /opt/ldsc/ldsc.py \
                --l2 \
                --bfile "/data/1000g/1000G_EUR_Phase3_plink/1000G.EUR.QC.$j" \
                --ld-wind-cm 1 \
                --annot "/data/annotations_ldscores/$trait/${trait}_degs_${window}.$j.annot.gz" \
                --thin-annot \
                --out "/data/annotations_ldscores/$trait/${trait}_degs_${window}.$j" \
                --print-snps "/data/1000g/1000G_EUR_Phase3_baseline/print_snps.txt"
        done # end chr loop
        
        # computed partitioned heritability estimate
        python /opt/ldsc/ldsc.py \
            --h2 $stats \
            --w-ld-chr "/data/1000g/weights_hm3_no_hla/weights." \
            --ref-ld-chr "/data/annotations_ldscores/$trait/${trait}_degs_${window}.,/data/1000g/1000G_EUR_Phase3_baseline/baseline." \
            --overlap-annot \
            --out "/data/results/${trait}_hiv_status_vl_suppressed_degs_${window}_results" \
            --print-coefficients \
            --frqfile-chr "/data/1000g/1000G_Phase3_frq/1000G.EUR.QC."
    
    done # end BED file loop
done # end trait file loop
```
  </details>

<br><br>

## Relevant Papers
* [Bulik-Sullivan, et al. LD Score Regression Distinguishes Confounding from Polygenicity in Genome-Wide Association Studies. Nature Genetics, 2015.](http://www.nature.com/ng/journal/vaop/ncurrent/full/ng.3211.html)
* [Finucane, HK, et al. Partitioning heritability by functional annotation using genome-wide association summary statistics. Nature Genetics, 2015.](https://www.nature.com/articles/ng.3404)
* [Finucane, HK, et al. Heritability enrichment of specifically expressed genes identifies disease-relevant tissues and cell types. Nature Genetics, 2018.](https://www.nature.com/articles/s41588-018-0081-4)
