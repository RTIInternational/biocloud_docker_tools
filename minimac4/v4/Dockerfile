
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

#### Install minimac4 dependencies and minimac4 ####

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        cmake \
        python-dev \
        python-pip \
    && rm -rf /var/lib/apt/lists/* \
    && pip install wheel \
    && pip install setuptools \
    && pip install cget \
    && cget install --prefix /minimac_tmp statgen/Minimac4 \
    && cp /minimac_tmp/bin/minimac4 /opt/ \
    && rm -r /minimac_tmp

WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/

CMD ["minimac4", "--help"]