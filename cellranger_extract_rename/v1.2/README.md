# Description

This Docker image contains an in-house script written to extract and rename all files from the large 'outs.zip' file or large 'outs' directory from the Cell Ranger process.  Its purpose is to fit in the single cell RNA sequencing workflow, as well as ATACseq and potentially GUIDEseq, in the RMIP project.  The Input to this should be a ZIP file or directory coming from a Cell Ranger run, and the output is an output directory with renamed files and a renamed copy of the input 'outs.zip' file (if compressed flag is used).  Files and relative paths within the 'outs.zip' file are listed in the table below:

| Directory | Filename | Description | Link |
| -- | -- | -- | -- |
| ./ | web_summary.html | Interactive summary HTML file named that contains summary metrics and automated secondary analysis results. | https://www.10xgenomics.com/support/software/cell-ranger/analysis/outputs/cr-outputs-web-summary-count |
| ./ | metrics_summary.csv | The metrics_summary.csv is organized with each column specifying one metric name. The metric values are specified in a single row.  | https://www.10xgenomics.com/support/software/cell-ranger/analysis/outputs/cr-3p-outputs-metrics-count |
| ./ | raw_feature_bc_matrix.h5 | Raw feature-barcode matrices describing the number of UMIs associated with a feature and a barcode. | https://www.10xgenomics.com/support/software/cell-ranger/analysis/outputs/cr-outputs-h5-matrices |
| ./ | possorted_genome_bam.bam | Index file containing position-sorted reads aligned to the genome and transcriptome. | https://www.10xgenomics.com/support/software/cell-ranger/analysis/outputs/cr-outputs-bam |
| ./ | possorted_genome_bam.bam.bai | Index file associated with the BAM file. | https://www.10xgenomics.com/support/software/cell-ranger/analysis/outputs/cr-outputs-bam |
| ./ | filtered_feature_bc_matrix.h5 | Filtered feature-barcode matrices describing the number of UMIs associated with a feature and a barcode. | https://www.10xgenomics.com/support/software/cell-ranger/analysis/outputs/cr-outputs-h5-matrices |

Each of these files are copied to an output directory and prepended with a "linker" for a given sample.  Additionally, the given ZIP file is copied to this directory and also prepended with this linker.  Given the example linker `RMIP_001_allo2_A_003_B`, this can be separated into different components, delimited by `_`.  Details on the linker and its format are below.

| Name | Component | Description |
| -- | -- | -- |
|  RMIP identifier | `RMIP` | Goes at the beginning of each linker |
|  Project Identifier | `001` | Numeric only |
|  Participant ID | `allo2` | Alphanumeric only, no length restrictions |
|  Discriminator | `A` | Alphabetic only - combination with "Identifier" uniquely identifies every collection event |
|  Identifier | `003` | Numeric only - combination with "Discriminator" uniquely identifies every collection event |
|  Vial identifier (alphabetic) | `B` | Alphabetic only - identifies specific collection aliquot - optional if only one vial |

## Sample usage

This script is used to extract results from the output of a Cell Ranger run.

Build
```
docker build -t cellranger_extract_rename:v1.2 .
```

Run
```
docker run -it -v $PWD:/data cellranger_extract_rename:v1.2 rename_files.sh
```

Usage info:
```
Usage: /rename_files.sh [OPTIONS]
Options:
 -h, --help             Display this help message
 -v, --verbose          Enable verbose mode
 -p, --pilot            Enable pilot mode
 -c, --compressed_output_mode   Enable compress output mode (compress all files except extracted files list)
 -l, --linker           STRING Specify name of linker to prepend to extracted files (format 'RMIP_<ddd>_<alphanum>_<w>_<ddd>_<w>') - Required
                          e.g. linker='RMIP_001_allo1_A_001_A'
                          Note that the Vial Identifier (last letter) is optional
 -i, --input_dir        STRING/PATH Specify name and path of input directory to read - one of either ZIP or Input Directory Required
 -z, --input_zip        STRING/PATH Specify name and path of ZIP file to read - one of either ZIP or Input Directory Required
 -o, --output_dir       STRING/PATH Specify directory where to put extracted files.  Default = '.'

Example usage
 Required flags (ZIP input):               ./rename_files.sh -z outs.zip -l RMIP_001_allo1_A_001_A
 Required flags (DIRECTORY input):         ./rename_files.sh -i outs -l RMIP_001_allo1_A_001_B
 Required flags (BOTH - defaults to ZIP):  ./rename_files.sh -z outs.zip -i outs -l RMIP_001_allo1_A_001_C
 Writing to output directory:              ./rename_files.sh -z outs.zip -l RMIP_001_allo1_A_001_D -o outs
 Verbose mode:                             ./rename_files.sh -v -z outs.zip -l RMIP_001_allo1_A_001_E
 Pilot mode:                               ./rename_files.sh -p -z outs.zip -l RMIP_001_PL_001
```

## Files included

- `Dockerfile`: the Docker file used to build this image
- `rename_files.sh`: Bash shell script that serves as the main executable when the Docker container is run.  Expected behavior is to take a specified input ZIP file OR directory in the current working directory, extract specific files from it, and rename those files to include a prefix signifying a sample name.  This writes those specific files and a renamed copy of the ZIP file (if given) to an output directory.

## Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- David Williams, email: dnwilliams@rti.org
- Caryn Willis, email: cdwillis@rti.org
