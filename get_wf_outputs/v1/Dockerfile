FROM python:3.7.6-slim-stretch

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# update the OS related packages
RUN apt-get update

# Add scripts to make it run
ADD get_wf_outputs.py /

# Add to /opt folder
RUN mv get_wf_outputs.py /opt/

# Set wrkdir
RUN mkdir /data
WORKDIR /data

RUN chmod 755 /opt/get_wf_outputs.py

ENV PATH=$PATH:/opt/

CMD ["python", "/opt/get_wf_outputs.py", "--help"]
