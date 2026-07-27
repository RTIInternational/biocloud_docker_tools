# Base image
FROM bioconductor/bioconductor_docker:RELEASE_3_23

# Maintainer and author
LABEL maintainer="Xin Wu <xwu@rti.org>"
LABEL description="Docker image for DNA methylation (DNAm) array processing and quality control using the SeSAMe pipeline."
LABEL base-image="bioconductor/bioconductor_docker:RELEASE_3_23"
LABEL software-website="https://github.com/RTIInternational/biocloud_docker_tools/tree/master/dnam_processing_qc"
LABEL software-version="1.0"
LABEL license="https://github.com/RTIInternational/biocloud_docker_tools/blob/master/LICENSE"

# Create working directory
RUN mkdir -p /scratch
WORKDIR /scratch

# Install system-level dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libhdf5-dev \
    && rm -rf /var/lib/apt/lists/*

# Install necessary R packages (pinned versions via pak)
RUN Rscript -e 'install.packages("pak", repos = "https://cloud.r-project.org")' \
 && Rscript -e 'pak::pak("pacman@0.5.1")' \
 && Rscript -e 'pak::pak("logr@1.3.9")' \
 && Rscript -e 'pak::pak("GGally@2.4.0")'

# Install necessary Bioconductor packages (pinned versions)
RUN Rscript -e 'BiocManager::install( \
    c("sesame", "sesameData", "BiocParallel", "minfi", "wateRmelon", "PCAtools"), \
    ask = FALSE, update = FALSE)'
# sesame==1.30.1, sesameData==1.30.0, BiocParallel==1.46.0,
# minfi==1.58.0, wateRmelon==2.18.0, PCAtools==2.24.0

# Add to environment
ENV PATH=$PATH:/opt/

# Copy script
COPY dnam_processing_qc.R /opt/dnam_processing_qc.R

# Set default command to display help message
CMD ["Rscript", "/opt/dnam_processing_qc.R"]
