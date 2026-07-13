FROM bioconductor/bioconductor_docker:RELEASE_3_17

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Create a group and user
RUN groupadd -g 1111 appgroup && \
    useradd -r -u 1111 -g appgroup appuser

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
RUN chown -R appuser:appgroup /data
