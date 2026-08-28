FROM python:3.12-slim

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"
LABEL description="GWASLab - Python toolkit for handling GWAS summary statistics"
LABEL software-website="https://cloufield.github.io/gwaslab/"
LABEL software-version="4.2.2"

# Install system dependencies and build tools needed for compilation (e.g. C/C++ extensions)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    tabix \
    procps \
    gzip \
    ca-certificates \
    wget \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir "gwaslab==4.2.2" \
    && apt-get purge -y --auto-remove build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
RUN mkdir -p /data
WORKDIR /data

# Default command
CMD ["python3", "-c", "import gwaslab as gl; print(f'GWASLab version: {gl.__version__}')"]
