# Base image
FROM ubuntu:18.04

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

#### Install bcftools dependencies and bcftools ####

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        libbz2-dev \
        liblzma-dev \
    && rm -rf /var/lib/apt/lists/* \
    && wget https://github.com/samtools/bcftools/releases/download/1.9/bcftools-1.9.tar.bz2 \
    && tar -xf bcftools-1.9.tar.bz2 \
    && cd /bcftools-1.9 \
    && ./configure --prefix=/bcftools-1.9 \
    && make install \
    && cp /bcftools-1.9/bin/* /opt/ \
    && rm -rf bcftools-1.9.tar.bz2 bcftools-1.9

WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/

CMD ["bcftools", "--help"]