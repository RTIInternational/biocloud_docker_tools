FROM python:3.13.0-slim-bullseye

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# update the OS related packages
RUN apt-get update

# Add scripts to make it run
ADD convert_variant_ids.py /

# Add to /opt folder
RUN mv convert_variant_ids.py /opt/

# Install libraries
RUN pip install pandas

# Set wrkdir
RUN mkdir /data
WORKDIR /data

RUN chmod 755 /opt/convert_variant_ids.py

CMD ["python", "/opt/convert_variant_ids.py", "--help"]

