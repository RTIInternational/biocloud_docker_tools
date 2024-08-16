# Base image
FROM rocker/tidyverse:4.4.1

# Maintainer and author
LABEL maintainer="Caryn Willis <cdwillis@rti.org>"
LABEL description="An R script using Seven Bridges API to tag files with RMIP file formatting."
LABEL software-website="https://doi.org/10.32614/CRAN.package.sevenbridges2"
LABEL software-version="0.2.0"
LABEL license="https://www.apache.org/licenses/LICENSE-2.0"

# Create working directory
RUN mkdir -p /scratch
WORKDIR /scratch

# Install necessary R packages
RUN Rscript -e 'install.packages(c("readr","tidyverse","openxlsx","sevenbridges2","tools","logr","stringr","optparse"), repos = "http://cran.us.r-project.org")'

#Add to environment
ENV PATH=$PATH:/opt/

# Copy script
COPY file_tagging.R /opt/file_tagging.R

# Set default command to display help message
CMD ["Rscript", "/opt/file_tagging.R", "-h"]
