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

#### Install METAL dependencies, METAL, and METAL patch ####

ADD metal-2010-02-08-patch2.tar.gz /

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
    && wget http://csg.sph.umich.edu/abecasis/Metal/download/generic-metal-2010-02-08.tar.gz \
    && tar xvzf generic-metal-2010-02-08.tar.gz \
    && tar xvzf metal-2010-02-08-patch2.tar.gz \
    && cd generic-metal \
    && mv libsrc/Parameters.cpp libsrc/Parameters_old.cpp \
    && perl -pe 's/bool legacy_count/int legacy_count/;' libsrc/Parameters_old.cpp > libsrc/Parameters.cpp \
    && patch -b -p1 < ../metal-2010-02-08-patch2/metal-2010-02-08-modified2.patch \
    && make all \
    && make install INSTALLDIR=/opt

WORKDIR /

ENV PATH=$PATH:/opt/
