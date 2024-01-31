#################################################################
# Dockerfile
#
# This can be used to run the Cell Viability PDF Parser tool
#
# Software: R
# Software Version: 4.3.2 Eye Holes
#
# R packages: pdftools, dplyr, openxlsx, getopt
#
# Description: This script loads a PDF file descibing cell viabaility
# from a nucleo counter 2000 and parses viability metrics that are
# exported to a tab delimited file
#
#
# Provides:
# Base Image: R 4.3.2
# Build Cmd: docker build --rm -t rtibiocloud/pdf_parse_r:v1.0.0 -f Dockerfile .
# Pull Cmd: docker pull rtibiocloud/pdf_parse_r:v1.0.0
# Run Cmd: docker run --rm -v ${PWD}:/data -w /data rtibiocloud/pdf_parse_r:v1.0.0 /bin/bash -c ""
#################################################################


FROM r-base:4.3.2

#----------------------------------------------------------------
# Container Metadata
#----------------------------------------------------------------
LABEL base.image="r-base:v4.3.2"
LABEL maintainer="Mike Enger <menger@rti.org>"
LABEL description="PDF parser for cell viability outputs"
LABEL software="R, pdftools, dplyr, openxlsx, getopt"
LABEL software-website="https://www.r-project.org/ https://dplyr.tidyverse.org/ https://cran.r-project.org/web/packages/openxlsx/index.html https://cran.r-project.org/web/packages/pdftools/pdftools.pdf https://cran.r-project.org/web/packages/getopt/index.html"
LABEL software.version="1.0.0"
LABEL license="GPL-2 | GPL-3 "
LABEL about.tags="RMIP"

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

#----------------------------------------------------------------
# Install R Packages
#----------------------------------------------------------------
ENV R_VERSION 4.3.2

# Setup the CRAN to get the packages
RUN echo "r <- getOption('repos'); r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile
RUN Rscript -e "install.packages('getopt', dependencies = T)"
RUN Rscript -e "install.packages('dplyr', dependencies = T)"
RUN Rscript -e "install.packages('pdftools', dependencies = T)"
RUN Rscript -e "install.packages('openxlsx', dependencies = T)"
RUN Rscript -e "library('getopt');##### R SESSION INFORMATION #####; sessionInfo()"

#----------------------------------------------------------------
# Copy over analysis scripts
#----------------------------------------------------------------
ADD parse_viability_pdf.R /opt/parser/parse_viability_pdf.R

#----------------------------------------------------------------
# Set working dir
#----------------------------------------------------------------
WORKDIR /data/


RUN cd talkingheads
