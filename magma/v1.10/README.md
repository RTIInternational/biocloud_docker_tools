# MAGMA
[MAGMA](https://ctg.cncr.nl/software/magma) is a tool for gene analysis and generalized gene-set analysis of GWAS data. It can be used to analyse both raw genotype data as well as summary SNP p-values from a previous GWAS or meta-analysis.

* [MAGMA manual (version 1.10) ](https://vu.data.surfsara.nl/index.php/s/MUiv3y1SFRePnyG)

<br>

## Example code
Data must be converted to build37, unless you have PLINK formatted genotype data in build 38.

<details>
    <summary>Create SNP Location File</summary>
    
```bash
infile=/home/ec2-user/rti-shared/gwas/phs000315_whi_garnet/results/uui/0001/minimac4_eagle2.4/topmed_r2/eur/biocloud_gwas_workflows/liftover_genomic_annotations/cromwell-executions/genome_liftover/f6a90825-fa7c-44fe-853f-552cab16c04f/call-final/execution/whi_garnet_c1c2_eur.rvtests.MetaAssoc.rsq.0.8.sampleMAF.0.01.hg19.tsv.gz
outfile=/home/ec2-user/rti-shared/gwas/phs000315_whi_garnet/results/uui/0001/minimac4_eagle2.4/topmed_r2/eur/magma/input/whi_garnet_c1c2_eur_snp_loc.tsv

# header
printf "SNP\tCHR\tBP\tP\tN\n" > $outfile

# VARIANT_ID CHR GRCh19_POS REF ALT ALT_AF MAF POP_MAF SOURCE IMP_QUAL N ALT_EFFECT SE P
zcat $infile | tail -n +2 |\
perl -lane ' print join("\t",$F[0],$F[1],$F[2], $F[13], $F[10]);' > tmp.txt
#perl -lane ' print join("\t",$F[0],$F[1],$F[2], $F[13], $F[10]);' >> $outfile


# make SNP IDs only rsID and not rsID:pos:A1:A2
# will cause issues because of a mismatch in SNP ID nomenclature between ref data and SNP p-value file 
awk ' {split($1,a,":") ;$1 = a[1]}  { print $0 }' OFS="\t" tmp.txt > tmp2.txt

# keep only variants with rsIDs
grep rs tmp2.txt >> $outfile

rm tmp*
```
</details>
    
    
    
    
    
<details>
    <summary>Annotate</summary>
    
Produces a file `[ANNOT_PREFIX].genes.annot`  containing the mapping of SNPs to genes.
  
```bash
# annotate with 100kb window
docker run -i -v $PWD:/data/ rtibiocloud/magma:v1.10_b95f665 \
/opt/magma \
    --annotate window=100 \
    --snp-loc /data/$snploc \
    --gene-loc /opt/NCBI37.3.gene.loc \
    --out /data/$outann
```
</details>
    
    
    
    
    
    
<details>
  <summary>Gene Analysis</summary>

Need a reference data set such as the 1,000 Genomes European panel (available on the MAGMA site).  
  
```bash
# The SNP locations in the data are in reference to human genome Build 37.
wget https://ctg.cncr.nl/software/MAGMA/ref_data/g1000_eur.zip
unzip g1000_eur.zip

# --gene-model snp-wise=mean is default for --pval runs
docker run -i -v $PWD:/data/ rtibiocloud/magma:v1.10_4bb4e51 \
/opt/magma \
    --genes-only \
    --bfile /data/g1000_eur \
    --pval /data/whi_garnet_c1c2_eur_snp_loc.tsv  ncol=N \
    --gene-annot /data/annotate_whi_garnet_c1c2_eur.genes.annot \
    --out /data/whi_garnet_c1c2_eur_gene_analysis
    #--gene-model multi \
#Reading file /data/g1000_eur.fam... 503 individuals read    
```
</details>



<details>
  <summary>Add gene symbols</summary>
  
```bash
infile=whi_garnet_c1c2_eur_gene_analysis.genes.out
outfile=$infile.gene_symbols_added.txt
head -n 1 $infile | awk '{print $0, "SYMBOL"}' > $outfile

# interactive mode
docker run -ti -v $PWD:/data/ rtibiocloud/magma:v1.10_b95f665 bash
cd /data/

infile=whi_garnet_c1c2_eur_gene_analysis.genes.out
outfile=$infile.gene_symbols_added.txt

# append gene symbol to outfil
awk 'FNR==NR{map[$1] = $6; next}
      { print $0, map[$1] }' /opt/NCBI37.3.gene.loc <(tail -n +2 $infile) >> $outfile
  
```  
</details>  
