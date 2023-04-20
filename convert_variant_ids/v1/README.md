# Description

This Docker image converts genetic variant IDs in input files to a different reference genome using a reference file. 
It can be used in conjunction with the following WDL workflow: 
https://github.com/RTIInternational/biocloud_gwas_workflows/blob/master/helper_workflows/convert_variant_ids_wf.wdl

<br>


## Example
```python3
python convert_variant_ids.py \
  --in_file input_file.txt \
  --in_header 1 \
  --in_sep tab \
  --in_id_col 0 \
  --in_chr_col 1 \
  --in_pos_col 2 \
  --in_a1_col 3 \
  --in_a2_col 4 \
  --in_missing_allele NA \
  --in_deletion_allele DEL \
  --ref reference_file.txt \
  --ref_deletion_allele DEL \
  --chr 1 \
  --out_file output_file.txt \
  --log_file log.txt

```

<br>


## Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- Nathan Gaddis, email: ngaddis@rti.org
- Jesse Marks, email: jmarks@rti.org
