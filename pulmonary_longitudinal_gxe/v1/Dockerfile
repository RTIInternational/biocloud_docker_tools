FROM bioconductor/bioconductor_docker:RELEASE_3_20

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Add R helper script
ADD run_gxe.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/run_gxe.R

# Install libraries
RUN Rscript -e 'BiocManager::install(c("optparse"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("bigsnpr"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("lme4"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("lmerTest"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("RSQLite"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("dbplyr"), ask = FALSE)'

# Set wrkdir
RUN mkdir /data
WORKDIR /data
