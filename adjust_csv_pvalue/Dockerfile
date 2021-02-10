FROM ubuntu:18.04

# =====================================================================
# Install R
# =====================================================================

# Don't print "debconf: unable to initialize frontend: Dialog" messages
ARG DEBIAN_FRONTEND=noninteractive

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


# Install R packages
RUN R -e 'install.packages(c("optparse"), repos="http://cran.us.r-project.org")'

# =====================================================================
# Add accesory scripts included in directory
# =====================================================================

# Add R helper script
ADD adjust_csv_pvalue.R /opt/

# Change permissions to make things exectuable
RUN chmod -R u+x /opt/

# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Add default command to show help message
CMD Rscript /opt/adjust_csv_pvalue.R --help