FROM continuumio/miniconda:4.7.12

LABEL maintainer=awaldrop@rti.org

# Add things to environment
ADD environment.yaml /

# Pin this to a specific commit of summary_gwas_imputation
RUN git clone https://github.com/hakyimlab/summary-gwas-imputation.git && \
    cd summary-gwas-imputation && \
    git checkout 206dac587824a6f207e137ce8c2d7b15d81d5869


# Create conda environment
RUN cd summary-gwas-imputation/src && \
    conda env create --file conda_env.yaml

# Add command to activate conda environment to bash script
RUN echo "source activate imlabtools" >> ~/.bashrc

# =====================================================================
# Standard docker image stuff
# =====================================================================
# Add summary-gwas-imputation to /opt folder
RUN mv summary-gwas-imputation /opt

# Change permissions to make things exectuable
RUN chmod -R u+x /opt/summary-gwas-imputation

# Put ldsc on path
ENV PATH /opt/summary-gwas-imputation/src:$PATH

# Set wrkdir
RUN mkdir -p /data
WORKDIR /data
