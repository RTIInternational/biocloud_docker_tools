# Description

This Docker image is based on the [neurogenomics/MungeSumstats](https://github.com/neurogenomics/MungeSumstats/) image and is designed for rapid standardization and quality control of GWAS or QTL summary statistics.
The image includes a an additional R script called `neurogenomics_liftover.R` which is used in the [RTI International Biocloud GWAS Workflows](https://github.com/RTIInternational/biocloud_gwas_workflows/tree/master/liftover_genomic_annotations) to perform genomic liftovers.

<br>

# Usage
## Docker

You can use this Docker image as a stand-alone tool by running the following command:

```bash
docker run -i rtibiocloud/neurogenomicslab_mungesumstats:1.7.10_6e16c82 Rscript /opt/neurogenomics_liftover.R \
    --file_name "~{file_name}" \
    --output_name "~{output_name}" \
    --sep "~{sep}" \
    --snp_name "~{snp_name}" \
    --chrom_name "~{chrom_name}" \
    --pos_name "~{pos_name}" \
    --ref_genome "~{ref_genome}" \
    --convert_ref_genome "~{convert_ref_genome}" \
    --chain_source "~{chain_source}"
```
* _be sure to use the latest tag_

<br>

## `neurogenomics_liftover.R` parameters

You can obtain the help message for the `neurogenomics_liftover.R` script by running the default command with your Docker image. When you run the following command:

```bash
docker run rtibiocloud/neurogenomicslab_mungesumstats:1.7.10_6e16c82
```

The output will display the help message for the script, providing information on its usage and available options:

```plaintext
usage: /opt/neurogenomics_liftover.R [-h] [--file_name FILE_NAME]
                                     [--output_name OUTPUT_NAME] [--sep SEP]
                                     [--snp_name SNP_NAME]
                                     [--chrom_name CHROM_NAME]
                                     [--pos_name POS_NAME]
                                     [--ref_genome REF_GENOME]
                                     [--convert_ref_genome CONVERT_REF_GENOME]
                                     [--chain_source CHAIN_SOURCE]

Convert summary statistics to a different reference genome

options:
  -h, --help            show this help message and exit
  --file_name FILE_NAME
                        Input file name
  --output_name OUTPUT_NAME
                        Output file name
  --sep SEP             Field separator: 'Tab', 'Comma', or 'Space'.
  --snp_name SNP_NAME   Name of SNP column
  --chrom_name CHROM_NAME
                        Name of chromosome column
  --pos_name POS_NAME   Name of position column
  --ref_genome REF_GENOME
                        Reference genome (e.g., GRCh37 or GRCh38)
  --convert_ref_genome CONVERT_REF_GENOME
                        Target reference genome (e.g., GRCh37 or GRCh38)
  --chain_source CHAIN_SOURCE
                        Source for chain files (ensembl or ucsc)
```

For more information on the liftover tool in general, refer to the [MungeSumstats liftover documentation](https://neurogenomics.github.io/MungeSumstats/reference/liftover.html).

<br>

## Contact

For questions or inquiries about this Docker image, please contact Jesse Marks at jmarks@rti.org.
