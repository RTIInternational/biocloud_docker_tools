FROM ubuntu:18.04

# =====================================================================
# Install R
# =====================================================================

# Maintainer and author
LABEL maintainer="Alex Waldrop <awaldrop@rti.org>"

#### Basic Ubuntu setup ####

# Set a default user. Available via runtime flag `--user docker`
# Add user to 'staff' group and make home directory
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

# Don't print "debconf: unable to initialize frontend: Dialog" messages
ENV DEBIAN_FRONTEND noninteractive

# Need this to add R repo
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ bionic main' >> /etc/apt/sources.list

# Add R apt repository
RUN apt-get update && apt-get install -y gnupg2
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN echo "deb http://cran.r-project.org/bin/linux/ubuntu bionic-cran35/" > /etc/apt/sources.list.d/cran.list

# Install basic stuff and R
RUN apt-get update && apt-get install -y \
    locales \
    git \
    vim-tiny \
    less \
    wget \
    r-base \
    fonts-texgyre \
    texinfo

RUN locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

RUN echo 'options(\n\
  repos = c(CRAN = "https://cloud.r-project.org/"),\n\
  download.file.method = "libcurl",\n\
  # Detect number of physical cores\n\
  Ncpus = parallel::detectCores(logical=FALSE)\n\
)' >> /etc/R/Rprofile.site

# =====================================================================
# Add accesory scripts included in directory
# =====================================================================


# Add R helper script
ADD generate_gwas_plots.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/generate_gwas_plots.R

# Set wrkdir
RUN mkdir /data
WORKDIR /data

