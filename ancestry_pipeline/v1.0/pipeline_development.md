<details>
<summary>Outline</summary>

1. Extract 1000G LD-pruned variants from gVCF and convert IDs
2. Convert dataset vcf to bfile
3. Get ref samples based on POP/SUPERPOP & get variants overlapping with dataset
4. Add pop IDs to dataset & ref
5. Merge
6. Prepare smartpca files
7. Run smartpca
8. Process smartpca results
9. Run assign_ancestry_mahalanobis.R
 
</details>


<details>
<summary>Test ancestry_pipeline.py</summary>

``` shell
python3 /mnt/git/biocloud_docker_tools/ancestry_pipeline/run_pipeline.py \
    --pipeline_config /mnt/git/biocloud_docker_tools/ancestry_pipeline/ancestry_pipeline_config.json \
    --pipeline_arguments /mnt/data/temp/t1d/ancestry_pipeline_test.json
```
</summary>


<details>
<summary>Pipeline development</summary>

```shell
# Get variants from dataset
perl /rti-01/ngaddis/git/biocloud_docker_tools/ancestry_pipeline/v1.0/scripts/get_ref_variants_from_dataset_gvcf.pl \
    --file_in_gvcf /home/merge-shared-folder/testing/genedx/gvcfs/2841201.hard-filtered.gvcf.gz \
    --file_in_ref_bim /home/merge-shared-folder/ref/grch37/all_phase3_autosomes_maf_gt_1pct_grch37_dbsnp_b153.bim \
    --file_out_prefix /home/merge-shared-folder/testing/genedx/get_ref_variants_from_dataset_gvcf/2841201 \
    --monomorphic_positions include \
    --pass_only 1

perl /rti-01/ngaddis/git/biocloud_docker_tools/ancestry_pipeline/v1.0/scripts/get_ref_variants_from_dataset_gvcf.pl \
    --file_in_gvcf /home/merge-shared-folder/testing/genedx/gvcfs/2841201.hard-filtered.gvcf.gz \
    --file_in_ref_bim /home/merge-shared-folder/ref/grch37/all_phase3_autosomes_maf_gt_1pct_grch37_dbsnp_b153.bim \
    --file_out_prefix /home/merge-shared-folder/testing/genedx/get_ref_variants_from_dataset_gvcf/2841201 \
    --monomorphic_positions include \
    --pass_only 1 \
    --filter_by_gq 1


# Convert dataset vcf to bfile
docker run -ti -v ~:/mnt --rm rtibiocloud/plink:v2.0_c6004f7 bash
plink2 \
    --vcf /mnt/temp/t1d/PFNA12878.hard-filtered.vcf \
    --make-bed \
    --out /mnt/temp/t1d/PFNA12878.hard-filtered \
    --threads 8
exit

# Get ref samples
perl ~/git/biocloud_docker_tools/ancestry_pipeline/get_ref_samples.pl \
    --file_in_psam ~/data/rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/phase3_orig.psam \
    --pop_type SUPERPOP \
    --ancestries_to_include AFR,AMR,EAS,EUR,SAS \
    --file_out_ancestry_id_xref ~/data/temp/t1d/ancestry_id_xref.tsv \
    --file_out_ref_samples ~/data/temp/t1d/ref_samples.tsv

# Add pop IDs to fam files
perl ~/git/biocloud_docker_tools/ancestry_pipeline/add_pop_ids_to_fam_files.pl \
    --file_in_dataset_fam ~/temp/t1d/PFNA12878.hard-filtered.fam \
    --file_in_ref_fam ~/data/rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/all_phase3_unique_grch37_dbsnp_b153.fam \
    --file_in_ref_samples ~/data/temp/t1d/ref_samples.tsv \
    --file_out_dataset_fam ~/temp/t1d/PFNA12878.hard-filtered_with_pop_id.fam \
    --file_out_ref_fam ~/temp/t1d/all_phase3_unique_grch37_dbsnp_b153_with_pop_ids.fam

# Extract samples and variants to merge from ref
docker run -ti -v ~:/mnt --rm rtibiocloud/plink:v2.0_c6004f7 bash
plink2 \
    --bed /mnt/data/rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/all_phase3_unique_grch37_dbsnp_b153.bed \
    --bim /mnt/data/rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/all_phase3_unique_grch37_dbsnp_b153.bim \
    --fam /mnt/temp/t1d/all_phase3_unique_grch37_dbsnp_b153_with_pop_ids.fam \
    --keep /mnt/temp/t1d/ref_samples.tsv \
    --extract /mnt/temp/t1d/PFNA12878.hard-filtered_variants.txt \
    --make-bed \
    --out /mnt/temp/t1d/all_phase3_unique_grch37_dbsnp_b153 \
    --threads 8
exit

# Merge
docker run -ti -v ~:/mnt --rm rtibiocloud/plink:v1.9-77ee25f bash
## Get merge conflicts
plink \
    --bfile /mnt/temp/t1d/all_phase3_unique_grch37_dbsnp_b153 \
    --bmerge /mnt/temp/t1d/PFNA12878.hard-filtered.bed \
        /mnt/temp/t1d/PFNA12878.hard-filtered.bim \
        /mnt/temp/t1d/PFNA12878.hard-filtered_with_pop_id.fam \
    --merge-mode 7 \
    --make-bed \
    --out /mnt/temp/t1d/merge_conflicts \
    --threads 8

## Flip
plink \
    --bfile /mnt/temp/t1d/all_phase3_unique_grch37_dbsnp_b153 \
    --make-bed \
    --flip /mnt/temp/t1d/merge_conflicts.missnp \
    --out /mnt/temp/t1d/all_phase3_unique_grch37_dbsnp_b153_flipped \
    --threads 8

## Merge
plink \
    --bfile /mnt/temp/t1d/all_phase3_unique_grch37_dbsnp_b153_flipped \
    --bmerge /mnt/temp/t1d/PFNA12878.hard-filtered.bed \
        /mnt/temp/t1d/PFNA12878.hard-filtered.bim \
        /mnt/temp/t1d/PFNA12878.hard-filtered_with_pop_id.fam \
    --make-bed \
    --allow-no-sex \
    --out /mnt/temp/t1d/ref_dataset_merged \
    --threads 8
exit

# Prepare files for smartpca
perl ~/git/biocloud_docker_tools/ancestry_pipeline/prepare_smartpca_input.pl \
    --file_in_bed ~/data/temp/t1d/ref_dataset_merged.bed \
    --file_in_bim ~/data/temp/t1d/ref_dataset_merged.bim \
    --file_in_fam ~/data/temp/t1d/ref_dataset_merged.fam \
    --file_in_pop_id_xref ~/data/temp/t1d/ancestry_id_xref.tsv \
    --dataset_name T1D \
    --ref_pops AFR,AMR,EAS,EUR,SAS \
    --file_out_prefix ~/data/temp/t1d/ref_dataset_merged_smartpca \
    --threads 8

# Run smartpca
docker run -ti -v ~/data:/data --rm rtibiocloud/eigensoft:v6.1.4_2d0f99b bash
smartpca -p /data/temp/t1d/ref_dataset_merged_smartpca_par.txt > ref_dataset_merged_smartpca.log

# Process smartpca results
perl ~/git/biocloud_docker_tools/ancestry_pipeline/process_smartpca_results.pl \
    --file_in_evec ~/data/temp/t1d/ref_dataset_merged_smartpca.evec \
    --file_in_eval ~/data/temp/t1d/ref_dataset_merged_smartpca.eval \
    --file_in_snpweight ~/data/temp/t1d/ref_dataset_merged_smartpca.snpweight \
    --file_in_bim_id_xref ~/data/temp/t1d/ref_dataset_merged_smartpca_bim_xref.tsv \
    --file_in_fam_id_xref ~/data/temp/t1d/ref_dataset_merged_smartpca_fam_xref.tsv \
    --file_out_prefix ~/data/temp/t1d/ref_dataset_merged_smartpca

# Run assign_ancestry_mahalanobis
docker run -ti -v /rti-01/ngaddis/data:/data --rm rtibiocloud/assign_ancestry_mahalanobis:v1_6207f45 bash
Rscript /mnt/git/biocloud_docker_tools/ancestry_pipeline/assign_ancestry_mahalanobis.R \
    --file-pcs /mnt/data/temp/t1d/process_smartpca_results/dataset_ref_smartpca_evec.tsv \
    --pc-count 10 \
    --dataset PFNA12878 \
    --dataset-legend-label PFNA12878 \
    --ref-pops AFR,AMR,EAS,EUR,SAS \
    --ref-pops-legend-labels AFR,AMR,EAS,EUR,SAS \
    --out-dir /mnt/data/temp/t1d/assign_ancestry_mahalanobis \
    --use-pcs-count 10 \
    --midpoint-formula "median" \
    --std-dev-cutoff 3

# Run get_ancestry_assignment
perl /rti-01/ngaddis/git/biocloud_docker_tools/ancestry_pipeline/get_ancestry_assignment.pl \
    --file_in_raw_ancestry_assignment /rti-01/ngaddis/data/temp/t1d_test/assign_ancestry_mahalanobis/PFNA12878_raw_ancestry_assignments.tsv \
    --file_out_ancestry_assignment /rti-01/ngaddis/data/temp/t1d_test/ancestry_assignment.txt
```
</details>


