FROM joshkeegan/zip:3.19.1

LABEL maintainer="David Williams <dnwilliams@rti.org>"
LABEL description="This Docker image contains an in-house script written to extract and rename files coming from the 'outs.zip' file from Cellranger"

RUN apk update
RUN apk add vim vim-doc vim-tutor
RUN apk add bash

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
ENV PATH $PATH:/opt/
