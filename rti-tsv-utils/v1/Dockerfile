FROM python:3.7.6-slim-stretch

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# update the OS related packages
RUN apt-get update

# Add scripts to make it run
ADD rti-tsv-utils-join.py /

# Add to /opt folder
RUN mv rti-tsv-utils-join.py /opt/

# Install libraries
RUN pip install pandas

# Set wrkdir
RUN mkdir /data
WORKDIR /data

RUN chmod 755 /opt/rti-tsv-utils-join.py

CMD ["python", "/opt/rti-tsv-utils-join.py", "--help"]
