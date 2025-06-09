# Base image
FROM ubuntu:24.04

# Maintainer and author
LABEL maintainer="Jesse Marks <jmarks@rti.org>" \
      base-image="ubuntu:24.04" \
      description="Plink2 a free and open-source whole-genome association analysis toolset." \
      software-website="https://www.cog-genomics.org/plink/2.0/" \
      software-version="v2.0.0-a.6.15" \
      git-commit="6adf7a57da1123104d23651fb12573a0842321b9"

# Basic Ubuntu setup with combined commands
RUN apt update && apt install -y \
        less \
        vim \
        wget \
        unzip \
    && rm -rf /var/lib/apt/lists/*

#### Install Plink dependencies and Plink ####
RUN wget https://s3.amazonaws.com/plink2-assets/alpha6/plink2_linux_amd_avx2_20250604.zip \
    && unzip plink2_linux_amd_avx2_20250604.zip -d plink_tmp \
    && cp /plink_tmp/plink2 /opt/ \
    && rm -rf plink2_linux_amd_avx2_20250604.zip plink_tmp


# Set working directory and path
WORKDIR /
ENV PATH=pkg-config:$PATH:/opt/

# Using CMD instead of ENTRYPOINT allows for easy interactive login with bash command.
# This way, overriding with --entrypoint is not necessary when logging in interactively.
CMD ["plink2"]
