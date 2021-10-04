# Select top PCs
The genotype PCA is performed to identify the PCs to include in the model. 
These PCs are the non-residual phenotypic variance explained by the genotype PCs.
This script selects the PCs that explain at least 75% of the phenotypic variance. 
It is common to run this analysis prior to GWAS.


**INPUT:** 
* phenotype file, (2) 
* Top 10 PCs (from eigenstrat for example)

**OUTPUT:** 
* phenotype file with top PCs appended
* PVE Plot

<br>

---

**Sample of phenotype file format**
```
fid iid hivstat gwassex age
245@1064714500_245@1064714500 245@1064714500_245@1064714500 1 1 26
266@1064714555_266@1064714555 266@1064714555_266@1064714555 1 1 48
```

<br>

**Sample of PC file format**
```
FID IID EV1 EV2 EV3 EV4 EV5 EV6 EV7 EV8 EV9 EV10
245@1064714500_245@1064714500 245@1064714500_245@1064714500 0.0051 0.0026 0.0015 -0.0010 -0.0012 0.0029 0.0037 -0.0005 -0.0023 0.0001
266@1064714555_266@1064714555 266@1064714555_266@1064714555 -0.0083 0.0020 0.0079 0.0101 -0.0009 0.0026 0.0166 0.0162 0.0221 0.0075
```
Notice the PC file must have the same list of fid and iid as the phenotype file.


<br><br>

<details>
  <summary>sample code</summary>
  
  ```bash
  an=eur
docker run -it -v $PWD:/data/ \
    rtibiocloud/select_pcs:v1_54156ec Rscript /opt/select_pcs.R \
        --file_in_pheno /data/uhs1234_${an}_hivstat_gwassex_age_fid_iid_1_2.txt \
        --file_in_pcs /data/${an}_ld_pruned_top10_eigenvecs_fid_iid.txt \
        --pheno_name "hivstat" \
        --model_type "logistic" \
        --coded_12 \
        --ancestry $an \
        --pve_threshold 75 \
        --file_out_pheno /data/uhs1234_${an}_hivstat_gwassex_age_pcs.txt \
        --file_out_prefix /data/uhs1234_${an}_hivstat_gwassex_age_pcs
  ```
  </details>
  
