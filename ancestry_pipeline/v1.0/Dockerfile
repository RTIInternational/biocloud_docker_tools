# Base image
FROM rocker/r-ubuntu:22.04

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

#### Update linux packages
RUN rm -Rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install -y \
        cpanminus

# Install miniconda3
ENV PATH /opt/conda/bin:$PATH
RUN set -x && \
    wget "https://repo.anaconda.com/miniconda/Miniconda3-py312_24.3.0-0-Linux-x86_64.sh" -O miniconda.sh -q && \
    echo "96a44849ff17e960eeb8877ecd9055246381c4d4f2d031263b63fa7e2e930af1 miniconda.sh" > shasum && \
    sha256sum --check --status shasum && \
    mkdir -p /opt && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh shasum && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy

# Install python
RUN conda install -c anaconda -y python=3.11
RUN ln -s /root/miniconda3/bin/python3.11 /usr/bin/python

#### Install plink1.9 ####
RUN conda install -c bioconda -y plink

#### Install eigensoft ####
RUN conda install -c bioconda -y eigensoft

# RUN apt-get update \
#     && apt-get install -y --no-install-recommends \
#         libgsl-dev \
#         libopenblas-dev \
#         liblapacke-dev \
#     && wget https://github.com/DReichLab/EIG/archive/v7.2.1.tar.gz \
#     && tar -xvzf v7.2.1.tar.gz \
#     && cd EIG-7.2.1/src/ \
#     && perl -i.bak -pe 's/# override LDLIBS \+= -llapacke/override LDLIBS += -llapacke/;' Makefile \
#     && make clobber \
#     && make install
# ENV PATH=$PATH:/EIG-7.2.1/bin
# RUN rm -Rf /var/lib/apt/lists/*

#### Install R libraries
RUN R -e "install.packages('scatterplot3d',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('optparse',dependencies=TRUE, repos='http://cran.rstudio.com/')"

#### Install PERL modules ####
RUN cpanm install JSON

#### Install custom scripts ####
# Add scripts
ADD scripts/add_pop_ids_to_fam_files.pl /opt/
ADD scripts/assign_ancestry_mahalanobis.R /opt/
ADD scripts/entrypoint.sh /opt/
ADD scripts/extract_gvcf_variants.pl /opt/
ADD scripts/get_ancestry_assignment.pl /opt/
ADD scripts/get_ref_samples.pl /opt/
ADD scripts/prepare_smartpca_input.pl /opt/
ADD scripts/process_smartpca_results.pl /opt/
ADD scripts/run_pipeline.py /opt/
# Change permissions
RUN chmod 755 /opt/add_pop_ids_to_fam_files.pl
RUN chmod 755 /opt/assign_ancestry_mahalanobis.R
RUN chmod 755 /opt/entrypoint.sh
RUN chmod 755 /opt/extract_gvcf_variants.pl
RUN chmod 755 /opt/get_ancestry_assignment.pl
RUN chmod 755 /opt/get_ref_samples.pl
RUN chmod 755 /opt/prepare_smartpca_input.pl
RUN chmod 755 /opt/process_smartpca_results.pl
RUN chmod 755 /opt/run_pipeline.py

#### Install pipeline config files ####
RUN mkdir -p /pipeline/config
ADD pipeline_config/* /pipeline/config/

RUN mkdir /data
WORKDIR /data

ENTRYPOINT [ "/opt/entrypoint.sh" ]

