# Base image
FROM ubuntu:22.04

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

#### Install general packages
RUN rm -Rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install -y \
        wget \
        less \
        cpanminus

#### Install PERL modules ####
RUN cpanm install JSON

#### Install plink2 ####
ENV DEBIAN_FRONTEND noninteractive
RUN wget https://s3.amazonaws.com/plink2-assets/alpha3/plink2_linux_x86_64_20220519.zip \
    && unzip plink2_linux_x86_64_20220519.zip -d /plink_tmp \
    && cp /plink_tmp/plink2 /opt/ \
    && rm -rf plink2_linux_x86_64_20220519.zip plink_tmp
ENV PATH=pkg-config:$PATH:/opt/
RUN rm -Rf /var/lib/apt/lists/*

#### Install custom scripts ####
# Add scripts
ADD extract_gcf_variants.pl /opt/
ADD entrypoint.sh /opt/
# Change permissions
RUN chmod 755 /opt/extract_gcf_variants.pl
RUN chmod 755 /opt/entrypoint.sh

WORKDIR /data

ENTRYPOINT [ "/opt/entrypoint.sh" ]

