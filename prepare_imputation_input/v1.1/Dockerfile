FROM python:3.7.6-slim-stretch

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
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
        unzip \
        pigz \
        gcc \
        make \
        bzip2 \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

#### Install plink ####
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

#### Install bgzip ####
RUN apt-get install -y wget gcc make bzip2 zlib1g-dev libbz2-dev liblzma-dev

RUN wget -nv https://github.com/samtools/htslib/releases/download/1.9/htslib-1.9.tar.bz2 && \
    tar xf htslib-1.9.tar.bz2 && \
    cd htslib-1.9 && \
    ./configure --prefix=/htslib-1.9 && \
    make && \
    make install && \
    make clean && \
    cp /htslib-1.9/bin/* /opt/ && \
    cd / && \
    rm -rf htslib-1.9.tar.bz2 htslib-1.9

#### Install custom script ####
# Add scripts to make it run
ADD prepare_imputation_input.py /

# Add to /opt folder
RUN mv prepare_imputation_input.py /opt/

# Install libraries
RUN pip install pandas

# Get rid of stuff to make space
RUN apt-get remove -y wget gcc make && \
    apt-get autoclean -y

# Add opt to path folder
ENV PATH=pkg-config:$PATH:/opt/

# Set wrkdir
RUN mkdir /data
WORKDIR /data

RUN chmod 755 /opt/prepare_imputation_input.py

CMD ["python", "/opt/prepare_imputation_input.py", "--help"]
