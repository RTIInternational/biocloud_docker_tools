FROM python:3.7.6-slim-stretch

# Maintainer and author
LABEL maintainer="Ravi Mathur <rmathur@rti.org>"

# Add R helper script
ADD ldsc.py /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/ldsc.py

# Install python modules


# Set wrkdir
RUN mkdir /data
WORKDIR /data

