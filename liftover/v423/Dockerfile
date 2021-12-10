#================================================================================
#=====================     Set Inital Image to work from     ====================
#================================================================================

FROM python:3.10

#================================================================================
#=====================     Add Image Labels     =================================
#================================================================================

LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL description="Contains the liftOver tool used to move genomic annotations \
from one assembly to another."
LABEL website="http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/"
LABEL binary="http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/liftOver"
LABEL version="kent source version 423"
LABEL release-date="2021-11-18"


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


#================================================================================
#======================     Install LiftOver     =====================
#================================================================================

RUN wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/liftOver
RUN chmod +x liftOver
RUN mv liftOver /opt/

ENV PATH="/opt/liftOver/:${PATH}"

CMD  ["bash", "/opt/liftOver"]
