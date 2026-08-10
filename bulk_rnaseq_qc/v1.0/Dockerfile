FROM rocker/r-ver:4.4.1

# Add Container Labels
LABEL maintainer="Caryn Willis <cdwillis@rti.org>"
LABEL description="Tools for running quality control on bulk RNA-seq data. Both sample level metrics and visualizations are generated. The QC script is designed to be run after alignment and quantification, but before differential expression analysis."
LABEL base-image="rocker/r-ver:4.4.1"
ENV DEBIAN_FRONTEND=noninteractive

# System libraries required by CRAN/Bioconductor packages used in the QC script.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential=12.9ubuntu3 \
    gfortran=4:11.2.0-1ubuntu1 \
    coinor-libsymphony-dev=5.6.17+dfsg-1 \
    libglpk-dev=5.0-1 \
    libuv1-dev=1.43.0-1ubuntu0.1 \
    libcurl4-openssl-dev=7.81.0-1ubuntu1.25 \
    libssl-dev=3.0.2-0ubuntu1.26 \
    libxml2-dev=2.9.13+dfsg-1ubuntu0.12 \
    libgit2-dev=1.1.0+dfsg.1-4.1ubuntu0.1 \
    libfontconfig1-dev=2.13.1-4.2ubuntu5 \
    libfreetype6-dev=2.11.1+dfsg-1ubuntu0.3 \
    libfribidi-dev=1.0.8-2ubuntu3.1 \
    libharfbuzz-dev=2.7.4-1ubuntu3.2 \
    libjpeg-dev=8c-2ubuntu10 \
    libpng-dev=1.6.37-3ubuntu0.5 \
    libtiff5-dev=4.3.0-6ubuntu0.13 \
    zlib1g-dev=1:1.2.11.dfsg-2ubuntu9.2 \
    libbz2-dev=1.0.8-5build1 \
    liblzma-dev=5.2.5-2ubuntu1.1 \
    r-cran-rcppeigen=0.3.3.9.1-1 \
    ca-certificates=20260601~22.04.1 \
    git=1:2.34.1-1ubuntu1.17 \
    && rm -rf /var/lib/apt/lists/*

# Install package managers with pinned versions.
# Bootstrap remotes, then force the pinned remotes version for reproducibility.
RUN Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); install.packages('remotes', repos = 'https://cloud.r-project.org'); remotes::install_version('remotes', version = '2.5.0', repos = 'https://cloud.r-project.org'); remotes::install_version('pacman', version = '0.5.1', repos = 'https://cloud.r-project.org'); remotes::install_version('BiocManager', version = '1.30.26', repos = 'https://cloud.r-project.org')"

# Install CRAN packages used by the script with pinned versions.
RUN Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); remotes::install_version('logr', version = '1.3.9', repos = 'https://cloud.r-project.org'); remotes::install_version('dplyr', version = '1.1.4', repos = 'https://cloud.r-project.org'); remotes::install_version('tibble', version = '3.3.0', repos = 'https://cloud.r-project.org'); remotes::install_version('stringr', version = '1.5.1', repos = 'https://cloud.r-project.org'); remotes::install_version('patchwork', version = '1.3.1', repos = 'https://cloud.r-project.org'); remotes::install_version('ggplot2', version = '3.5.2', repos = 'https://cloud.r-project.org')"

# Pin Bioconductor release for R 4.4.x and install required Bioc packages.
RUN Rscript -e "BiocManager::install(version = '3.20', ask = FALSE, update = FALSE); BiocManager::install(c('DESeq2', 'tximport', 'IHW', 'lpsymphony'), ask = FALSE, update = FALSE)"

# Reduce compiler memory use for RcppEigen, which otherwise can be OOM-killed.
RUN mkdir -p /root/.R \
    && printf 'CXXFLAGS=-O0 -g0\nCXX11FLAGS=-O0 -g0\nCXX14FLAGS=-O0 -g0\nCXX17FLAGS=-O0 -g0\nMAKEFLAGS=-j1\n' > /root/.R/Makevars \
    && Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); remotes::install_version('RcppEigen', version = '0.3.4.0.2', repos = 'https://cloud.r-project.org')"

# Install omixjutsu from pinned GitHub commit for reproducibility.
# dependencies = NA installs only Depends/Imports/LinkingTo (not Suggests).
RUN Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); remotes::install_github('bryancquach/omixjutsu@d530c725c18567c69f00a3476388d6c8839b720f', upgrade = 'never', dependencies = NA)"

# Fail fast if the package did not install correctly.
RUN Rscript -e "stopifnot(requireNamespace('omixjutsu', quietly = TRUE)); cat('omixjutsu', as.character(packageVersion('omixjutsu')), '\n')"

WORKDIR /opt/

COPY bulk_rnaseq_quality_control.R /opt/bulk_rnaseq_quality_control.R

CMD ["Rscript", "/opt/bulk_rnaseq_quality_control.R", "--help"]
