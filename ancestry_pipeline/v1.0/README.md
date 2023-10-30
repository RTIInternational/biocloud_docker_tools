<details>
<summary>Usage</summary>

``` shell
docker run 
```
</details>

# Prior to build, generate new presigned URLs for reference files in S3 using following code:
``` shell
aws s3 presign s3://rti-common/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bed --expires-in 172800
aws s3 presign s3://rti-common/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bim --expires-in 172800
aws s3 presign s3://rti-common/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.fam --expires-in 172800
aws s3 presign s3://rti-common/ancestry/smartpca_mahal_pipeline/1000g_variants.tsv --expires-in 172800
aws s3 presign s3://rti-common/ancestry/smartpca_mahal_pipeline/phase3_orig.psam --expires-in 172800
```