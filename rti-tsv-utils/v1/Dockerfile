FROM python:3.13.9-slim

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# update the OS related packages
RUN apt-get update

# Add scripts to make it run
ADD rti-tsv-utils-join.py /
ADD rti-tsv-utils-sort.py /

# Add to /opt folder
RUN mv rti-tsv-utils-join.py /opt/
RUN mv rti-tsv-utils-sort.py /opt/

# Install libraries
RUN pip install pandas

# Set wrkdir
RUN mkdir /data
WORKDIR /data

RUN chmod 755 /opt/rti-tsv-utils-join.py
RUN chmod 755 /opt/rti-tsv-utils-sort.py
