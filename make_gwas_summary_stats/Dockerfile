FROM python:3

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Add scripts to make it run
ADD make_gwas_summary_stats.py /

# Add to /opt folder
RUN mv make_gwas_summary_stats.py /opt/

# Install libraries
RUN pip install pandas
RUN pip install pprint

# Set wrkdir
RUN mkdir /data
WORKDIR /data
