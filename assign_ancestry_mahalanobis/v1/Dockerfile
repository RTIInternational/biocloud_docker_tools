FROM bioconductor/bioconductor_docker:RELEASE_3_17

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Add R helper script
ADD assign_ancestry_mahalanobis.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/assign_ancestry_mahalanobis.R

# Install libraries
RUN Rscript -e 'BiocManager::install(c("scatterplot3d"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("optparse"), ask = FALSE)'

# Set wrkdir
RUN mkdir /data
WORKDIR /data
