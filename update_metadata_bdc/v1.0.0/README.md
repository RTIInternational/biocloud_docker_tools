# Generate Metadata Manifest on BioData Catalyst

This Dockerfile sets up an environment for running an Rscript that generates a metadata manifest for all files within a specified project on BioData Catalyst (BDC). 

## Overview

**Metadata Manifest File**

The metadata manifest file allows for batch updating metadata across multiple files using the BioData Catalyst (BDC) user interface.

A key challenge in the current system is the inability to generate a metadata manifest for all files within a project, especially when the project contains nested subdirectories. This application overcomes this limitation by recursively identifying and extracting metadata for all files within the specified project, regardless of their directory structure. It pulls the existing metadata for each file, consolidates it into a single manifest file, and outputs it in a format ready for updates. Once updated, this manifest file can be uploaded back to the platform via the user interface, enabling seamless and accurate metadata updates across the entire project.
<br>

## Usage
The following command can be used to run the docker: 
```
docker pull rtibiocloud/update_metadata_bdc:<tagname>
docker run -it rtibiocloud/update_metadata_bdc:<tagname> -c "Rscript /opt/parser/generate_metadata_manifest.R --help"
```

Example Docker run command with volume mounting:
```bash
docker run --rm -v ${PWD}:/data -w /data rtibiocloud/update_metadata_bdc:<tagname> /bin/bash -c " Rscript /opt/parser/generate_metadata_manifest.R -t <insert API token> -p /project_owner/project -o ."
```

If not running the docker from the directory with the data, replace `${PWD}` with the actual path on your host system with the PDF outputs.

<br>

## Build
To build this Docker image, you can use the following command:
```
docker build --rm -t rtibiocloud/update_metadata_bdc:<tagname> -f Dockerfile .
```
Here's what each part of the command does:

`docker build`: This command tells Docker to build an image.
`--rm`: This flag removes any intermediate containers that are created during the build process, helping to keep your system clean.
`-t rtibiocloud/update_metadata_bdc:v1.0.0`: The -t flag specifies the name and tag for the image. In this case, it's named update_metadata_bdc with version v1.0.0.
`-f Dockerfile`: This flag specifies the Dockerfile to use for building the image. You can replace Dockerfile with the actual name of your Dockerfile if it's different.
`.`: The dot at the end of the command indicates that the build context is the current directory, where the Dockerfile is located.
Running this command will build a Docker image with the name `rtibiocloud/update_metadata_bdc:v1.0.0`. Make sure you are in the directory containing the Dockerfile you want to use for building the image.

## Rscript Inputs
| Short Flag | Long Flag | Description |
|:-----:|:--------:|--------------------------------|
|   -t  |  --token       | Authentication token              |
|   -p  |  --project_id   | Project ID                  |
|   -o  |  --output_path   | Path to save the output manifest           |
|   -h  |  --help      | Display the function usage statement       |

## Rscript Outputs

The output of this application is a CSV formatted manifest file. The manifest file contains 4 required columns for identifying the correct file in the project. The remaining columns are prespecified metadata fields. Details on these fields and the overall metadata schema can be found within the following webpage: https://sb-biodatacatalyst.readme.io/docs/metadata-schema

As mentioned above, this output can be updated and uploaded to BDC, using the user interface, to update metadata fields for files in the specified project.

## Perform a testrun

`docker run -v ${PWD}/:/data -t rtibiocloud/update_metadata_bdc:v1.0.0 /bin/bash  -c "Rscript /opt/generate_metadata_manifest.R -t <insert token> -p <insert projectID> -o ."`

<details>

```
root@0a407da6d20a:/data# Rscript /opt/generate_metadata_manifest.R -t <insert token> -p <insert projectID> -o .


Loading required package: getopt
Loading required package: dplyr

Attaching package: ‘dplyr’

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union

Loading required package: httr
Loading required package: stringr
Loading required package: lubridate

Attaching package: ‘lubridate’

The following objects are masked from ‘package:base’:

    date, intersect, setdiff, union

Loading required package: sevenbridges2
Loading required package: jsonlite
[2024-08-22 18:07:17.506371] - setup - INFO - Setting up recursive file and folder extraction function
[2024-08-22 18:07:17.513716] - setup - INFO - Starting script and setting up API endpoint and platform URL
[2024-08-22 18:07:17.513962] - setup - INFO - Authenticating with the API
[2024-08-22 18:07:17.539544] - get_project - INFO - Retrieving project information
[2024-08-22 18:07:19.057607] - main - INFO - Starting extraction of files and folders
[2024-08-22 18:07:19.405385] - extract - INFO - Processing folder: Harmonized_Data
[2024-08-22 18:07:19.794829] - extract - INFO - Processing folder: RMIP_000_CyTOF
[2024-08-22 18:07:19.98858] - extract - INFO - Processing file: RMIP_000_001_A_001_A.txt
[2024-08-22 18:07:19.989302] - extract - INFO - Processing file: RMIP_000_002_A_001_A.txt
[2024-08-22 18:07:19.989939] - extract - INFO - Processing folder: RMIP_000_scRNA
[2024-08-22 18:07:20.080253] - extract - INFO - Processing folder: RMIP_000_viability
[2024-08-22 18:07:20.126575] - extract - INFO - Processing folder: Raw_Data
[2024-08-22 18:07:20.356785] - extract - INFO - Processing folder: RMIP_000_CyTOF
[2024-08-22 18:07:20.5892] - extract - INFO - Processing file: RMIP_000_001_A_001_A.txt
[2024-08-22 18:07:20.590099] - extract - INFO - Processing file: RMIP_000_002_A_001_A.txt
[2024-08-22 18:07:20.590935] - extract - INFO - Processing folder: RMIP_000_scRNA
[2024-08-22 18:07:20.639246] - extract - INFO - Processing folder: RMIP_000_viability
[2024-08-22 18:07:20.729023] - extract - INFO - Processing folder: Study_Documentation
[2024-08-22 18:07:20.777902] - extract - INFO - Processing folder: Templates
[2024-08-22 18:07:21.013212] - extract - INFO - Processing file: README.md
[2024-08-22 18:07:21.222711] - main - INFO - CSV file written to ./manifest_20240822.csv
[2024-08-22 18:07:21.22298] - main - INFO - Metadata Manifest generated successfully

```
</details>

## Contact
For additional information or assistance, please contact Mike Enger (menger@rti.org).

