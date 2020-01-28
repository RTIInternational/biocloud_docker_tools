
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

#### Install dependencies and multiqc ####

RUN apt-get update \ 
    && apt-get install -y --no-install-recommends \
        gcc \
        python3.6 \
        python3-dev \
        python3-pip \
    && pip3 install wheel \
    && pip3 install setuptools \
    && pip3 install pyyaml
    
RUN wget https://github.com/ewels/MultiQC/archive/v1.7.tar.gz \
    && tar -xzf v1.7.tar.gz \
    && cd /MultiQC-1.7/ \
    && python3 setup.py install --install-scripts=/opt \
    && cd / \
    && rm -rf /MultiQC-1.7 \
    && rm -r v1.7.tar.gz

# Disable pyYAML loader warning 
ENV PYTHONWARNINGS=ignore:'calling yaml.load() without Loader'

WORKDIR /

# Add /opt to executables path list
ENV PATH=pkg-config:$PATH:/opt/

CMD ["multiqc","--help"]