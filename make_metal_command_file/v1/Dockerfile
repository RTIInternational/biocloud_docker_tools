FROM ubuntu:22.04 

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# update the OS related packages
RUN apt-get update

# Add scripts to make it run
ADD make_metal_command_file.pl /

# Add to /opt folder
RUN mv make_metal_command_file.pl /opt/

# Change permissions to make things exectuable
RUN chmod u+x /opt/make_metal_command_file.pl

# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Add to environment
ENV PATH $PATH:/opt/
