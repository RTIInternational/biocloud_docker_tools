
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
        wget \
        unzip \
        locales \
    && rm -rf /var/lib/apt/lists/*

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

#### Install tsv-utils and create binary executables in /opt ####

RUN wget https://github.com/eBay/tsv-utils/releases/download/v1.4.4/tsv-utils-v1.4.4_linux-x86_64_ldc2.tar.gz --no-check-certificate \
    && tar -zxf tsv-utils-v1.4.4_linux-x86_64_ldc2.tar.gz \
    && mv /tsv-utils-v1.4.4_linux-x86_64_ldc2 /opt/ \
    && chmod -R a+x /opt/tsv-utils-v1.4.4_linux-x86_64_ldc2/bin/ \
    && rm -f tsv-utils-v1.4.4_linux-x86_64_ldc2.tar.gz

WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/tsv-utils-v1.4.4_linux-x86_64_ldc2/bin/

CMD ["ls", "-l", "/opt/tsv-utils-v1.4.4_linux-x86_64_ldc2/bin/"]