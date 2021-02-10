########################## Set Inital Image to work from ################################
FROM ubuntu:18.04


############################### Add Container Labels ####################################
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL software="METAL"
LABEL software.version="2020-05-05"
LABEL website="https://github.com/statgen/METAL"
LABEL description="A tool for the meta-analysis of genome-wide association studies."

######################################## Defaults ####################################### 
# disable prompt during packages installation
ARG DEBIAN_FRONTEND=noninteractive

# Set a default user. Available via runtime flag `--user docker` 
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
# User should also have & own a home directory (for rstudio or linked volumes to work properly). 
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

############################### Install System Dependencies #############################

# Install basic system dependencies. Once all installation is completed, remove
# all packages cache to reduce the size of the custom image.
RUN echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ bionic main' >> /etc/apt/sources.list
RUN apt update && apt install -y --no-install-recommends \
    git \
    vim-tiny \
    cmake \
    zlib1g-dev \
    dirmngr \
    software-properties-common \
    build-essential \
    ca-certificates \
    wget \
    locales \
    openssl \
    build-essential \
    libssl-dev \
    libffi-dev \
 && rm -rf /var/lib/apt/lists/* && apt clean

################################## Install METAL ######################################

# download from source, unpack, cleanup, and move to appropriate dir
RUN wget https://github.com/statgen/METAL/archive/2020-05-05.tar.gz \
    && tar -xvzf 2020-05-05.tar.gz \
    && rm /2020-05-05.tar.gz \
    && mv METAL-2020-05-05 /opt/ 

# build and install
RUN mkdir /opt/METAL-2020-05-05/build/ \
    && cd /opt/METAL-2020-05-05/build/ \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make && make test && make install

# hyperlink in CODE approved dir and create file for default help command
RUN cd /opt/ \
    && ln -s METAL-2020-05-05/build/bin/metal \
    && echo "HELP" > /opt/help.txt

############################ Final system configurations ################################
RUN mkdir /data/

WORKDIR /data/

ENV PATH="/opt/:${PATH}"

# default help command
CMD  ["/opt/metal", "/opt/help.txt"]