<details>
<summary>Test assign_ids_to_dataset_variants.pl</details>

``` bash
/rti-01/ngaddis/git/biocloud_docker_tools/ancestry_pipeline/v1.0/dependencies/assign_ids_to_dataset_bim.pl \
    --file_in_dataset_bim /shared/ngaddis/data/temp/test.bim \
    --file_in_ref_bim /shared/ngaddis/data/rti-bioinformatics-resources/wf_inputs/biocloud_docker_tools/ancestry_pipeline/v1/grch37/all_phase3_ld_pruned_autosomes_grch37_dbsnp_b153.bim \
    --file_out_dataset_bim /shared/ngaddis/data/temp/test_updated.bim \
    --file_out_extract_list /shared/ngaddis/data/temp/test.extract
```
</details>


<details>
<summary>Test get_ref_files.py</details>

``` bash
aws_acct=code
aws_access_key_id=$(perl -ane 'BEGIN {$take = 0;} if ($F[0] =~ /'$aws_acct'/) { $take = 1; } if ($take && $F[0] =~ /aws_access_key_id/) { print $F[2]; $take = 0; }' ~/.aws/credentials)
aws_secret_access_key=$(perl -ane 'BEGIN {$take = 0;} if ($F[0] =~ /'$aws_acct'/) { $take = 1; } if ($take && $F[0] =~ /aws_secret_access_key/) { print $F[2]; $take = 0; }' ~/.aws/credentials)
python3 /rti-01/ngaddis/git/biocloud_docker_tools/ancestry_pipeline/v1.0/scripts/get_ref_files.py \
    --genome_build grch37 \
    --ref_panel 1000g \
    --aws_access_key $aws_access_key_id \
    --aws_secret_access_key $aws_secret_access_key \
    --target_dir /shared/ngaddis/temp/1000g/

```
</details>