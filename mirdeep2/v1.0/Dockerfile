FROM conda/miniconda3:latest
LABEL maintainer="Caryn Willis cdwillis@rti.org"
LABEL description="This Docker image contains the tool miRdeep2 for discovering active knorn or novel miRNAs from deep sequencing data."
LABEL base-image="conda/miniconda3:latest"
LABEL software-version="1.0"


RUN conda config --add channels bioconda
RUN conda config --add channels conda-forge
RUN conda config --set channel_priority strict
RUN conda install mirdeep2

# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Add to environment
ENV PATH=$PATH:/opt/
