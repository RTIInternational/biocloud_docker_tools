# Base image
FROM rocker/tidyverse:4.4.1

# Maintainer and author 
LABEL maintainer="Caryn Willis <cdwillis@rti.org>"
LABEL description="An R script to format LCMS xlsx files."


# Create working directory
RUN mkdir -p /scratch
WORKDIR /scratch

# Install necessary R packages
RUN Rscript -e 'install.packages(c("optparse", "openxlsx", "readxl", "tools"), repos = "http://cran.us.r-project.org")'


# Add to environment
ENV PATH=$PATH:/opt/

# Copy script
COPY LCMS_file_formatter.R /opt/LCMS_file_formatter.R

# Set default command to display help message
CMD ["Rscript", "/opt/LCMS_file_formatter.R", "-h"]
