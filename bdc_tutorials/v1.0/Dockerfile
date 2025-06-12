#-------------------------------------------------
# BioData Catalyst Tutorials 
# Provides:
# Base Image: rocker/tidyverse:4.4.2
# Build Cmd: docker build --rm -t rtibiocloud/bdc_tutorial:v1.0.0 -f Dockerfile .
# Pull Cmd: docker pull rtibiocloud/bdc_tutorial:v1.0.0
# Run Cmd: docker run --rm -v ${PWD}:/data -w /data rtibiocloud/bdc_tutorial:v1.0.0 /bin/bash -c ""
#-------------------------------------------------
# Base image
#-------------------------------------------------
FROM rocker/tidyverse:4.4.2

#-------------------------------------------------
# Set Labels
#-------------------------------------------------
LABEL maintainer="Jeran Stratford <jstratford@rti.org>"
LABEL description="An R script to demonstrate how to bring your own tools to BioData Catalyst."
LABEL base-image="rocker/tidyverse:4.4.2"
LABEL software="R, getopt"
LABEL software-website="https://www.r-project.org/ https://cran.r-project.org/web/packages/getopt/index.html"
LABEL software-version="1.0"
LABEL license="GPL-2 | GPL-3 "

#-------------------------------------------------
# Install necessary R packages
#-------------------------------------------------
RUN Rscript -e 'install.packages(c("getopt"), repos = "http://cran.us.r-project.org")'

#-------------------------------------------------
# Add to environment
#-------------------------------------------------
ENV PATH=$PATH:/opt/

#-------------------------------------------------
# Copy script
#-------------------------------------------------
COPY aa_translator.R /opt/bdc_tutorial/aa_translator.R

#-------------------------------------------------
# Create working directory
#-------------------------------------------------
RUN mkdir -p /scratch
WORKDIR /scratch

#-------------------------------------------------
# Set default command to display help message
#-------------------------------------------------
CMD ["Rscript", "/opt/bdc_tutorial/aa_translator.R", "-h"]