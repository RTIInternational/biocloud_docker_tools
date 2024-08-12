#----------------------------------------------------------------
# Use the official R image as a base
#----------------------------------------------------------------
FROM r-base:4.3.2

#----------------------------------------------------------------
# Container Metadata
#----------------------------------------------------------------
LABEL base.image="r-base:v4.3.2"
LABEL maintainer="Mike Enger <menger@rti.org>"
LABEL description="BDC Metadata Manifest Generator"
LABEL software="R, dplyr, httr, lubridate, stringr, sevenbridges2, getopt"
LABEL software-website="https://www.r-project.org/ https://dplyr.tidyverse.org/ hhttps://httr.r-lib.org/ https://github.com/tidyverse/lubridate https://stringr.tidyverse.org/ https://cran.r-project.org/web/packages/sevenbridges2/index.html https://cran.r-project.org/web/packages/getopt/index.html"
LABEL software.version="1.0.0"
LABEL license="GPL-2 | GPL-3 "
LABEL about.tags="RMIP"

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

#----------------------------------------------------------------
# Install required command line tools and packages
#----------------------------------------------------------------
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get -y upgrade && \
	apt-get install -y --no-install-recommends \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    build-essential && \
    apt-get clean && \
    apt-get autoremove

#----------------------------------------------------------------
# Install R Packages
#----------------------------------------------------------------
ENV R_VERSION 4.3.2

# Configure CRAN for package retrieval
RUN echo "r <- getOption('repos'); r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile
RUN Rscript -e "install.packages('getopt', dependencies = T)"
RUN Rscript -e "install.packages(c('dplyr', 'httr', 'stringr','lubridate','sevenbridges2'), dependencies = T)"
RUN Rscript -e "library('getopt');##### R SESSION INFORMATION #####; sessionInfo()"

#----------------------------------------------------------------
# Copy over analysis scripts
#----------------------------------------------------------------
ADD generate_metadata_manifest.R /opt/generate_metadata_manifest.R

#----------------------------------------------------------------
# Set working dir
#----------------------------------------------------------------
WORKDIR /data/

#----------------------------------------------------------------
# Set default command or entrypoint if needed
#----------------------------------------------------------------
CMD ["Rscript", "/opt/generate_metadata_manifest.R"]
