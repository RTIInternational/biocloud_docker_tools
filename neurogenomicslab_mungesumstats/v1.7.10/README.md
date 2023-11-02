# Description

This Docker image is based on the [neurogenomics/MungeSumstats](https://github.com/neurogenomics/MungeSumstats/) image and is designed for rapid standardization and quality control of GWAS or QTL summary statistics.
The image includes a an additional R script called `neurogenomics_liftover.R` which is used in the [RTI International Biocloud GWAS Workflows](https://github.com/RTIInternational/biocloud_gwas_workflows/tree/master/liftover_genomic_annotations) to perform genomic liftovers.

<br>

## Usage

You can use this Docker image as a stand-alone tool by running the following command:

```bash
docker run -i rtibiocloud/neurogenomicslab_mungesumstats:1.7.10_3d50aed Rscript /opt/neurogenomics_liftover.R \
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

For more information on how to use the image and its available options, refer to the [liftover documentation](https://neurogenomics.github.io/MungeSumstats/reference/liftover.html).

<br>

## Contact

For questions or inquiries about this Docker image, please contact Jesse Marks at jmarks@rti.org.
