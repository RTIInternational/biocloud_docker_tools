#################################################################
# Dockerfile
#
# This can be used to run the Cell Viability PDF Parser tool
#
# Software: R
# Software Version: 4.3.2
#
#
# Description: This script loads a PDF file descibing cell viabaility
# from a nucleo counter 2000 and parses viability metrics that are
# exported to a tab delimited file
#
#
# Provides:
# Base Image: R 4.3.2
# Build Cmd: docker build --rm -t rtibiocloud/pdf_parse_r:v1.0.0 Dockerfile .
# Pull Cmd: docker pull rtibiocloud/pdf_parse_r:v1.0.0
# Run Cmd: docker run --rm -v ${PWD}:/data -w /data rtibiocloud/pdf_parse_r:v1.0.0 /bin/bash -c ""
#################################################################


FROM r-base:4.3.2

#----------------------------------------------------------------
# Container Metadata
#----------------------------------------------------------------
LABEL maintainer="Mike Enger <menger@rti.org>"
LABEL description="PDF parser for cell viability outputs"
LABEL software-website=" "
LABEL software.version="1.0"
LABEL license=" "

#----------------------------------------------------------------
# Install R Packages
#----------------------------------------------------------------
RUN echo "r <- getOption('repos'); r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile
RUN Rscript -e "install.packages('getopt')"
RUN Rscript -e "install.packages('dplyr')"
RUN Rscript -e "install.packages('pdftools')"
RUN Rscript -e "install.packages('openxlsx')"
RUN Rscript -e "library('getopt');##### R SESSION INFORMATION #####; sessionInfo()"

#----------------------------------------------------------------
# Set working directory
#----------------------------------------------------------------
WORKDIR /opt

#----------------------------------------------------------------
# Copy over analysis scripts
#----------------------------------------------------------------
RUN wget --no-check-certificate https://github.com/ExpressionAnalysis/CNV_Radar/archive/master.zip -O /opt/CNVRadar.zip && \
    unzip /opt/CNVRadar.zip -d /opt/CNVRadar && \
    mv /opt/CNVRadar/CNV_Radar-master/* /opt/CNVRadar/ && \
    rm -r /opt/CNVRadar/CNV_Radar-master/ && \
    rm /opt/CNVRadar.zip

#----------------------------------------------------------------
# Set working dir
#----------------------------------------------------------------
WORKDIR /data/
