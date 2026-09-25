FROM rocker/r-ver:4.2.3

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Install Python dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    python3 \
    python3-pip \
    python3-pandas \
    python3-numpy \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN Rscript -e 'install.packages(c("pak", "optparse", "magrittr", "R.utils"), repos = "https://cloud.r-project.org")'
RUN Rscript -e 'pak::pkg_install(c("url::https://cran.r-project.org/src/contrib/Archive/lavaan/lavaan_0.6-15.tar.gz", "GenomicSEM/GenomicSEM")); stopifnot(packageVersion("lavaan") == package_version("0.6-15")); require(GenomicSEM); require(Matrix); require(stats)'

# Record installed package versions in the image.
RUN mkdir -p /opt/package_versions && \
    Rscript -e 'packages <- installed.packages()[, c("Package", "Version"), drop = FALSE]; write.table(packages, "/opt/package_versions/r-packages.tsv", sep = "\t", quote = FALSE, row.names = FALSE)' && \
    pip3 freeze | sort > /opt/package_versions/python-packages.txt && \
    dpkg-query -W -f='${binary:Package}\t${Version}\n' | sort > /opt/package_versions/debian-packages.tsv

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