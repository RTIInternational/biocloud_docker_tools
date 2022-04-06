# Select top PCs
The genotype PCA is performed to identify the PCs to include in the model. 
These PCs are the non-residual phenotypic variance explained by the genotype PCs.
This script selects the PCs that explain at least 75% of the phenotypic variance. 
It is common to run this analysis prior to GWAS.


**INPUT:** 
* phenotype file (in [RVTESTS format](https://github.com/zhanxw/rvtests#phenotype-file))
* top 10 PCs file (from eigenstrat, see output from [genotype_pca workflow](https://github.com/RTIInternational/biocloud_gwas_workflows/tree/master/genotype_pca))

**OUTPUT:** 
* phenotype file with top PCs appended
* PVE Plot
* PVE analysis log file

<br>

---

**Sample of phenotype file format**
```
fid iid fatid matid sex uui age diabetes parity obesity
111142697 335368 0 0 2 2 52 1 2 1
111100359 248150 0 0 2 1 57 1 3 2
```

<br>

**Sample of PC file format**
```
fid iid PC1 PC2 PC3 PC4 PC5 PC6 PC7 PC8 PC9 PC10
111000103 391350 0.0031 -0.0048 -0.0011 0.0017 0.0006 0.0005 0.0005 0.0002 0.0007 0.0002
111000143 203913 0.0028 -0.0072 0.0006 -0.0006 -0.0010 -0.0016 0.0010 -0.0003 0.0028 0.0018
```
Notice the PC file must have the same list of fid and iid as the phenotype file, but not necessarily in the same order.


<br><br>

<details>
  <summary>sample code</summary><br>
  
  Notice the `--combine_fid_iid` flag. The TOPMed imputation server usually combines the fid and iid with an underscore. If this is the case for your imputed genotype data, and your phenotype data are not in this format, use this flag.
  
  ```bash
docker run -it -v $PWD:/data/ \
  rtibiocloud/select_pcs:v2_bbe9fa4 Rscript /opt/select_pcs.R \
      --file_in_pheno /data/without_pcs/20220401_final_uui_phenotype_without_pcs_rvtest_format.txt \
      --file_in_pcs /data/with_pcs/whi_garnet_c1c2_eur_ld_pruned_top10_pcs.txt \
      --pheno_name "uui" \
      --model_type "logistic" \
      --coded_12 \
      --ancestry "eur" \
      --pve_threshold 75 \
      --combine_fid_iid \
      --file_out_pheno /data/with_pcs/whi_garnet_c1c2_eur_uui_age_diabetes_parity_obesity_pcs_n3139.txt \
      --file_out_prefix /data/with_pcs/whi_garnet_c1c2_eur_uui
  ```
  There were three outputs with this command:
  * whi_garnet_c1c2_eur_uui_age_diabetes_parity_obesity_pcs_n3139.txt
  * whi_garnet_c1c2_eur_uui_pve.png
  * whi_garnet_c1c2_eur_uui.log

  
  This is the final phenotype file with the top PCs appended, a plot of the PCs, and a log file with the model ran and the PVE of the top PCs at the bottom.
  
  </details>
  
