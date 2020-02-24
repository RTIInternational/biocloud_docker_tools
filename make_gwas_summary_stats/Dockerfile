FROM python:3.7.6-slim-stretch 

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# update the OS related packages
RUN apt-get update

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

RUN chmod 755 /opt/make_gwas_summary_stats.py

CMD ["python", "/opt/make_gwas_summary_stats.py", "--help"]
