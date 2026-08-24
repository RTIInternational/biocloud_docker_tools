for region in BLA CE NAC SFC; do       
docker run --rm \-v "/Users/cdwillis/OneDrive - Research Triangle Institute/AUD_CS_R01/multiomics-aud-cs/task/1_munging/0003/0001/tables:/scratch" bulk_rnaseq_qc:v1.0 \  Rscript bulk_rnaseq_quality_control.R \
  --multiqc_dir "/scratch/multiqc_output/" \
  --txi_rds "/scratch/merge_Mayfield_RNAseq_all_regions_20260727_salmon_dge_gene_data.rds" \
  --pheno_tsv "/scratch/Mayfield_NSWTRC_bulk_rnaseq_pheno_table_20260730_${region}.tsv" \
  --annotation_gtf "/scratch/gencode.v40.primary_assembly.annotation.gtf" \
  --output_dir "/scratch/" \
  --sample_id_col "Sample_Number" \
  --sex_col "Gender" \
  --run_name "Mayfield_NSW_TRC_RNAseq_${region}" \
  --group_vars "RIN,Age,Gender,Ethnicity,PM.,trimmomatic_dropped_pct" \
  --rin_col "RIN"
     