FROM bioconductor/bioconductor_docker:3.17

LABEL maintainer="David Williams <dnwilliams@rti.org>"
LABEL description="This Docker image contains an in-house script written to convert ab1 files to FASTA files using the sangeranalyseR package from Bioconductor."
LABEL base-image="bioconductor/bioconductor_docker:3.17"
LABEL software-version="1.0"

RUN apt update
RUN apt install -y vim

# Install libraries
RUN Rscript -e 'BiocManager::install(c("sangeranalyseR"), ask = FALSE)'
RUN Rscript -e 'install.packages("getopt")'

# Add scripts to make it run
ADD convert_ab1_to_fasta.r /

# Add to /opt folder
RUN mv convert_ab1_to_fasta.r /opt/

# Change permissions to make things exectuable
RUN chmod u+x /opt/convert_ab1_to_fasta.r

# Set wrkdir
RUN mkdir /data
COPY ./*.ab1 /data
WORKDIR /data

# Add to environment
ENV PATH $PATH:/opt/
