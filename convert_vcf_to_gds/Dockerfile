FROM bioconductor_docker:RELEASE_3_11

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Add R helper script
ADD convert_vcf_to_gds.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/convert_vcf_to_gds.R

# Install SNPRelate
RUN Rscript -e 'BiocManager::install(c("SNPRelate"), version = "3.11", ask = FALSE);'

# Set wrkdir
RUN mkdir /data
WORKDIR /data
