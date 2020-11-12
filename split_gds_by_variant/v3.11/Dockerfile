FROM bioconductor/bioconductor_docker:RELEASE_3_11

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Add R helper script
ADD split_gds_by_variant.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/split_gds_by_variant.R

# Install libraries
RUN Rscript -e 'BiocManager::install(c("gdsfmt"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("data.table"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("R.utils"), ask = FALSE)'

# Set wrkdir
RUN mkdir /data
WORKDIR /data
