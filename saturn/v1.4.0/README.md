# SatuRn Differential Transcript Usage
This Dockerfile sets up an environment for running differential transcript usage with satuRn.

## Overview
**What is satuRn?**

satuRn is a highly performant and scalable method for performing differential transcript usage analyses. Visit the satuRn github for more details: https://github.com/statOmics/satuRn

<br>

## Usage
For comprehensive instructions, please refer to the satuRn vignette here: https://statomics.github.io/satuRn/articles/Vignette.html



## Build
To build this Docker image, you can use the following command:
```
docker build --rm -t /satuRn:v1.4.0 -f Dockerfile .`
```
Here's what each part of the command does:

`docker build`: This command tells Docker to build an image. 
`--rm`: This flag removes any intermediate containers that are created during the build process, helping to keep your system clean. 
`-t satuRn:v1.4.0:` The -t flag specifies the name and tag for the image. In this case, it's named satuRn with version v1.4.0. 
`-f Dockerfile`: This flag specifies the Dockerfile to use for building the image. You can replace Dockerfile with the actual name of your Dockerfile if it's different. 
`.`: The dot at the end of the command indicates that the build context is the current directory, where the Dockerfile is located. 
Running this command will build a Docker image with the name satuRn:v1.4.0. Make sure you are in the directory containing the Dockerfile you want to use for building the image.



Contact
For additional information or assistance, please contact Eric Earley (eearley@rti.org).
