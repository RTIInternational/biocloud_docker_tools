FROM python:3.7.6-slim-stretch

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# update the OS related packages
RUN apt-get update

# Install libraries
RUN pip install TEtranscripts==2.2.1

# Set wrkdir
RUN mkdir /data
WORKDIR /data

CMD ["TEcount", "--help"]
