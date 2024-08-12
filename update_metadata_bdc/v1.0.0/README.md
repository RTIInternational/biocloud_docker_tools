# Update File Metadata on BioData Catalyst

This Dockerfile sets up an environment for running an Rscript that generates a metadata manifest file based on all of the files found within a specified project on BioData Catalyst (BDC). 

## Overview

**Metadata Manifest File**

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


## Contact
For additional information or assistance, please contact Mike Enger (menger@rti.org).

#################################################################
