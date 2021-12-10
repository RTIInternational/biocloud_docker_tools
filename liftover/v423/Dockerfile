#================================================================================
#=====================     Set Inital Image to work from     ====================
#================================================================================

FROM python:3.10

#================================================================================
#=================     Add Container Labels     =================================
#================================================================================

LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL description="Contains the liftOver tool used to move genomic annotations from one assembly to another."


#================================================================================
#=============================     Defaults    ==================================
#================================================================================

# Set a default user. Available via runtime flag `--user docker`
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library

# Don't print "debconf: unable to initialize frontend: Dialog" messages
ARG DEBIAN_FRONTEND=noninteractive


#================================================================================
#======================     Install System Dependencies     =====================
#================================================================================

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
	vim
