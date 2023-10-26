# saige_gds Dockerfile

This Dockerfile sets up an environment for running [SAIGEgds]([https://www.10xgenomics.com/support/software/cell-ranger](https://bioconductor.org/packages/release/bioc/html/SAIGEgds.html)) software for GWAS.

## Overview

**What is SAIGEgds?**

This is an R package that is widely used in GWAS. This version accepts GDS files which are a highly compressed and efficient version. The original saige only accepted plink files.
This docker image is an implementation of this package.
<br>

## Build
To build this Docker image, you can use the following command:
```
docker build --rm -t saige_gds -f Dockerfile .`
```
Here's what each part of the command does:

`docker build`: This command tells Docker to build an image.
`--rm`: This flag removes any intermediate containers that are created during the build process, helping to keep your system clean.
`-t saige_gds`: The -t flag specifies the name and tag for the image.
`-f Dockerfile`: This flag specifies the Dockerfile to use for building the image. You can replace Dockerfile with the actual name of your Dockerfile if it's different.
`.`: The dot at the end of the command indicates that the build context is the current directory, where the Dockerfile is located.
Running this command will build a Docker image with the name `saige_gds`. Make sure you are in the directory containing the Dockerfile you want to use for building the image.



## Usage

`docker run 6abf7cf0091f Rscript saige_gds.R --help`



## Contact
For additional information or assistance, please contact Eric Earley (eearley@rti.org).
