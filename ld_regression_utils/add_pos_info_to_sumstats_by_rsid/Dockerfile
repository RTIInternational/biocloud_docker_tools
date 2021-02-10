FROM continuumio/miniconda

LABEL maintainer=awaldrop@rti.org

# Add things to environment
ADD environment.yaml /

# Create conda environment
RUN conda env create --file environment.yaml

# Add command to activate generate_input conda environment to bash script
RUN echo "source activate add_pos_info" >> ~/.bashrc

# =====================================================================
# Standard docker image stuff
# =====================================================================
# Add source files to /opt folder
ADD add_pos_info_to_sumstats_by_rsid.py /
ADD utils.py /
ADD run.sh /

RUN mkdir /opt/ld_regression
RUN mv add_pos_info_to_sumstats_by_rsid.py /opt/ld_regression
RUN mv utils.py /opt/ld_regression
RUN mv run.sh /opt/ld_regression

# Change permissions to make things exectuable
RUN chmod -R u+x /opt/ld_regression

# Put ldsc on path
ENV PATH /opt/ld_regression:$PATH

# Set wrkdir
RUN mkdir -p /data
WORKDIR /data

#ENTRYPOINT ["/bin/bash", "/opt/ld_regression/run.sh"]