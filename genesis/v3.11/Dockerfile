FROM bioconductor/bioconductor_docker:RELEASE_3_11

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Add R helper script
ADD genesis.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/genesis.R

# Install libraries
RUN Rscript -e 'BiocManager::install(c("GWASTools"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("GENESIS"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("R.utils"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("optparse"), ask = FALSE)'

# Set wrkdir
RUN mkdir /data
WORKDIR /data
