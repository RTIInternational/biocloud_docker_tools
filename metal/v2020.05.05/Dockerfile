########################## Set Inital Image to work from ################################
FROM python:3.8-slim


############################### Add Container Labels ####################################
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"
LABEL software="METAL"
LABEL software.version="2020-05-05"
LABEL website="https://github.com/statgen/METAL"
LABEL description="A tool for the meta-analysis of genome-wide association studies."

######################################## Defaults ####################################### 
# disable prompt during packages installation
ARG DEBIAN_FRONTEND=noninteractive

# Set a default user. Available via runtime flag `--user docker` 
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
# User should also have & own a home directory (for rstudio or linked volumes to work properly). 
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && usermod -a -G staff docker

############################### Install System Dependencies #############################

# Install basic system dependencies. Once all installation is completed, remove
# all packages cache to reduce the size of the custom image.
RUN apt update && apt install -y --no-install-recommends \
	wget \
	build-essential \
	cmake \
	libglib2.0-dev \
 && rm -rf /var/lib/apt/lists/* && apt clean

################################## Install METAL ######################################

# download from source, unpack, cleanup
RUN wget https://github.com/statgen/METAL/archive/2020-05-05.tar.gz \
	&& tar -xvzf 2020-05-05.tar.gz \
	&& rm 2020-05-05.tar.gz \
	&& mv METAL-2020-05-05 /opt/

# build and install
RUN cd /opt/METAL-2020-05-05/ \
	&& cmake -DCMAKE_BUILD_TYPE=Release \
	&& make \
	&& make test \
	&& make install

# hyperlink in CODE approved dir and create file for default help command
RUN cd /opt/ \
	&& ln -s METAL-2020-05-05/bin/metal

######################## Install python libraries ############################

RUN pip install --no-cache-dir pandas

######################## Install make_metal_command_file.pl ############################

COPY make_metal_command_file.pl /opt/
COPY postprocess_metal_results.py /opt/

############################ Final system configurations ################################

RUN mkdir /data/

WORKDIR /data/

ENV PATH="/opt/:${PATH}"

############################## END OF DOCKERFILE #######################################