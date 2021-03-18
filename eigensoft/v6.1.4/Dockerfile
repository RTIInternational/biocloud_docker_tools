########################## Set Inital Image to work from ################################
FROM ubuntu:18.04


############################### Add Container Labels ####################################
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL software="EIGENSOFT"
LABEL software.version="6.1.4"
LABEL website="https://www.hsph.harvard.edu/alkes-price/software/"
LABEL description="Population genetics software that performs PCA."

######################################## Defaults ####################################### 
# disable prompt during packages installation
ARG DEBIAN_FRONTEND=noninteractive

# Set a default user. Available via runtime flag `--user docker` 
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
# User should also have & own a home directory (for rstudio or linked volumes to work properly). 
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

############################### Install System Dependencies #############################

# Install basic system dependencies. Once all installation is completed, remove
# all packages cache to reduce the size of the custom image.
RUN echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ bionic main' >> /etc/apt/sources.list
RUN apt update && apt install -y --no-install-recommends \
	git \
	vim-tiny \
	cmake \
	zlib1g-dev \
    dirmngr \
	software-properties-common \
	build-essential \
	ca-certificates \
	wget \
	locales \
	openssl \
	build-essential \
	libssl-dev \
	libffi-dev \
 && rm -rf /var/lib/apt/lists/* && apt clean

################################## Install EIGENSOFT ######################################

# Download from source, unpack, cleanup, and move to appropriate dir
# No need to build because executable binaries are already included in bin/
# The main tool our group currently uses is smartpca.perl
# Note that the executables must stay in the bin directory bin must be in PATH
RUN wget https://data.broadinstitute.org/alkesgroup/EIGENSOFT/EIG-6.1.4.tar.gz \
	&& tar -xvzf EIG-6.1.4.tar.gz \
	&& rm EIG-6.1.4.tar.gz \
	&& mv EIG-6.1.4 /opt/ 

############################ Final system configurations ################################
RUN mkdir /data/

WORKDIR /data/

ENV PATH="/opt/EIG-6.1.4/bin/:${PATH}"

# default help command
RUN cat /opt/EIG-6.1.4/EIGENSTRAT/README > /opt/help_file.txt \
 && echo "\n\n------------------------------------------------------------------------------------------------------------------\n\n" >> /opt/help_file.txt\
 && echo "\n\nNote from Dockerfile author:\nThe README file printed above explains that the smartpca program is called by the smartpca.pl wrapper." >> /opt/help_file.txt \
 && echo "The wrapper is actually named smartpca.perl" >> /opt/help_file.txt

CMD  ["cat", "/opt/help_file.txt"]
