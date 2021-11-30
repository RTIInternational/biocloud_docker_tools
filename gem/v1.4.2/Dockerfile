# Base image
FROM ubuntu:22.04

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

#### Basic Ubuntu setup ####

# Set a default user. Available via runtime flag `--user docker`
# Add user to 'staff' group and make home directory
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        dirmngr \
        software-properties-common \
        lsb-release \
        ed \
        less \
        locales \
        vim \
        wget \
        apt-transport-https \
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

#### Install GEM dependencies and GEM ####

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        build-essential \
        intel-mkl \
        libboost-all-dev \
    && rm -rf /var/lib/apt/lists/* \
    && wget https://github.com/large-scale-gxe-methods/GEM/archive/refs/tags/v1.4.2.tar.gz \
    && tar -xvzf v1.4.2.tar.gz
    && cd GEM-1.4.2/src \
    && make \
    && cp GEM /opt/

WORKDIR /

ENV PATH=$PATH:/opt/
