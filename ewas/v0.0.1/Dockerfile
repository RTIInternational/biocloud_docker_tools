##################### Set Inital Image to work from ############################
FROM r-base:4.0.4


##################### Add Container Labels #####################################
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL description="Contains the R packages necessary to run the EWAS workflow."


##################### Defaults ##############################
# Set a default user. Available via runtime flag `--user docker`
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
# User should also have & own a home directory (for rstudio or linked volumes to work properly).
#RUN useradd docker \
#    && mkdir /home/docker \
#    && chown docker:docker /home/docker \
#    && addgroup docker staff

# Don't print "debconf: unable to initialize frontend: Dialog" messages
ARG DEBIAN_FRONTEND=noninteractive


##################### Install System Dependencies ##############################
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        software-properties-common \
        git \
        vim \
	wget \
        tk-dev \
        dirmngr \
        zlib1g-dev \
        gnupg \
        gpg-agent \
        libssl-dev \
	locales \
	libcurl4-openssl-dev
        

RUN apt-get install -y --no-install-recommends \
        build-essential \
        python3-pip \
        python-setuptools \
        python-dev \
        python-tk \
        pip

RUN apt-get install -y --no-install-recommends \
        r-base \
        r-cran-randomforest

RUN rm -rf /var/lib/apt/lists/*


######################### Install Python ###############################
RUN alias python='/usr/bin/python3' \
    && echo 'alias python="/usr/bin/python3"' >> /root/.bashrc \
    && echo 'alias pip="/usr/bin/pip3"' >> /root/.bashrc \
    && . /root/.bashrc

RUN echo "statsmodels\nsklearn\ncvxopt\nscipy\nnumpy\npandas\nmatplotlib" >  /opt/requirements.txt

RUN pip3 install -r /opt/requirements.txt

############################ Install R ##################################
RUN Rscript -e 'install.packages(c("XML", "xml2", "data.table", "ggplot2", "ggrepel", "gridExtra", "dplyr", "sandwich", "lmtest", "remotes", "RColorBrewer", "MASS", "gee", "cat", "BiocManager"))' 

RUN Rscript -e 'install.packages("optparse")' 
#RUN Rscript -e 'BiocManager::install("DESeq2", version= "3.10")'

RUN  Rscript -e 'BiocManager::install(c("minfi", "IlluminaHumanMethylation450kanno.ilmn12.hg19", "FlowSorted.DLPFC.450k", "FlowSorted.Blood.EPIC", "FlowSorted.Blood.450k", "IlluminaHumanMethylationEPICanno.ilm10b4.hg19", "GenomicRanges", "SummarizedExperiment", "LieberInstitute/jaffelab"))'
