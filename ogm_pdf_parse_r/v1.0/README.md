# Optical Genome Mapping PDF Parser

This Dockerfile sets up an environment for running an [Rscript](v1.0/ogm_pdf_parse.R) that takes the PDF output from an optical genome mapping run on the [BioNano Saphyr Instrument](https://bionano.com/saphyr-systems/) and exports either a set of tab delimited files or an excel spreadsheet (1 row per sample).

## Overview

**Optical Genome Mapping**

Optical genome mapping uses high-resolution imaging to map the structure and organization of an organism's genome, providing insights into large-scale genomic variations and architecture.

For the Regenerative Medicine Innovation Project (RMIP), the In-Depth Cell Characterization Hub (IDCCH) uses a BioNano Saphyr instrument to perform optical genome mapping. This instrument detects and quantifies genomic variation including single nucleotide changes and structural (e.g., insertions, deletions, inversions, and complex) and copy number variations. The output of this process is a .VCF file and a standardized PDF file.

The purpose of this docker is to run an Rscript that will take the PDF outputs generated by the IDCCH, extract key values from the PDF and export a standardized, machine readable, set of tab delimited files or an excel spreadsheet.

<br>

## Usage
The following command can be used to run the docker: 
```
docker pull rtibiocloud/ogm_pdf_parse_r:<tagname>
docker run -it rtibiocloud/ogm_pdf_parse_r:<tagname> -c "Rscript /opt/parser/ogm_pdf_parse.R --help"
```

Example Docker run command with volume mounting:
```bash
docker run --rm -v ${PWD}:/data -w /data rtibiocloud/ogm_pdf_parse_r:<tagname> /bin/bash -c " Rscript /opt/parser/ogm_pdf_parse.R -i /data/example.pdf -p /data -o example.tsv -v"
```

If not running the docker from the directory with the data, replace `${PWD}` with the actual path on your host system with the PDF outputs.

<br>

## Build
To build this Docker image, you can use the following command:
```
docker build --rm -t rtibiocloud/ogm_pdf_parse_r:<tagname> -f Dockerfile .
```
Here's what each part of the command does:

`docker build`: This command tells Docker to build an image.
`--rm`: This flag removes any intermediate containers that are created during the build process, helping to keep your system clean.
`-t rtibiocloud/ogm_pdf_parse_r:v1.0.0`: The -t flag specifies the name and tag for the image. In this case, it's named ogm_pdf_parse_r with version v1.0.0.
`-f Dockerfile`: This flag specifies the Dockerfile to use for building the image. You can replace Dockerfile with the actual name of your Dockerfile if it's different.
`.`: The dot at the end of the command indicates that the build context is the current directory, where the Dockerfile is located.
Running this command will build a Docker image with the name `rtibiocloud/ogm_pdf_parse_r:v1.0.0`. Make sure you are in the directory containing the Dockerfile you want to use for building the image.

<br>

## Rscript Inputs
| Short Flag | Long Flag | Description |
|:-----:|:--------:|--------------------------------|
|   -i  |  --pdf       | Path to the input PDF file                 |
|   -o  |  --outfile   | Name of the output file                    |
|   -p  |  --outpath   | Path to the output directory               |
|   -E  |  --excel     | Export the results as an MS Excel Workbook |
|   -v  |  --verbose   | Display verbose logging                    |
|   -h  |  --help      | Display the function usage statement       |

<br>

## Rscript Output
Either an Excel spreadsheet, with three sheets (one for job details extracted from the last page, one for Filtered Structured Variants and one for Copy Number Variants) or two tab-delimited files (one for Filtered Structured Variants and one for Copy Number Variants). If output two tab-delimited files, the project information will be inculded within the Filtered Structured Variant file.

**Job Detail Columns**
|     Column     | Description                                                                    |
|:--------------:|--------------------------------------------------------------------------------|
|    Operation   | Description of the job                                                         |
|      Date      | The time and date of the run.                                                  |
|    Job Name    | The name assigned to the job.                                                  |
|     Sample     | The name assigned to the sample.                                               |
|   Reference    | The reference genome used for assembly.                                        |
|     Job ID     | The unique identifier assigned to the job.                                     |
|     Command    | The command used to generate this report.                                      |

<br>

**Filtered Structured Variant Columns**
|     Column     | Description                                                                    |
|:--------------:|--------------------------------------------------------------------------------|
|     SMAP ID    | The Single-Molecule Assembly and Polishing (SMAP) unique identifier.           |
|      Type      | The type of structural variant.                                                |
|    Location    | The genomic position of the variant described in this record.                  |
|    Size (bp)   | The difference in length between REF and ALT alleles.                          |
|    Zygosity    | The zygosity of structural variant.                                            |
|   Confidence   | The variant confidence scores from the SMAP output.                            |
|   Algorithm    | The algorithm used in the Variant Analysis Pipeline (VAP).                     |
|   Orientation  | The genomic strand.                                                            |
| Present % Control Samples | Percent of BNG control samples with SV                              |
| Nearest Non-overlap Gene  | The nearest non-overlapping gene.                                   |
| Nearest Non-overlap Gene Distance (bp) | The distance to the nearest non-overlapping gene.      |
|   Found in Self Molecules | Found in self molecules? (yes/no)                                   |
| Overlapping Genes | The set of genes overlapped by structural variant.                          |
| Overlapping Genes Count |The count of overlapping genes.                                        |
|      ISCN      |  The International Common Structural Variation Nomenclature (ICSN) annotation  |
| Fail Assembly Chimeric Score | The Fail Assembly Chimeric Score.                                |
| Putative Gene Fusion |   Potential gene fusions identified by the BioNano variant annotation pipeline  |
| Molecule Count | The self molecule count.                                                       |
| Number of Overlap DGV Calls | The number of overlapped variants in the Database of Genomic Variants (DGV). |
|  UCSC Web Link | The weblink to the University of California, Santa Cruz Genome Browser for the genomic coordinates listed within the Lcoation column. |
| Found In Control Sample Assembly | Found In Control Sample Assembly? (yes/no)                   |
| Found In Control Sample Molecules | Found In Control Sample Molecules? (yes/no)                 |
| Control Molecule Count | The count of control molecules.                                        |
| Copy Number Variants | Lists the relevant copy number variants, if applicable.                  |

<br>

**Copy Number Variant Columns**
|     Column     | Description                                                                    |
|:--------------:|--------------------------------------------------------------------------------|
|     CNV ID     | The Copy Number Variant (CNV) unique identifier.                               |
|      Type      | The type of structural variant.                                                |
|    Location    | The genomic position of the variant described in this record.                  |
|    Size (bp)   | The difference in length between REF and ALT alleles.                          |
|   Copy Number  | The copy number count.                                                         |
|   Confidence   | The variant confidence scores from the CNV output.                             |
| Overlapping Genes Count |The count of overlapping genes.                                        |

For additional information on the columns within the output, please reference the documentation provided by BioNano [here](https://bionanogenomics.com/wp-content/uploads/2021/11/30459-Bionano-VCF-File-Format-Specification-Sheet.pdf).

<br>

## Perform a testrun
`docker run -v ${PWD}/example_files/:/data -t rtibiocloud/ogm_pdf_parse_r:v1.0.0 /bin/bash  -c "Rscript /opt/parser/ogm_pdf_parse.R -i /data/example.pdf -p /data -o example.tsv"`

<details>

```
root@0a407da6d20a:/data# Rscript /opt/parser/ogm_pdf_parse.R -i /data/ogm_example.pdf --excel
Loading required package: getopt
Loading required package: dplyr

Attaching package: ‘dplyr’

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union

Loading required package: stringr
Loading required package: pdftools
Using poppler version 22.12.0
[1] "-i"                    "/data/ogm_example.pdf" "--excel"
Loading required package: openxlsx
[2024-02-13 16:01:27.546675] - main - INFO - User: root
[2024-02-13 16:01:27.551427] - main - INFO - Running from: 0a407da6d20a
[2024-02-13 16:01:27.551756] - main - INFO - Platform: x86_64-pc-linux-gnu (64-bit)
[2024-02-13 16:01:27.558544] - main - INFO - R version: R version 4.3.2 (2023-10-31)
[2024-02-13 16:01:27.558822] - main - INFO - R packages loaded: openxlsx, pdftools, stringr, dplyr, ge
[2024-02-13 16:01:27.563847] - main - INFO - Rscript: /opt/parser/ogm_pdf_parse.R
[2024-02-13 16:01:27.564151] - getopt - INFO - CommandLine: -i /data/ogm_example.pdf --excel
[2024-02-13 16:01:27.56442] - getopt - INFO - Arguments: ARGS = character(0)
 [2024-02-13 16:01:27.56442] - getopt - INFO - Arguments: pdf = /data/ogm_example.pdf
 [2024-02-13 16:01:27.56442] - getopt - INFO - Arguments: excel = TRUE
 [2024-02-13 16:01:27.56442] - getopt - INFO - Arguments: outfile = pdf_extract.xlsx
 [2024-02-13 16:01:27.56442] - getopt - INFO - Arguments: outpath = /data
 [2024-02-13 16:01:27.56442] - getopt - INFO - Arguments: verbose = FALSE
[2024-02-13 16:01:27.597341] - load_pdf - INFO - Reading in the PDF file
[2024-02-13 16:01:31.777627] - load_pdf - INFO - PDF file /data/ogm_example.pdf processing complete
Initializing data extraction...
Page 1000 of 5725 (17%) completed
Page 2000 of 5725 (35%) completed
Page 3000 of 5725 (52%) completed
Page 4000 of 5725 (70%) completed
Page 5000 of 5725 (87%) completed
[2024-02-13 16:02:10.769867] - main - INFO - Data extraction completed

[2024-02-13 16:02:11.417938] - export - INFO - pdf_extract.xlsx has been exported to /data

[2024-02-13 16:02:11.418414] - main - INFO - Process began at 2024-02-13 16:01:27.024163 and finished

[2024-02-13 16:02:11.418769] - main - INFO - Finished


```

<br>

```
Outputs:
- Excel spreadsheet:                      /data/pdf_extract.xlsx
```
</details>

<br>

## Contact
For additional information or assistance, please contact Mike Enger (menger@rti.org).

#################################################################
