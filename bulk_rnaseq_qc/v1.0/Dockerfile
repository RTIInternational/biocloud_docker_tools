ARG TARGETPLATFORM=linux/arm64

FROM --platform=$TARGETPLATFORM rocker/r-ver:4.6.1 

# Add Container Labels
LABEL maintainer="Caryn Willis <cdwillis@rti.org>"
LABEL description="Tools for running quality control on bulk RNA-seq data. Both sample level metrics and visualizations are generated. The QC script is designed to be run after alignment and quantification, but before differential expression analysis."
LABEL base-image="rocker/r-ver:4.6.1"
ENV DEBIAN_FRONTEND=noninteractive

# System libraries required by CRAN/Bioconductor packages used in the QC script.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff5-dev \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install package managers with pinned versions.
# Bootstrap remotes, then force the pinned remotes version for reproducibility.
RUN Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); install.packages('remotes', repos = 'https://cloud.r-project.org'); remotes::install_version('remotes', version = '2.5.0', repos = 'https://cloud.r-project.org'); remotes::install_version('pacman', version = '0.5.1', repos = 'https://cloud.r-project.org'); remotes::install_version('BiocManager', version = '1.30.26', repos = 'https://cloud.r-project.org')"

# Install CRAN packages used by the script with pinned versions.
RUN Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); remotes::install_version('logr', version = '1.3.9', repos = 'https://cloud.r-project.org'); remotes::install_version('dplyr', version = '1.1.4', repos = 'https://cloud.r-project.org'); remotes::install_version('tibble', version = '3.3.0', repos = 'https://cloud.r-project.org'); remotes::install_version('stringr', version = '1.5.1', repos = 'https://cloud.r-project.org'); remotes::install_version('patchwork', version = '1.3.1', repos = 'https://cloud.r-project.org'); remotes::install_version('ggplot2', version = '3.5.2', repos = 'https://cloud.r-project.org')"

# Pin Bioconductor release 3.23 for R 4.6.x.
# Resolved package versions for this release: DESeq2 1.52.0, tximport 1.40.0,
# and IHW 1.40.0.
RUN Rscript -e "BiocManager::install(version = '3.23', ask = FALSE, update = FALSE); BiocManager::install(c('DESeq2', 'tximport', 'IHW'), ask = FALSE, update = FALSE)"

WORKDIR /opt/

COPY bulk_rnaseq_quality_control.R /opt/bulk_rnaseq_quality_control.R
COPY bulk_rnaseq_qc_functions.R /opt/bulk_rnaseq_qc_functions.R

CMD ["Rscript", "/opt/bulk_rnaseq_quality_control.R", "--help"]
