FROM bioconductor/bioconductor_docker:RELEASE_3_11

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Add R helper script
ADD convert_seq_gds_to_snp_gds.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/convert_seq_gds_to_snp_gds.R

# Install SNPRelate
RUN Rscript -e 'BiocManager::install(c("SeqArray"), ask = FALSE)'

# Set wrkdir
RUN mkdir /data
WORKDIR /data

