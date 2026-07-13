FROM bioconductor/bioconductor_docker:RELEASE_3_23

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Install libraries
RUN Rscript -e 'BiocManager::install(c("scatterplot3d"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("optparse"), ask = FALSE)'

# Add R helper script
ADD assign_ancestry_mahalanobis.R /opt/

# Change permissions to make things executable
RUN chmod 755 /opt/assign_ancestry_mahalanobis.R

# Set wrkdir
RUN mkdir /data
WORKDIR /data