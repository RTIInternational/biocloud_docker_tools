
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

#### Install eigenMT dependencies and eigenMT ####

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        unzip \
        gcc \
        g++ \
        libbz2-dev \
        liblzma-dev \
        python3 \
        python3-pip \
    && pip3 install setuptools wheel \
    && pip3 install scipy numpy sklearn pandas \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/joed3/eigenMT/archive/master.zip \
    && unzip master.zip \
    && cp /eigenMT-master/eigenMT.py /opt/ \
    && rm -rf /master.zip /eigenMT-master
    
WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/

CMD ["python3", "/opt/eigenMT.py", "-h"]