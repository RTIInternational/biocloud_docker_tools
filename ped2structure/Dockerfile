FROM ubuntu:18.04

# Maintainer and author
LABEL maintainer="Alex Waldrop <awaldrop@rti.org>"

# Add scripts to make it run
ADD ped2structure.pl /

# Add to /opt folder
RUN mv ped2structure.pl /opt/

# Change permissions to make things exectuable
RUN chmod u+x /opt/ped2structure.pl

# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Add to environment
ENV PATH $PATH:/opt/