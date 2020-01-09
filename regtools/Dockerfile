##################### Set Inital Image to work from ############################
FROM ubuntu:18.04


##################### Add Container Labels #####################################
LABEL maintainer="Jesse Marks <jmarks@rti.org>"


##################### Install System Dependencies ##############################
RUN echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ bionic main' >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        vim \
        cmake \
        zlib1g-dev \
        build-essential \
        ca-certificates \
        wget


##################### Install Regtools #########################################
RUN wget https://github.com/griffithlab/regtools/archive/0.5.1.tar.gz
RUN tar -xvzf 0.5.1.tar.gz

# build tool
RUN chmod -R u+x /regtools-0.5.1 && \
    mkdir /regtools-0.5.1/build && \
    cd /regtools-0.5.1/build && \
    cmake .. && \
    make

# clean up image
RUN mv /regtools-0.5.1/build/regtools /opt/ && \
    rm -rf /regtools-0.5.1 && \
    rm 0.5.1.tar.gz && \
    apt-get autoremove && \
    rm -rf /tmp/*

ENV PATH="/opt/:${PATH}"
WORKDIR /

# default help command
CMD  ["./opt/regtools"]
