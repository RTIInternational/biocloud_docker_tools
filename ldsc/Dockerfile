FROM continuumio/miniconda

LABEL maintainer=awaldrop@rti.org

# =====================================================================
# Install LDSC from git
# =====================================================================

RUN git clone https://github.com/bulik/ldsc.git

# Create conda environment
RUN cd ldsc && \
    conda env create --file environment.yml

# Add command to activate ldsc conda environment to bash script
RUN echo "source activate ldsc" >> ~/.bashrc

# =====================================================================
# Standard docker image stuff
# =====================================================================
# Add ldsc to /opt folder
RUN mv ldsc /opt

# Change permissions to make things exectuable
RUN chmod -R u+x /opt/ldsc

# Put ldsc on path
ENV PATH /opt/ldsc:$PATH

# Set wrkdir
RUN mkdir -p /data
WORKDIR /data
