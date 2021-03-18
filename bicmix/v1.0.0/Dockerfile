
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
    
RUN echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ focal main' >> /etc/apt/sources.list \
    && apt-get update \ 
    && apt-get install -y --no-install-recommends \
        dirmngr \
        software-properties-common \
        lsb-release \
        ed \
        less \
        locales \
        vim \
        wget \
        ca-certificates \
        fonts-texgyre \
        make \
        libglib2.0-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

#### Install dependencies ####
RUN apt-get update \ 
    && apt-get install -y --no-install-recommends \
        unzip \
        gcc \
        g++ \
        gsl-bin \
        libgsl-dev \
        libboost-dev \
        libeigen3-dev \
        libopenblas-base \
        liblapack64-dev \
        gpg-agent \
    && rm -rf /var/lib/apt/lists/*


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
RUN Rscript -e 'install.packages(c("BiocManager", "Matrix", "GeneNet", "argparser"));' \
    && Rscript -e 'BiocManager::install(version = "3.11", ask = F);'
RUN Rscript -e 'BiocManager::install(c("reshape2", "ggplot2"), version = "3.11");'

WORKDIR /


#### Install bicmix ####
RUN wget https://github.com/bryancquach/BicMix/archive/v1.0.0.zip \
    && unzip v1.0.0.zip \
    && rm v1.0.0.zip \
    && mv BicMix-1.0.0 /opt/ \
    && cd /opt/BicMix-1.0.0/ \
    && perl -i -pe 's/Your_library/usr\/include/g' Makefile \
    && mv /usr/include/eigen3/Eigen/ /usr/include/ \
    && make \
    && mv /opt/BicMix-1.0.0/BicMix /opt/ \
    && cd / \
    && rm -rf /opt/BicMix-1.0.0

#### Add network building script ####
RUN wget https://github.com/bryancquach/twn_tsn/archive/master.zip \
    && unzip /master.zip \
    && mv /twn_tsn-master/tsn/recover_TSN.R /opt \
    && rm -rf /master.zip /twn_tsn-master
    
WORKDIR /

# Add /opt to executables path list
ENV PATH=pkg-config:$PATH:/opt/

# Default command 
CMD ["ls", "-1", "/opt/"]
