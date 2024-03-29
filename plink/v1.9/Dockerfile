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

# RUN echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ bionic main' >> /etc/apt/sources.list \
RUN apt-get update \ 
    && apt-get install -y --no-install-recommends \
        curl \
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
        unzip \
        pigz \
        gcc \
        g++ \
        gfortran \
        libc-bin \
        libc-dev \
        libblas-dev \
        liblapack-dev \
        libatlas-base-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

#### Install plink dependencies and plink ####

# RUN wget http://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20200219.zip \
#     && unzip plink_linux_x86_64_20200219.zip -d /plink_tmp \
#     && cp /plink_tmp/plink /opt/ \
#     && rm -rf plink_linux_x86_64_20200219.zip plink_tmp

# Plink v1.90 beta 5
# https://www.cog-genomics.org/plink/1.9/dev
# https://www.cog-genomics.org/plink/
RUN wget https://github.com/chrchang/plink-ng/archive/refs/tags/b15c19f.tar.gz \
    && tar -xvzf b15c19f.tar.gz \
    && mv plink-ng-b15c19f/ /plink_tmp/

COPY plink_common.h /plink_tmp/1.9/plink_common.h

COPY sse2neon.h /plink_tmp/1.9/sse2neon.h 
COPY SFMT.h /plink_tmp/1.9/SFMT.h 

RUN cd plink_tmp/1.9/ \
    && ./plink_first_compile \
    && cp /plink_tmp/1.9/plink /opt/plink \
    && cd / \
    && rm -rf b15c19f.tar.gz plink_tmp

WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/

CMD ["plink"]

