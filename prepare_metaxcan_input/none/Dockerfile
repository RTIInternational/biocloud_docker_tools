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
RUN R -e 'install.packages(c("plyr"), repos="http://cran.us.r-project.org")'

# =====================================================================
# Get accessory scripts from github repos
# =====================================================================

# Add to /opt folder
RUN mkdir /opt/code_docker_lib

# Clone git repo, checkout specific commit to keep versioning constant, transfer helper scripts to code directory
RUN git clone https://github.com/RTIInternational/code_docker_lib.git && \
    cd /code_docker_lib && git reset --hard beea21a956fc35bb7fb8367dd8d6b3125efb9812 && \
    mv /code_docker_lib/convert_to_1000g_ids/convert_to_1000g_ids.pl /opt/code_docker_lib/ && \
    mv /code_docker_lib/extract_by_id/extract_by_id.pl /opt/code_docker_lib/ && \
    rm -rf /code_docker_lib

# =====================================================================
# Add accesory scripts included in directory
# =====================================================================

# Add scripts to make it run
ADD merge_gxg_gtex_variants.R /
ADD prepare_metaxcan_input.sh /
ADD run.sh /

# Move scripts to
RUN mv merge_gxg_gtex_variants.R /opt/code_docker_lib && \
    mv prepare_metaxcan_input.sh /opt/code_docker_lib && \
    mv run.sh /opt/code_docker_lib

# Change permissions to make things exectuable
RUN chmod -R u+x /opt/code_docker_lib/

# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Create entrypoint that runs the run.sh wrapper script
#ENTRYPOINT ["/bin/bash", "/opt/code_docker_lib/run.sh"]