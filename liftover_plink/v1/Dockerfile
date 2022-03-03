#======================= Set Inital Image to work from ==========================
FROM python:3.8


#======================= Add Container Labels ===================================
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL description="Genomic liftOver on Plink formatted map/ped files."

#=========================== Defaults ===========================================
# Set a default user. Available via runtime flag `--user docker`
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
#RUN useradd docker \
#  && mkdir /home/docker \
#RUN chown docker:docker /home/docker \
#    && addgroup docker staff

# Don't print "debconf: unable to initialize frontend: Dialog" messages
ARG DEBIAN_FRONTEND=noninteractive


#======================= Install System Dependencies ============================
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
        vim \
	curl \
	gcc \
	ca-certificates

#================================================================================
#======================     Install LiftOver     ================================
#================================================================================

RUN wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/liftOver
RUN chmod +x liftOver
RUN mv liftOver /opt/

# common liftover conversion
RUN wget http://hgdownload.soe.ucsc.edu/goldenPath/hg18/liftOver/hg18ToHg19.over.chain.gz
RUN mv hg18ToHg19.over.chain.gz /opt/

####################### Add source files ##########################
ADD liftOverPlink.py /opt/

CMD ["python3", "/opt/liftOverPlink.py", "--help"]
