FROM bioconductor/bioconductor_docker:RELEASE_3_23

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Add R helper script
ADD GenomicSEM_commonFactor.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/GenomicSEM_commonFactor.R

# Install R packages
RUN Rscript -e 'install.packages("magrittr"); install.packages("devtools"); library("devtools"); pak::pak("GenomicSEM/GenomicSEM"); require(GenomicSEM); require(Matrix); require(stats)'

# Set wrkdir
RUN mkdir /data
WORKDIR /data
