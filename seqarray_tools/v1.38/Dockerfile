FROM bioconductor/bioconductor_docker:RELEASE_3_15

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Add R helper script
ADD convert_seq_gds_to_snp_gds.R /opt/
ADD convert_seq_gds_to_vcf.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/convert_seq_gds_to_snp_gds.R
RUN chmod 755 /opt/convert_seq_gds_to_vcf.R

# Install SNPRelate
RUN Rscript -e 'BiocManager::install(c("SeqArray"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("optparse"), ask = FALSE)'

# Set wrkdir
RUN mkdir /data
WORKDIR /data

