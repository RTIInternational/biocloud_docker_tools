FROM bioconductor/bioconductor_docker:RELEASE_3_15

# author
LABEL maintainer="Eric Earley <eearley@rti.org>"

# add R script
ADD saige_gds.R /opt/


# change permissions to make executable
RUN chmod 755 /opt/genesis.R

# Install libraries
RUN Rscript -e 'BiocManager::install(c("R.utils"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("SeqArray"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("SAIGEgds"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("SNPRelate"), ask = FALSE)'


# Set wrkdir
RUN mkdir /data
WORKDIR /data
