
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

#### Install fastQTL dependencies and fastQTL ####

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
#        libdpkg-perl \
#        libmono-system-configuration4.0 \
        libboost-regex1.65-dev \
        libboost-dev \
        libboost-iostreams-dev \
        libboost-program-options-dev \
        gcc \
        g++ \
        libgsl-dev \
        libblas-dev \
        zlib1g-dev \
        r-mathlib \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /root/Software/R-3.1.3/src/nmath/standalone \
    && mkdir -p /root/Software/R-3.1.3/src/include \
    && cp /usr/lib/libRmath* /root/Software/R-3.1.3/src/nmath/standalone/ \
    && wget http://fastqtl.sourceforge.net/files/FastQTL-2.184.linux.tgz \
    && tar -xf FastQTL-2.184.linux.tgz \
    && cd /FastQTL \
    && make \
    && cp /FastQTL/bin/fastQTL /opt/ \
    && rm -rf FastQTL-2.184.linux.tgz FastQTL

WORKDIR /

ENV PATH=pkg-config:$PATH

ENTRYPOINT ["/opt/fastQTL"]

CMD ["--help"]