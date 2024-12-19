FROM ubuntu:24.04

LABEL maintainer="David Williams <dnwilliams@rti.org>"
LABEL description="This Docker image contains the 7z compression tool for use in Seven Bridges or other platforms to do compression related operations."
LABEL software-version="1.0"

RUN apt update
RUN apt install -y vim p7zip-full p7zip-rar
RUN apt install -y bash

# Set workdir
RUN mkdir /data
COPY ./*.zip ./*.7z ./*.gz ./*.tar ./*.rar ./*.bz ./*.tbz ./*.tb2 ./*.bz2 /data
WORKDIR /data

# Add to environment
ENV PATH=$PATH:/opt/
