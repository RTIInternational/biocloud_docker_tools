FROM bioconductor/bioconductor_docker:RELEASE_3_11

# Maintainer and author
LABEL maintainer="Jesse Marks <jmarks@rti.org>"

# Add R helper script
ADD select_pcs.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/select_pcs.R

# Install libraries
RUN Rscript -e 'BiocManager::install(c("R.utils"), ask = FALSE)'

# Set wrkdir
RUN mkdir /data
WORKDIR /data
