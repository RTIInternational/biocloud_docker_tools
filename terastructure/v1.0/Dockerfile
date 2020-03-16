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
        software-properties-common \
        vim \
        git \
        make \
        libglib2.0 \
    && rm -rf /var/lib/apt/lists/*

#### Install terastructure dependencies and terastructure ####


RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgsl0-dev \
        gcc \
        g++ \
        libbz2-dev \
        liblzma-dev \
        libncurses5-dev \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /opt/terastructure/ \
    && git clone https://github.com/StoreyLab/terastructure /opt/terastructure  \
    && cd /opt/terastructure \
    && ./configure \
    && make \
    && make install \
    && rm -rf /opt/terastructure

WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/

CMD ["terastructure"]