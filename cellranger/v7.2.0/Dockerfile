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
RUN curl -o cellranger-7.2.0.tar.gz "https://cf.10xgenomics.com/releases/cell-exp/cellranger-7.2.0.tar.gz?Expires=1696039695&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA&Signature=J8boUOw-~-wL~21yRmpJ5q5xOGetDKjaqxghUzGD4SIXJQA5Opnl197lyG0CrCOESqrPh2olhfgKfSBmF0-lcQnwH8onnFJ6-XkMCG2l1dqIhU6~UpWXGz95WHHGsXojVv9gllcyYL~lJwRFJLZbbY3C0pR5wEi5~onf4GkOKlT1q~o~pWwX5i0W7Cl4sWy4-MnS0sm6Y9lRmtGYP-TGZwdL4o3A0XUmMjnCn3O-Fc0DuiF1Gm5kg3RKswEOPHHZuXtd9VIx73ATOsiqXpcVUUWkzE8IFOFHVpmoE2Vd0qERbHqu1MxSUrzqL2mgEMgzLjBTEC~AWmflRI4qby-V4w__"

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
