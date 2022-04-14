FROM ubuntu:18.04


############################### Add Container Labels ####################################
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL software="MAGMA"
LABEL software.version="v1.10 "
LABEL website="https://ctg.cncr.nl/software/magma"
LABEL description="Tool for gene and gene-set analysis of GWAS data."


################################ Defaults ###############################################
# disable prompt during packages installation
ARG DEBIAN_FRONTEND=noninteractive


############################### Install System Dependencies #############################

# Install basic system dependencies. Once all installation is completed, remove
# all packages cache to reduce the size of the custom image.

RUN apt update && apt install -y --no-install-recommends \
  vim \
  wget \
  unzip \
  g++ \
  make \
  ca-certificates \
 && rm -rf /var/lib/apt/lists/* && apt clean

################################## Install EIGENSOFT ######################################

# Download from source, unpack, cleanup, and move to appropriate dir
RUN cd /opt \
  && wget https://ctg.cncr.nl/software/MAGMA/prog/magma_v1.10_source.zip \
  && unzip magma_v1.10_source.zip \
  && make

# Download gene location files build 37
RUN mkdir /opt/build37/ \
  && cd /opt/build37/ \
  && wget https://ctg.cncr.nl/software/MAGMA/aux_files/NCBI37.3.zip \
  && unzip NCBI37.3.zip \
  && rm NCBI37.3.zip

# Download gene location files build 38
RUN mkdir /opt/build38/ \
  && cd /opt/build38/ \
  && wget https://ctg.cncr.nl/software/MAGMA/aux_files/NCBI38.zip \
  && unzip NCBI38.zip \
  && rm NCBI38.zip

# clean up
RUN rm /opt/magma_v1.10_source.zip

# default command
CMD  ["/opt/magma"]
