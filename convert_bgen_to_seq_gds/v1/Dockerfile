FROM bioconductor/bioconductor_docker:RELEASE_3_11

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Add R helper script
ADD convert_bgen_to_seq_gds.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/convert_bgen_to_seq_gds.R

# Install SNPRelate
RUN Rscript -e 'library("devtools"); install_github("zhengxwen/gds2bgen");'

# Set wrkdir
RUN mkdir /data
WORKDIR /data

