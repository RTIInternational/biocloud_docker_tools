
# Base image
FROM ubuntu:20.04

# Maintainer and author
LABEL maintainer="Bryan Quach <bquach@rti.org>"

#### Build code for installing R ####

# Set a default user. Available via runtime flag `--user docker` 
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
# User should also have & own a home directory (for rstudio or linked volumes to work properly). 
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

RUN echo 'deb http://mirror.umd.edu/ubuntu/ focal main' >> /etc/apt/sources.list \
    && apt-get update \ 
    && apt-get install -y --no-install-recommends \
        dirmngr \
        software-properties-common \
        lsb-release \
        ed \
        less \
        locales \
        vim-tiny \
        wget \
        ca-certificates \
        fonts-texgyre \
        libkeyutils1 \
    && rm -rf /var/lib/apt/lists/*

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# Install OpenBLAS for optimized R linear algebra computations
# Install littler, and create a link for littler in /usr/local/bin
# Set a default CRAN repo, and make sure littler knows about it
# Install stringr to make dococt install (from source) easier
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgfortran-9-dev-amd64-cross \
        libgfortran-9-dev-arm64-cross \
        cpp \
        libgirepository-1.0-1 \
        libglib2.0-0 \
        libelf1 \
        libssl-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        libmpx2 \
        curl \
        perl-base \
        gpg-agent \
        libxrender1 \
    && apt-get install -y --no-install-recommends libopenblas-base

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
    && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/' \
    && apt-get update \
    && apt-get install -y --no-install-recommends r-base-core \
        r-recommended \
        r-base \
        r-base-dev \
        r-recommended \
    && Rscript -e 'install.packages(c("littler", "stringr", "docopt"));' \
    && echo 'options(repos = c(CRAN = "https://cloud.r-project.org/"))' >> /etc/R/Rprofile.site \
    && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*

#### Install Matrix eQTL ####    

WORKDIR /

#Install packages from CRAN and bioconductor:
RUN wget https://cran.r-project.org/src/contrib/Archive/MatrixEQTL/MatrixEQTL_2.2.tar.gz \
    && wget https://cran.r-project.org/src/contrib/Archive/optparse/optparse_1.6.1.tar.gz \
    && wget https://cran.r-project.org/src/contrib/Archive/getopt/getopt_1.20.2.tar.gz \
    && Rscript -e 'install.packages("MatrixEQTL_2.2.tar.gz", repos = NULL);' \
    && Rscript -e 'install.packages("getopt_1.20.2.tar.gz", repos = NULL);' \
    && Rscript -e 'install.packages("optparse_1.6.1.tar.gz", repos = NULL);' \
    && rm MatrixEQTL_2.2.tar.gz optparse_1.6.1.tar.gz getopt_1.20.2.tar.gz

COPY run_matrix_eqtl.R /opt/

ENV PATH=pkg-config:$PATH

CMD ["Rscript", "/opt/run_matrix_eqtl.R", "--help"]
