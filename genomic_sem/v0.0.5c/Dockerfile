FROM bioconductor/bioconductor_docker:RELEASE_3_23

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Install Python dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-pandas \
    python3-numpy \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN Rscript -e 'install.packages("devtools"); library("devtools");'
RUN Rscript -e 'install.packages("optparse"); library("optparse");'
RUN Rscript -e 'install.packages("magrittr"); library("magrittr");'
RUN Rscript -e 'install.packages("R.utils"); library("R.utils");'
RUN Rscript -e 'pak::pak("GenomicSEM/GenomicSEM"); require(GenomicSEM); require(Matrix); require(stats)'

# Add R and Python helper scripts
ADD gsem_*.R gsem_*.py /opt/

# Change permissions to make things executable
RUN chmod 755 /opt/gsem_*.R /opt/gsem_*.py

# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Parallel settings
ENV OPENBLAS_NUM_THREADS=1
ENV OMP_NUM_THREADS=1
ENV MKL_NUM_THREADS=1
ENV NUMEXPR_NUM_THREADS=1
ENV VECLIB_MAXIMUM_THREADS=1
