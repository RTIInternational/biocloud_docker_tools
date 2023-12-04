# Cell Ranger Dockerfile

This Dockerfile sets up an environment for running [Cell Ranger](https://www.10xgenomics.com/support/software/cell-ranger) software for single-cell analyses.

## Overview

**What is Cell Ranger?**

Cell Ranger is a set of analysis pipelines that process Chromium Next GEM single-cell data to align reads, generate feature-barcode matrices, perform clustering, and other secondary analyses. It supports various workflows and libraries. For detailed usage instructions and documentation, visit the [official Cell Ranger documentation](https://www.10xgenomics.com/support/software/cell-ranger/getting-started/cr-getting-started-with-cell-ranger).


<br>


## Usage
For comprehensive instructions, please refer to the official Cell Ranger documentation. However, for a quick start, you can use the following command which will provide you with basic usage information: 
`docker run -it b55e1a301011 cellranger --help`


### Important Note on Reference Data
Please note that we do not include the Human reference (GRCh38) dataset required for Cell Ranger within this Docker image.
The reference data can be obtained directly from the 10x Genomics website: [Download GRCh38 Reference Data](https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2020-A.tar.gz).
Due to the substantial size of these reference files, including them in the Docker image would significantly increase its size, making it impractical for distribution.
Therefore, we kindly ask users to follow these steps to use the reference data effectively:

1. **Download the Reference Data:**
   - Click the link provided above to download the reference data archive (`refdata-gex-GRCh38-2020-A.tar.gz`) from the 10x Genomics website.

2. **Extract the Reference Data:**
   - After downloading, extract the contents of the archive to a location on your local machine.

3. **Mount the Reference Data as a Volume:**
   - When running the Docker container, you will need to mount the directory containing the extracted reference data as a volume within the container. This ensures that Cell Ranger can access the necessary reference files.

Example Docker run command with volume mounting:
```bash
docker run -v /path/to/extracted/reference:/mnt/reference -d your-cellranger-image:tag
```

Replace `/path/to/extracted/reference` with the actual path on your host system where you extracted the reference data, and your-cellranger-image:tag with the appropriate Docker image and tag.


<br>


## Build
To build this Docker image, you can use the following command:
```
docker build --rm -t /cellranger:v7.2.0 -f Dockerfile .`
```
Here's what each part of the command does:

`docker build`: This command tells Docker to build an image.
`--rm`: This flag removes any intermediate containers that are created during the build process, helping to keep your system clean.
`-t cellranger:v7.2.0`: The -t flag specifies the name and tag for the image. In this case, it's named cellranger with version v7.2.0.
`-f Dockerfile`: This flag specifies the Dockerfile to use for building the image. You can replace Dockerfile with the actual name of your Dockerfile if it's different.
`.`: The dot at the end of the command indicates that the build context is the current directory, where the Dockerfile is located.
Running this command will build a Docker image with the name `cellranger:v7.2.0`. Make sure you are in the directory containing the Dockerfile you want to use for building the image.


## Perform a testrun
`docker run -it 69d989ee9140 cellranger testrun --id=check_install`

<details>

```
Martian Runtime - v4.0.11
Serving UI at http://eb970b64a1ba:39913?auth=pzi9FgFTCwMgu-YofnG0tFetgD5NGSwD3QOayHL0kxc

Running preflight checks (please wait)...
Checking sample info...
Checking FASTQ folder...
Checking reference...
Checking reference_path (/opt/cellranger-7.2.0/external/cellranger_tiny_ref) on eb970b64a1ba...
Checking optional arguments...
mro: v4.0.11
mrp: v4.0.11
Anaconda: Python 3.10.11
numpy: 1.24.3
scipy: 1.10.1
pysam: 0.21.0
h5py: 3.6.0
pandas: 1.5.3
STAR: 2.7.2a
samtools: samtools 1.16.1
```
...
...
...

<br>

```
Outputs:
- Run summary HTML:                         /opt/check_install/outs/web_summary.html
- Run summary CSV:                          /opt/check_install/outs/metrics_summary.csv
- BAM:                                      /opt/check_install/outs/possorted_genome_bam.bam
- BAM BAI index:                            /opt/check_install/outs/possorted_genome_bam.bam.bai
- BAM CSI index:                            null
- Filtered feature-barcode matrices MEX:    /opt/check_install/outs/filtered_feature_bc_matrix
- Filtered feature-barcode matrices HDF5:   /opt/check_install/outs/filtered_feature_bc_matrix.h5
- Unfiltered feature-barcode matrices MEX:  /opt/check_install/outs/raw_feature_bc_matrix
- Unfiltered feature-barcode matrices HDF5: /opt/check_install/outs/raw_feature_bc_matrix.h5
- Secondary analysis output CSV:            /opt/check_install/outs/analysis
- Per-molecule read information:            /opt/check_install/outs/molecule_info.h5
- CRISPR-specific analysis:                 null
- Antibody aggregate barcodes:              null
- Loupe Browser file:                       /opt/check_install/outs/cloupe.cloupe
- Feature Reference:                        null
- Target Panel File:                        null
- Probe Set File:                           null

Waiting 6 seconds for UI to do final refresh.
Pipestance completed successfully!

2023-09-29 16:33:06 Shutting down.
Saving pipestance info to "check_install/check_install.mri.tgz"
```
</details>

<br><br>

## Contact
For additional information or assistance, please contact Jesse Marks (jmarks@rti.org).
