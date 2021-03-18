
# Base image
FROM ubuntu:20.04

# Maintainer and author
LABEL maintainer="Bryan Quach <bquach@rti.org>"

#### Basic Ubuntu setup ####

# Set a default user. Available via runtime flag `--user docker` 
# Add user to 'staff' group and make home directory 
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

ENV DEBIAN_FRONTEND noninteractive
    
RUN echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ bionic main' >> /etc/apt/sources.list \
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
    && rm -rf /var/lib/apt/lists/*

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

#RUN add-apt-repository -y ppa:marutter/c2d4u3.5 \
#   && apt-get update \
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
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
    && cp /etc/apt/sources.list /etc/apt/sources.list~ \
    && sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list \
    && apt-get update \
    && apt-get build-dep -y r-base  \
    && wget https://cran.r-project.org/src/base/R-4/R-4.0.1.tar.gz \
    && tar -xzf R-4.0.1.tar.gz \
    && rm R-4.0.1.tar.gz \
    && cd R-4.0.1/ \
    && ./configure --prefix=/usr/lib/R/ --with-blas --with-lapack \
    && make \
    && make install \
    && ln -s /usr/lib/R/bin/R /bin/R \
    && ln -s /usr/lib/R/bin/Rscript /bin/Rscript \
    && cd .. \
    && rm -rf R-4.0.1

# Add R repo to get more R versions
# Install littler, and create a link for littler in /usr/local/bin
# Set a default CRAN repo, and make sure littler knows about it
# Install stringr to make dococt install (from source) easier
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
    && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/' \
    && apt-get clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libxcb-shm0 \
    && apt-get install -y --no-install-recommends \
        r-base-core
RUN apt-get install -y --no-install-recommends r-recommended \
    r-base \
    r-base-dev \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*

#Install packages from CRAN and bioconductor:
RUN Rscript -e 'install.packages(c("BiocManager", "gplots", "knitr"));' \
    && Rscript -e 'BiocManager::install(version = "3.11", ask = F);'
RUN Rscript -e 'BiocManager::install(c("qplots", "pheatmap", "glmnet", "rsvd", "qvalue", "biomaRt"), version = "3.11");'

WORKDIR /


#### Install plier ####
RUN wget https://github.com/wgmao/PLIER/archive/v0.1.4.tar.gz \
    && R CMD INSTALL v0.1.4.tar.gz \
    && rm v0.1.4.tar.gz
    
WORKDIR /

# Add /opt to executables path list
ENV PATH=pkg-config:$PATH:/opt/

# Default command 
CMD ["ls", "-1", "/opt/"]
