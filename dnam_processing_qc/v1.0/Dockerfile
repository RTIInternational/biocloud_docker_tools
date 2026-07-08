# Base image
FROM bioconductor/bioconductor_docker:RELEASE_3_23

# Maintainer and author
LABEL maintainer="Xin Wu <xwu@rti.org>"
LABEL description="Docker image for DNA methylation (DNAm) array processing and quality control using the SeSAMe pipeline."
LABEL base-image="bioconductor/bioconductor_docker:RELEASE_3_23"
LABEL software-website="https://github.com/rti-international/multiomics-aud-cs"
LABEL software-version="1.0"
LABEL license="https://github.com/RTIInternational/biocloud_docker_tools/blob/master/LICENSE"

# Create working directory
RUN mkdir -p /scratch
WORKDIR /scratch

# Install system-level dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libhdf5-dev \
    && rm -rf /var/lib/apt/lists/*

# Install necessary R packages
RUN Rscript -e 'install.packages(c("pacman", "logr", "GGally"), repos = "http://cran.us.r-project.org")'

# Install necessary Bioconductor packages
RUN Rscript -e 'BiocManager::install( \
    c("sesame", "sesameData", "BiocParallel", "minfi", "wateRmelon", "PCAtools"), \
    ask = FALSE, update = FALSE)'

# Add to environment
ENV PATH=$PATH:/opt/

# Copy script
COPY dnam_processing_qc.R /opt/dnam_processing_qc.R

# Set default command to display help message
CMD ["Rscript", "/opt/dnam_processing_qc.R"]
