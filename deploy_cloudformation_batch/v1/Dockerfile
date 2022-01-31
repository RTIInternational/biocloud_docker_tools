##################### Set Inital Image to work from ############################
FROM ubuntu:20.04

##################### Add Container Labels #####################################
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL description="A script to create a new AWS Batch environment."

##################### Defaults ##############################
# Set a default user. Available via runtime flag `--user docker`
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
#RUN useradd docker \
#  && mkdir /home/docker \
#RUN chown docker:docker /home/docker \
#    && addgroup docker staff

# Don't print "debconf: unable to initialize frontend: Dialog" messages
ARG DEBIAN_FRONTEND=noninteractive


##################### Install System Dependencies ##############################
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
        vim \
	less \
	curl \
	gcc \
	ca-certificates \
	unzip \
	jq


RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

####################### Add source files ##########################
ADD deploy-cloudformation-batch.sh /opt/
ADD help-file.txt /opt/

CMD ["cat", "/opt/help-file.txt"]
