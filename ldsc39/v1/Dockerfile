FROM python:3.9-slim

LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL base-image="python:3.9-slim"
LABEL description="CBIIT's actively maintained Python 3 fork of LDSC (LD Score Regression), the engine behind ldlink.nih.gov/ldscore. Pinned to a commit with the gzip-input header fix for munge_sumstats.py already merged."
LABEL software-website="https://github.com/CBIIT/ldsc"
LABEL software-version="3.0.1"
LABEL license="https://www.gnu.org/licenses/gpl-3.0.html"

# Install git (needed to clone the pinned LDSC commit below), then drop apt caches
RUN apt-get update && apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

# Pin to a specific commit of CBIIT/ldsc's main branch (not a branch reference,
# so it can't silently change later). This commit already includes the fix for
# a gzip-input header bug in munge_sumstats.py (same fix as the still-open
# https://github.com/CBIIT/ldsc/pull/6, merged independently on main).
# Install the pinned Python dependencies, then drop the .git history and pip
# cache — neither is needed at runtime.
RUN git clone https://github.com/CBIIT/ldsc.git /opt/ldsc && \
    cd /opt/ldsc && \
    git checkout 1f09cf0 && \
    rm -rf .git && \
    pip install --no-cache-dir numpy==1.21.5 pandas==1.3.3 scipy==1.7.3 bitarray==2.6.0

# Make the LDSC scripts executable and put them on PATH
RUN chmod -R u+x /opt/ldsc
ENV PATH=/opt/ldsc:$PATH

# Default working directory for mounted input/output data
WORKDIR /data

# Default to printing usage; override with a specific ldsc.py/munge_sumstats.py command
CMD ["/opt/ldsc/ldsc.py", "--help"]
