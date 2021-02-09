FROM python:2

# Maintainer and author
LABEL maintainer="Ravi Mathur <rmathur@rti.org>"

# update the OD related packages
RUN apt-get update

# clone cov-ldsc repo
RUN cd /opt \
    git clone https://github.com/immunogenomics/cov-ldsc.git

# Change permissions to make things exectuable
RUN chmod 755 /opt/cov-LDSC/ldsc.py

# Install python modules
RUN pip install numpy
RUN pip install pandas

# Set wrkdir
RUN mkdir /data
WORKDIR /data

