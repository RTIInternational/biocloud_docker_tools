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
COPY bdc_tutorial.R /opt/bdc_tutorial.R

#-------------------------------------------------
# Create working directory
#-------------------------------------------------
RUN mkdir -p /scratch
WORKDIR /scratch

#-------------------------------------------------
# Set default command to display help message
#-------------------------------------------------
CMD ["Rscript", "/opt/bdc_tutorial.R", "-h"]