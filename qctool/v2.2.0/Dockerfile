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
        unzip \
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
        python2 \
        build-essential \
        intel-mkl \
        libboost-all-dev \
    && wget https://code.enkre.net/qctool/zip/release/qctool.tgz \
    && unzip qctool.tgz \
    && cd qctool \
    && python2 ./waf configure \
    && python2 ./waf \
    && cp /qctool/build/release/apps/qctool_v2.2.0 /opt/

WORKDIR /

ENV PATH=$PATH:/opt/
