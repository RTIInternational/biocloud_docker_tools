
# Base image
FROM ubuntu:18.04

# Maintainer and author
LABEL maintainer="Alex Waldrop<awaldrop@rti.org>"

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
        autoconf \
        git \
        automake \
        pigz \
    && rm -rf /var/lib/apt/lists/*

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

#### Install rfmix ####

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        libbz2-dev \
        liblzma-dev \
        libncurses5-dev \
    && rm -rf /var/lib/apt/lists/* \
    && git clone https://github.com/slowkoni/rfmix.git \
    && cd /rfmix \
    && autoreconf --force --install \
    && ./configure --prefix=/rfmix \
    && make \
    && cp /rfmix/*.pl /opt/ \
    && cp /rfmix/rfmix /opt/ \
    && cp /rfmix/simulate /opt/ \
    && rm -rf /rfmix

WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/

CMD ["rfmix"]
