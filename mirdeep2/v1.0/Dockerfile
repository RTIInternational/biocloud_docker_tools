# Base image
FROM continuumio/miniconda3:24.11.1-0


LABEL maintainer="Caryn Willis cdwillis@rti.org"
LABEL description="This Docker image contains the tool miRdeep2 for discovering active knorn or novel miRNAs from deep sequencing data."
LABEL base-image="continuumio/miniconda3:24.11.1-0"
LABEL software-version="1.0"

# Create conda environment, install mirdeep2
RUN conda config --add channels bioconda
RUN conda config --add channels conda-forge
RUN conda config --set channel_priority strict
RUN conda install -y bioconda::mirdeep2
# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Add to environment
ENV PATH=$PATH:/opt/
