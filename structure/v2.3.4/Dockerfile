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

#### Install structure dependencies and structure ####

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6-i386 \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://web.stanford.edu/group/pritchardlab/structure_software/release_versions/v2.3.4/release/structure_linux_console.tar.gz \
    && tar -xzf /structure_linux_console.tar.gz \
    && mkdir /opt/data \
    && mv /console/structure /opt/ \
    && mv /console/mainparams /opt/data/ \
    && mv /console/extraparams /opt/data/ \
    && mv /console/testdata1 /opt/data/ \
    && rm -rf /console /structure_linux_console.tar.gz

WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/

CMD ["structure"]