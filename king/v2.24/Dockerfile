
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
        unzip \
        locales \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgsl0-dev \
        gcc \
        g++ \
        libbz2-dev \
        liblzma-dev \
        libncurses5-dev \
    && rm -rf /var/lib/apt/lists/*

#### Download king pre-compiled binaries ####

RUN wget http://people.virginia.edu/~wc9c/KING/Linux-king.tar.gz \
    && tar xzvf Linux-king.tar.gz && mv king /opt/ \
    && rm -rf Linux-king.tar.gz

WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/

CMD ["king"]
