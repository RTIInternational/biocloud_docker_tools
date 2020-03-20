FROM ubuntu:18.04 

# Maintainer and author
LABEL maintainer="Alex Waldrop <awaldrop@rti.org>"

# Add scripts to make it run
ADD convert_to_impute2_ids.pl /

# Add to /opt folder
RUN mv convert_to_impute2_ids.pl /opt/

# Change permissions to make things exectuable
RUN chmod u+x /opt/convert_to_impute2_ids.pl

# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Add to environment
ENV PATH $PATH:/opt/
