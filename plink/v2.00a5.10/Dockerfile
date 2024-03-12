# Base image
FROM ubuntu:22.04

# Maintainer and author
LABEL maintainer="Jesse Marks <jmarks@rti.org>" \
      base-image="ubuntu:22.04" \
      description="Plink2 a free and open-source whole-genome association analysis toolset." \
      software-website="https://www.cog-genomics.org/plink/2.0/" \
      software-version="v2.00a5.10" \
      git-commit="2b95c238d695a13b0f370378e976d8bd1d1282eb"

# Basic Ubuntu setup with combined commands
RUN apt update && apt install -y \
        less \
        vim \
        wget \
        unzip \
    && rm -rf /var/lib/apt/lists/*

#### Install Plink dependencies and Plink ####
RUN wget https://s3.amazonaws.com/plink2-assets/alpha5/plink2_linux_x86_64_20240105.zip \
    && unzip plink2_linux_x86_64_20240105.zip -d plink_tmp \
    && cp /plink_tmp/plink2 /opt/ \
    && rm -rf plink2_linux_x86_64_20240105.zip plink_tmp

# Set working directory and path
WORKDIR /
ENV PATH=pkg-config:$PATH:/opt/

# Using CMD instead of ENTRYPOINT allows for easy interactive login with bash command.
# This way, overriding with --entrypoint is not necessary when logging in interactively.
CMD ["plink2"]
