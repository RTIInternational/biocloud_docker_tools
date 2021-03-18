
# Base image
FROM ubuntu:18.04

# Maintainer and author
LABEL maintainer="Bryan Quach <bquach@rti.org>"

#### Build code for installing R ####

# Set a default user. Available via runtime flag `--user docker` 
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
# User should also have & own a home directory (for rstudio or linked volumes to work properly). 
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

RUN echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ bionic main' >> /etc/apt/sources.list \
    && apt-get update \ 
    && apt-get install -y --no-install-recommends \
        dirmngr \
        software-properties-common \
        lsb-release \
        ed \
        less \
        locales \
        vim-tiny \
        wget \
        ca-certificates \
        fonts-texgyre \
    && rm -rf /var/lib/apt/lists/*

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# Add R repo to get R 3.5.1
# Install littler, and create a link for littler in /usr/local/bin
# Set a default CRAN repo, and make sure littler knows about it
# Install stringr to make dococt install (from source) easier
ENV R_BASE_VERSION 3.5.1-2bionic
ENV DEBIAN_FRONTEND noninteractive

#RUN add-apt-repository -y ppa:marutter/c2d4u3.5 \
#   && apt-get update \
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cpp \
        libgirepository-1.0-1 \
        libglib2.0-0 \
        libelf1 \
        libssl-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        libmpx0 \
        curl \
        perl-base \
        gpg-agent \
        libxrender1 \
    && apt-get install -y --no-install-recommends libopenblas-base

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
    && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/' \
    && cp /etc/apt/sources.list /etc/apt/sources.list~ \
    && sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list \
    && apt-get update \
    && apt-get build-dep -y r-base  \
    && wget https://cran.r-project.org/src/base/R-3/R-3.5.1.tar.gz \
    && tar -xzf R-3.5.1.tar.gz \
    && rm R-3.5.1.tar.gz \
    && cd R-3.5.1/ \
    && ./configure --prefix=/usr/lib/R/ --with-blas --with-lapack \
    && make \
    && make install \
    && ln -s /usr/lib/R/bin/R /bin/R \
    && ln -s /usr/lib/R/bin/Rscript /bin/Rscript \
    && cd .. \
    && rm -rf R-3.5.1

WORKDIR /

RUN Rscript -e 'install.packages(c("littler", "stringr"), repos = "http://cran.us.r-project.org")' \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*

#### Build code for installing PEER ####    

# Install dependencies and Python PEER package
RUN apt-get update \
    && apt-get install -y \
        libmpx0 \
        libgcc-6-dev \
        libstdc++-6-dev \
        gcc-5 \
        g++-5 \
        cmake \
        swig \
        python3-lib2to3 \
        python3-distutils \
        python \
        python-dev \
        python-numpy \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 50 --slave /usr/bin/g++ g++ /usr/bin/g++-5 \
    && wget https://github.com/downloads/PMBio/peer/peer_source_1.3.tar.gz \
    && tar -xvf peer_source_1.3.tar.gz \
    && cd /peer/build/ \
#    && find /peer -exec touch \{\} \;
    && cmake /peer \
    && make \
    && make install \
    && cd / \
    && rm -rf /peer /peer_source_1.3.tar.gz

# Install dependencies and R PEER package
WORKDIR /

RUN Rscript -e 'install.packages(c("optparse"), repos = "http://cran.us.r-project.org")' \
    && wget https://github.com/downloads/PMBio/peer/R_peer_source_1.3.tgz \
    && R CMD INSTALL R_peer_source_1.3.tgz \
    && rm R_peer_source_1.3.tgz

# Add wrapper script
COPY run_peer.R /opt/

ENV PATH=pkg-config:$PATH

WORKDIR /

CMD ["Rscript", "/opt/run_peer.R", "--help"]
