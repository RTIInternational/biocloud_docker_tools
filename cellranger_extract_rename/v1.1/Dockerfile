FROM alpine:3.20.3

LABEL maintainer="David Williams <dnwilliams@rti.org>"
LABEL description="This Docker image contains an in-house script written to extract and rename files coming from the 'outs.zip' file or outs directory from Cellranger"
LABEL software-version="1.1"

RUN apk update
RUN apk add --no-cache vim vim-doc vim-tutor zip unzip libarchive-tools
RUN apk add --no-cache bash

# Add scripts to make it run
ADD rename_files.sh /

# Add to /opt folder
RUN mv rename_files.sh /opt/

# Change permissions to make things exectuable
RUN chmod u+x /opt/rename_files.sh

# Set workdir
RUN mkdir /data
COPY ./*.zip /data
WORKDIR /data

# Add to environment
ENV PATH=$PATH:/opt/
