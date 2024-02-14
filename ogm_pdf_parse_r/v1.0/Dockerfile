#----------------------------------------------------------------
# Use the official R image as a base
#----------------------------------------------------------------
FROM r-base:4.3.2

#----------------------------------------------------------------
# Container Metadata
#----------------------------------------------------------------
LABEL maintainer="Mike Enger <menger@rti.org>"
LABEL description="PDF parser for optical genome mapping outputs"
LABEL base.image="r-base:v4.3.2"
LABEL software="R, pdftools, dplyr, openxlsx, getopt"
LABEL software-website="https://www.r-project.org/ https://dplyr.tidyverse.org/ https://cran.r-project.org/web/packages/openxlsx/index.html https://cran.r-project.org/web/packages/pdftools/pdftools.pdf https://cran.r-project.org/web/packages/getopt/index.html"
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
	libxml2-dev \
	libcurl4-openssl-dev \
	libssl-dev \
	libjpeg-dev \
	libicu-dev \
	libpq-dev \
	libmysqlclient-dev \
	libpoppler-cpp-dev && \
	apt-get clean && \
	apt-get autoremove

#----------------------------------------------------------------
# Install R Packages
#----------------------------------------------------------------
ENV R_VERSION 4.3.2

# Configure CRAN for package retrieval
RUN echo "r <- getOption('repos'); r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile
RUN Rscript -e "install.packages('getopt', dependencies = T)"
RUN Rscript -e "install.packages(c('RMySQL', 'RPostgreSQL', 'dplyr'), dependencies = T)"
RUN Rscript -e "install.packages(c('xml2', 'curl', 'qpdf', 'pdftools', dependencies = T))"
RUN Rscript -e "install.packages('openxlsx', dependencies = T)"
RUN Rscript -e "library('getopt');##### R SESSION INFORMATION #####; sessionInfo()"

#----------------------------------------------------------------
# Copy over analysis scripts
#----------------------------------------------------------------
ADD ogm_pdf_parse.R /opt/parser/ogm_pdf_parse.R

#----------------------------------------------------------------
# Set working dir
#----------------------------------------------------------------
WORKDIR /data/

#----------------------------------------------------------------
# Set default command or entrypoint if needed
#----------------------------------------------------------------
CMD ["Rscript", "/opt/parser/ogm_pdf_parse.R"]
