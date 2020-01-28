
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

# Add R repo to get more R versions
# Install littler, and create a link for littler in /usr/local/bin
# Set a default CRAN repo, and make sure littler knows about it
# Install stringr to make dococt install (from source) easier
ENV R_BASE_VERSION 3.6.1-3bionic
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libssl-dev \
        gpg-agent
        
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
    && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/' \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-upgrade r-base-core=${R_BASE_VERSION}
RUN apt-get install -y --no-install-recommends --no-upgrade r-recommended=${R_BASE_VERSION} \
    r-base=${R_BASE_VERSION} \
    r-base-dev=${R_BASE_VERSION} \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*

#### Install dependencies ####
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        python3-pycurl \
        python3-dev \
        python3-pip \
    && pip3 install setuptools \
    && pip3 install wheel \
    && pip3 install pyBigWig \
    && pip3 install cython \
    && rm -rf /var/lib/apt/lists/*

#### Install rseqc ####
RUN wget https://files.pythonhosted.org/packages/3a/33/4cc945c2e54fe8fdd69d86b388c19f8bebe5d1773da9f209eb7210b3fa07/RSeQC-3.0.0.tar.gz \
    && tar -zxf RSeQC-3.0.0.tar.gz \
    && rm RSeQC-3.0.0.tar.gz \
    && cd /RSeQC-3.0.0 \
    && python3 setup.py install --install-scripts=/opt/ \
    && cd / \
    && rm -rf /RSeQC-3.0.0

WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/

CMD ["ls", "-1", "/opt/"]