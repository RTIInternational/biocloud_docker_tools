
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

#### Install dependencies ####

RUN apt-get update \ 
    && apt-get install -y --no-install-recommends \
        unzip \
        bison \
        bc \
        default-jdk \
        default-jre \
        gcc \
        g++ \
        libxcb-dri3-0 \
        libxml2-dev \
        libmagic-dev \
        libhdf5-dev \
        python

#### Install NCBI tools ####
RUN mkdir /opt/ncbi \
    && cd /opt/ncbi \
    && wget https://github.com/ncbi/ngs/archive/2.9.6.tar.gz \
    && tar -xzf /opt/ncbi/2.9.6.tar.gz \
    && rm /opt/ncbi/2.9.6.tar.gz \
    && wget https://github.com/ncbi/ncbi-vdb/archive/2.9.6.tar.gz \
    && tar -xzf /opt/ncbi/2.9.6.tar.gz \
    && rm /opt/ncbi/2.9.6.tar.gz \
    && cd /opt/ncbi/ngs-2.9.6 \
    && ./configure \
    && make -C ngs-sdk \
    && make -C ngs-java \
    && make -C ngs-sdk install \
    && make -C ngs-java install \ 
    && cd /opt/ncbi/ncbi-vdb-2.9.6 \
    && ./configure \
    && make \
    && make install \
    && cd /opt/ncbi/ngs-2.9.6 \
    && ./configure \
    && make -C ngs-python \
    && make -C ngs-python install
    
ENV LD_LIBRARY_PATH=/usr/local/ngs/ngs-sdk/lib64:/usr/local/ncbi/ncbi-vdb/lib64:$LD_LIBRARY_PATH
ENV NCBI_VDB_LIBDIR=/usr/local/ncbi/ncbi-vdb/lib64
WORKDIR /

#### Install HISAT2 ####
RUN wget ftp://ftp.ccb.jhu.edu/pub/infphilo/hisat2/downloads/hisat2-2.1.0-source.zip \
    && unzip hisat2-2.1.0-source.zip \
    && rm hisat2-2.1.0-source.zip \
    && mv hisat2-2.1.0 /opt/ \
    && cd /opt/hisat2-2.1.0/ \
    && make USE_SRA=1 NCBI_NGS_DIR=/usr/local/ngs/ngs-sdk NCBI_VDB_DIR=/usr/local/ncbi/ncbi-vdb \
    && cp hisat2-* *.py /opt/ \
    && cp hisat2 /opt/ \
    && cp scripts/* /opt/ \
    && cp hisatgenotype_modules/* /opt/ \
    && cp hisatgenotype_scripts/* /opt/ 
    
WORKDIR /

# Add /opt to executables path list
ENV PATH=pkg-config:$PATH:/opt/

# Default command to list all executables in /opt/
# Print all names that are not directories
CMD ["find", "/opt/", "-maxdepth", "1", "-not", "-type", "d", "-printf", "%f\n"]