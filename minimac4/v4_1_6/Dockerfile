# Base image
FROM ubuntu:22.04

# Maintainer and author
LABEL maintainer="Stephanie Giamberardino <sgiamberardino@rti.org>" \
      base-image="ubuntu:22.04" \
      description="minimac4 imputation software" \
      software-website="https://github.com/statgen/Minimac4" \
      software-version="v4.6.1"

#### Basic Ubuntu setup ####

# Set a default user. Available via runtime flag `--user docker`
# Add user to 'staff' group and make home directory
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
    && rm -rf /var/lib/apt/lists/*

#### Install minimac4 ####
RUN wget https://github.com/statgen/Minimac4/releases/download/v4.1.6/minimac4-4.1.6-Linux-x86_64.sh --no-check-certificate
RUN chmod +x minimac4-4.1.6-Linux-x86_64.sh
RUN ./minimac4-4.1.6-Linux-x86_64.sh --prefix=/opt --skip-license

# Set working directory and path
WORKDIR /
ENV PATH=pkg-config:$PATH:/opt/bin/

# Using CMD instead of ENTRYPOINT allows for easy interactive login with bash command.
# This way, overriding with --entrypoint is not necessary when logging in interactively.
CMD ["minimac4"]
