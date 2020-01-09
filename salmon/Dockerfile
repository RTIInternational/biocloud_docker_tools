
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
    && apt-get install -y --no-install-recommends --fix-missing \
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
ENV PACKAGES git gcc g++ liblzma-dev libbz2-dev \
    zlib1g-dev curl unzip autoconf \
    libpsm-infinipath1 librdmacm1 libnghttp2-14 libboost-locale-dev \
    libboost-stacktrace-dev libjemalloc-dev

RUN apt-get update \
    && apt-get install -y --no-install-recommends --fix-missing ${PACKAGES} \
    && apt-get clean
    
RUN apt-get update \ 
    && apt-get install -y --no-install-recommends libboost-all-dev \
    && apt-get clean

# Install cmake 3.12 because FindIconv module is needed    
ENV version 3.12
ENV build 0

RUN apt remove --purge --auto-remove cmake \
    && mkdir ~/temp \
    && cd ~/temp \
    && wget https://cmake.org/files/v$version/cmake-$version.$build.tar.gz \
    && tar -xzvf cmake-$version.$build.tar.gz \
    && mv cmake-$version.$build/ /usr/share/ \
    && cd /usr/share/cmake-$version.$build/ \
    && ./bootstrap \
    && make -j$(nproc) \
    && make install \
    && ln -s /usr/share/cmake-$version.$build/bin/cmake /usr/bin/cmake \
    && rm -rf ~/temp

#### Install Salmon ####
ENV SALMON_VERSION 1.1.0
ENV CMAKE_REQUIRED_INCLUDES /usr/include

RUN apt-get update \
    && curl -k -L https://github.com/COMBINE-lab/salmon/archive/v${SALMON_VERSION}.tar.gz -o salmon-v${SALMON_VERSION}.tar.gz \
    && tar xzf salmon-v${SALMON_VERSION}.tar.gz \
    && cd salmon-${SALMON_VERSION} \
    && mkdir build \
    && cd build \
    && cmake .. -DCMAKE_INSTALL_PREFIX=/usr \
    && make \
    && make install \
    && ln -s /usr/bin/salmon /opt/salmon \
    && rm -rf /salmon-v${SALMON_VERSION}.tar.gz /salmon-${SALMON_VERSION}
    
WORKDIR /

ENV PATH pkg-config:$PATH:/opt/bin/
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/lib:/opt/lib

CMD ["salmon", "--help"]