# Base image
FROM ubuntu:18.04
# Maintainer and author
LABEL maintainer="Bryan Quach <bquach@rti.org>"

ENV DEBIAN_FRONTEND noninteractive

#### Basic Ubuntu setup ####
# Set a default user. Available via runtime flag `--user docker`
# Add user to 'staff' group and make home directory
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

RUN echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ bionic main' >> /etc/apt/sources.list \
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
    libglib2.0 \
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
    gcc \
    g++ \
    gsl-bin \
    libgsl-dev \
    libboost-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /

#### Install gwas_pw ####
RUN wget https://github.com/joepickrell/gwas-pw/archive/0.21.tar.gz \
    && tar -xzf 0.21.tar.gz \
    && rm 0.21.tar.gz \
    && mv gwas-pw-0.21 /opt/ \
    && cd /opt/gwas-pw-0.21/ \
    && ./configure \
    && make \
    && mv /opt/gwas-pw-0.21/src/gwas-pw /opt/ \
    && cd /opt \
    && rm -rf gwas-pw-0.21

# Add /opt to executables path list
ENV PATH=pkg-config:$PATH:/opt/

# Default command
CMD ["/opt/gwas-pw"]
