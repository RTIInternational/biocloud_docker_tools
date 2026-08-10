FROM rocker/r-ver:4.4.1

# Add Container Labels
LABEL maintainer="Caryn Willis <cdwillis@rti.org>"
LABEL description="Tools for running quality control on bulk RNA-seq data. Both sample level metrics and visualizations are generated. The QC script is designed to be run after alignment and quantification, but before differential expression analysis."

ENV DEBIAN_FRONTEND=noninteractive

# System libraries required by CRAN/Bioconductor packages used in the QC script.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gfortran \
    coinor-libsymphony-dev \
    libglpk-dev \
    libuv1-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
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
    r-cran-rcppeigen \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install package managers with pinned versions.
RUN Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); install.packages('remotes'); remotes::install_version('pacman', version = '0.5.1', repos = 'https://cloud.r-project.org'); remotes::install_version('BiocManager', version = '1.30.26', repos = 'https://cloud.r-project.org'); remotes::install_version('remotes', version = '2.5.0', repos = 'https://cloud.r-project.org')"

# Install CRAN packages used by the script with pinned versions.
RUN Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); remotes::install_version('logr', version = '1.3.9', repos = 'https://cloud.r-project.org'); remotes::install_version('dplyr', version = '1.1.4', repos = 'https://cloud.r-project.org'); remotes::install_version('tibble', version = '3.3.0', repos = 'https://cloud.r-project.org'); remotes::install_version('stringr', version = '1.5.1', repos = 'https://cloud.r-project.org'); remotes::install_version('patchwork', version = '1.3.1', repos = 'https://cloud.r-project.org'); remotes::install_version('ggplot2', version = '3.5.2', repos = 'https://cloud.r-project.org')"

# Pin Bioconductor release for R 4.4.x and install required Bioc packages.
RUN Rscript -e "BiocManager::install(version = '3.20', ask = FALSE, update = FALSE); BiocManager::install(c('DESeq2', 'tximport', 'IHW', 'lpsymphony'), ask = FALSE, update = FALSE)"

# Reduce compiler memory use for RcppEigen, which otherwise can be OOM-killed.
RUN mkdir -p /root/.R \
    && printf 'CXXFLAGS=-O0 -g0\nCXX11FLAGS=-O0 -g0\nCXX14FLAGS=-O0 -g0\nCXX17FLAGS=-O0 -g0\nMAKEFLAGS=-j1\n' > /root/.R/Makevars \
    && Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); install.packages('RcppEigen')"

# Install omixjutsu from pinned GitHub commit for reproducibility.
# dependencies = NA installs only Depends/Imports/LinkingTo (not Suggests).
RUN Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); remotes::install_github('bryancquach/omixjutsu@d530c725c18567c69f00a3476388d6c8839b720f', upgrade = 'never', dependencies = NA)"

# Fail fast if the package did not install correctly.
RUN Rscript -e "stopifnot(requireNamespace('omixjutsu', quietly = TRUE)); cat('omixjutsu', as.character(packageVersion('omixjutsu')), '\n')"

WORKDIR /opt/

COPY bulk_rnaseq_quality_control.R /opt/bulk_rnaseq_quality_control.R

ENTRYPOINT ["Rscript", "/opt/bulk_rnaseq_quality_control.R"]
