FROM python:3.7.6-slim-stretch

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# update the OS related packages
RUN apt-get update

# Add scripts to make it run
ADD ped2structure.py /

# Add to /opt folder
RUN mv ped2structure.py /opt/

# Set wrkdir
RUN mkdir /data
WORKDIR /data

RUN chmod 755 /opt/ped2structure.py

CMD ["python", "/opt/ped2structure.py", "--help"]