FROM python:3.12

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"
LABEL description="GWASLab - Python toolkit for handling GWAS summary statistics"
LABEL software-website="https://cloufield.github.io/gwaslab/"
LABEL software-version="4.2.2"

# Install system dependencies, build tools needed for compilation (e.g. C/C++ extensions),
# and fonts for plotting
RUN apt update && apt install -y --no-install-recommends \
    build-essential \
    bcftools \
    ca-certificates \
    cabextract \
    gzip \
    libfontenc1 \
    libmspack0 \
    procps \
    tabix \
    wget \
    xfonts-encodings \
    xfonts-utils \
    && wget http://ftp.de.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.8_all.deb \
    && dpkg -i ttf-mscorefonts-installer_3.8_all.deb \
    && rm ttf-mscorefonts-installer_3.8_all.deb \
    && fc-cache -f -v \
    && pip install --upgrade pip \
    && python -m pip install --no-cache-dir "gwaslab==4.2.2" \
    && python -m pip install --upgrade "numpy>=2.0" \
    && python -m pip install --no-cache-dir notebook \
    && apt purge -y --auto-remove build-essential \
    && rm -rf /var/lib/apt/lists/*

# Add plotting, sumstats, reference, and io CLI wrappers
ADD io/gwaslab_*.py /opt/
ADD plot/gwaslab_plot_*.py /opt/
ADD reference/gwaslab_*.py /opt/
ADD sumstats/core/gwaslab_sumstats_*.py /opt/
ADD sumstats/fix/gwaslab_sumstats_*.py /opt/
ADD sumstats/filter/gwaslab_sumstats_*.py /opt/
ADD sumstats/downstream/gwaslab_sumstats_*.py /opt/
ADD sumstats/gwaslab_sumstats_common.py /opt/
ADD workflows/gwaslab*.py /opt/
RUN chmod 755 /opt/gwaslab_*.py
ENV PATH="/opt:${PATH}"

# Set working directory
RUN mkdir -p /data
WORKDIR /data
RUN chmod 777 /data
ENV GWASLAB_DATA_DIR="/data"
ENV GWASLAB_CONFIG="/data/config.json"
ENV MPLCONFIGDIR="/data"
ENV XDG_CACHE_HOME=/data/.cache


# Default command
CMD ["python3", "-c", "import gwaslab as gl; print(f'GWASLab version: {gl.__version__}')"]
