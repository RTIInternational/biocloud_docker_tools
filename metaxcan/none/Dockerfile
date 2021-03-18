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
RUN R -e 'install.packages(c("ggplot2", "dplyr"), repos="http://cran.us.r-project.org")'

# =====================================================================
# Install Miniconda for python dependencies
# =====================================================================
# Install basic stuff to be able to install Miniconda
RUN echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ bionic main' >> /etc/apt/sources.list
RUN apt-get update && apt-get install -y bzip2 \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    mercurial \
    subversion

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda2-4.5.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

# Set path to conda
ENV PATH /opt/conda/bin:$PATH

# Updating Anaconda packages
RUN conda update conda
RUN conda update --all

# =====================================================================
# Install required python packages
# =====================================================================
RUN conda create -n metaxcan python=2.7 \
    numpy=1.11.1 \
    pandas=0.18.1 \
    patsy=0.5.0 \
    statsmodels=0.8.0 \
    h5py=2.7.1 \
    h5py_cache=1.0 \
    mock=2.0.0 \
    sqlalchemy=1.2.14 \
    -c bioconda \
    -c moble

# =====================================================================
# Install Metaxcan and download sample data
# =====================================================================
RUN git clone https://github.com/hakyimlab/MetaXcan

# Download sample data
RUN mkdir /ref
RUN wget -O /ref/sample_data.tar.gz https://s3.amazonaws.com/imlab-open/Data/MetaXcan/sample_data/v0_5/sample_data.tar.gz && \
    tar xvf /ref/sample_data.tar.gz -C /ref && \
    chmod -R u+x /ref


# =====================================================================
# Standard docker image stuff
# =====================================================================
# Add metaxcan to /opt folder
ADD run.sh /
RUN mkdir /opt/code_docker_lib
RUN mv MetaXcan /opt/code_docker_lib
RUN mv run.sh /opt/code_docker_lib

# Change permissions to make things exectuable
RUN chmod u+x /opt/code_docker_lib/run.sh
RUN chmod -R u+x /opt/code_docker_lib/MetaXcan

# Set wrkdir
RUN mkdir -p /data
WORKDIR /data

# Create entrypoint that runs the run.sh wrapper script
#ENTRYPOINT ["/bin/bash", "/opt/code_docker_lib/run.sh"]
