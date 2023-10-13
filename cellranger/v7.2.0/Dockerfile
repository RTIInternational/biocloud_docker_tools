# Use an appropriate base image
FROM ubuntu:22.04

# Set maintainer label
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL description="Cell Ranger software for single-cell analyses."
LABEL software-website="https://support.10xgenomics.com/single-cell-gene-expression/software/overview/welcome"
LABEL software-version="7.2.0"
LABEL license="https://www.10xgenomics.com/legal/end-user-software-license-agreement"

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoremove

# Set working directory
WORKDIR /opt

# Download and unpack the cellranger-7.1.0.tar.gz tar file
RUN curl -o cellranger-7.2.0.tar.gz "https://cf.10xgenomics.com/releases/cell-exp/cellranger-7.2.0.tar.gz?Expires=1697256046&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA&Signature=WSr9QEqQgKktdrM7GnIX26Z1-eTf3Y939X0RmVHVyTHcz97dphrPeYxvFZo7-BikxFLLakE1SUVwuITGpw-~0ga3K3Ip4ogspsqv85mYtdG1OVxx6FHJcUN5Lsk~iZ1jVLb8J67-nlfhfKuTRjpZvdT~I-oF9YcrJXRa1ombOVg1lM4wEzSWqkhanduBMVTVfKIf8-BI5dVJEMP6yH298ol3MCF6FJnwiuHiQ12D7rcWfbJ-847RjZOTjNneN1A7uzkzLCJNRwm1AMCvYUOngdpvlyePM7eJOQ2jDsGsJiUNZ4TJEFBEhBGtHaRlOTuXrZqiEXn3JNjN~DVTe3cfcw__"

# Download and unpack reference data files
#RUN curl -O https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2020-A.tar.gz

# Unpack the downloaded files
RUN tar -xzvf cellranger-7.2.0.tar.gz
#RUN tar -xzvf refdata-gex-GRCh38-2020-A.tar.gz

# Remove downloaded tar.gz files
RUN rm cellranger-7.2.0.tar.gz 
#RUN rm refdata-gex-GRCh38-2020-A.tar.gz

# Add Cell Ranger directory to $PATH
ENV PATH="/opt/cellranger-7.2.0:${PATH}"

# Set default command or entrypoint if needed
CMD ["cellranger"]
