FROM bioconductor/bioconductor_docker:RELEASE_3_11

# Maintainer and author
LABEL maintainer="Ravi Mathur <rmathur@rti.org>"

# Add R helper script
ADD GenomicSEM_commonFactor.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/GenomicSEM_commonFactor.R

# Install R packages
RUN Rscript -e 'install.packages("magrittr"); install.packages("devtools"); library("devtools"); install_github("MichelNivard/GenomicSEM");require(GenomicSEM);require(Matrix);require(stats);library(R.utils)'

# Set wrkdir
RUN mkdir /data
WORKDIR /data
