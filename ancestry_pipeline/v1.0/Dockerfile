# Base image
FROM rocker/r-ubuntu:22.04

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Arguments
ARG bed
ARG bim
ARG fam
ARG psam
ARG variants

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

#### Install general packages
RUN rm -Rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install -y \
        curl \
        awscli

#### Install plink1.9 ####
RUN apt-get install -y \
        curl \
        fonts-texgyre \
        libatlas-base-dev
RUN wget https://github.com/chrchang/plink-ng/archive/refs/tags/b15c19f.tar.gz \
    && tar -xvzf b15c19f.tar.gz \
    && mv plink-ng-b15c19f/ /plink_tmp/
COPY dependencies/plink_common.h /plink_tmp/1.9/plink_common.h
COPY dependencies/sse2neon.h /plink_tmp/1.9/sse2neon.h 
COPY dependencies/SFMT.h /plink_tmp/1.9/SFMT.h
RUN cd /plink_tmp/1.9/ \
    && ./plink_first_compile \
    && cp /plink_tmp/1.9/plink /opt/plink1.9 \
    && cd / \
    && rm -rf b15c19f.tar.gz plink_tmp

#### Install plink2 ####
ENV DEBIAN_FRONTEND noninteractive
RUN wget https://s3.amazonaws.com/plink2-assets/alpha6/plink2_linux_x86_64_20250129.zip \
    && unzip plink2_linux_x86_64_20250129.zip -d /plink_tmp \
    && cp /plink_tmp/plink2 /opt/ \
    && rm -rf plink2_linux_x86_64_20250129.zip plink_tmp
ENV PATH=pkg-config:$PATH:/opt/

#### Install eigensoft ####
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgsl-dev \
        libopenblas-dev \
        liblapacke-dev \
    && wget https://github.com/DReichLab/EIG/archive/v7.2.1.tar.gz \
    && tar -xvzf v7.2.1.tar.gz \
    && cd EIG-7.2.1/src/ \
    && perl -i.bak -pe 's/# override LDLIBS \+= -llapacke/override LDLIBS += -llapacke/;' Makefile \
    && make clobber \
    && make install
ENV PATH=$PATH:/EIG-7.2.1/bin
RUN rm -Rf /var/lib/apt/lists/*

#### Install R libraries
RUN R -e "install.packages('scatterplot3d',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('optparse',dependencies=TRUE, repos='http://cran.rstudio.com/')"

#### Add reference data
# Note: prior to build get new presigned URLs and insert below
RUN mkdir /data
RUN mkdir /data/.ref
WORKDIR /data/.ref
RUN wget -O all_phase3_ld_pruned_autosomes_grch37_dbsnp_b153.bed "https://rti-bioinformatics-resources.s3.us-east-1.amazonaws.com/wf_inputs/biocloud_docker_tools/ancestry_pipeline/v1/grch37/all_phase3_ld_pruned_autosomes_grch37_dbsnp_b153.bed?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20250409%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250409T184446Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=48df0023425f0bc69b37354a529977c322b76824373562cb3d39487589717fce"
RUN wget -O all_phase3_ld_pruned_autosomes_grch37_dbsnp_b153.bim "https://rti-bioinformatics-resources.s3.us-east-1.amazonaws.com/wf_inputs/biocloud_docker_tools/ancestry_pipeline/v1/grch37/all_phase3_ld_pruned_autosomes_grch37_dbsnp_b153.bim?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20250409%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250409T184447Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=7ca5f23dea49aa1899b774f37768cbd60ec1293ac883c707698119935c5a4170"
RUN wget -O all_phase3_ld_pruned_autosomes_grch37_dbsnp_b153.fam "https://rti-bioinformatics-resources.s3.us-east-1.amazonaws.com/wf_inputs/biocloud_docker_tools/ancestry_pipeline/v1/grch37/all_phase3_ld_pruned_autosomes_grch37_dbsnp_b153.fam?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20250409%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250409T184447Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=0f7477faee54dfe16f0d1ada65931a35182238352d13516469353ef57203376a"
RUN wget -O all_phase3_ld_pruned_autosomes_grch37_dbsnp_b153.psam "https://rti-bioinformatics-resources.s3.us-east-1.amazonaws.com/wf_inputs/biocloud_docker_tools/ancestry_pipeline/v1/grch37/all_phase3_ld_pruned_autosomes_grch37_dbsnp_b153.psam?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20250409%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250409T184448Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=2a1387fdccad2b2dd3d7e67ee2cacb0879cc3746e03e2808d9d13c51a5da4330"
RUN wget -O all_phase3_ld_pruned_autosomes_grch38_dbsnp_b153.bed "https://rti-bioinformatics-resources.s3.us-east-1.amazonaws.com/wf_inputs/biocloud_docker_tools/ancestry_pipeline/v1/grch38/all_phase3_ld_pruned_autosomes_grch38_dbsnp_b153.bed?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20250409%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250409T184448Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=e085a9cb9659af0098a905cbc77c52c5dc886b07ace8b3c1188bc07266468c33"
RUN wget -O all_phase3_ld_pruned_autosomes_grch38_dbsnp_b153.bim "https://rti-bioinformatics-resources.s3.us-east-1.amazonaws.com/wf_inputs/biocloud_docker_tools/ancestry_pipeline/v1/grch38/all_phase3_ld_pruned_autosomes_grch38_dbsnp_b153.bim?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20250409%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250409T184449Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=6ae1047e2a8dc916dcf42170bf13778f4d20f585aecd99a07585aa27127289b1"
RUN wget -O all_phase3_ld_pruned_autosomes_grch38_dbsnp_b153.fam "https://rti-bioinformatics-resources.s3.us-east-1.amazonaws.com/wf_inputs/biocloud_docker_tools/ancestry_pipeline/v1/grch38/all_phase3_ld_pruned_autosomes_grch38_dbsnp_b153.fam?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20250409%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250409T184450Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=7c60c1d671db6566f2e681227849546fa50f3530cf0dc029fc4a1ea5d94e7e3f"
RUN wget -O all_phase3_ld_pruned_autosomes_grch38_dbsnp_b153.psam "https://rti-bioinformatics-resources.s3.us-east-1.amazonaws.com/wf_inputs/biocloud_docker_tools/ancestry_pipeline/v1/grch38/all_phase3_ld_pruned_autosomes_grch38_dbsnp_b153.psam?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20250409%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20250409T184450Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=7d91a995ef0d743da436a479b7d88353fb329e78a3f100e35542151e9425be0d"

# Add pipeline config files
RUN mkdir -p /pipeline/config
ADD config/ancestry_pipeline_entrypoint_bfile.json /pipeline/config/
ADD config/ancestry_pipeline_entrypoint_gvcf.json /pipeline/config/
ADD config/ancestry_tasks.json /pipeline/config/

#### Install custom scripts ####
# Add scripts
RUN mkdir -p /pipeline/scripts
ADD scripts/add_pop_ids_to_fam_files.pl /pipeline/scripts/
ADD scripts/assign_ancestry_mahalanobis.R /pipeline/scripts/
ADD scripts/assign_ids_to_dataset_bim.pl /pipeline/scripts/
ADD scripts/entrypoint.sh /pipeline/scripts/
ADD scripts/get_ancestry_assignment.pl /pipeline/scripts/
ADD scripts/get_ref_samples.pl /pipeline/scripts/
ADD scripts/get_ref_variants_from_dataset_gvcf.pl /pipeline/scripts/
ADD scripts/prepare_smartpca_input.pl /pipeline/scripts/
ADD scripts/process_smartpca_results.pl /pipeline/scripts/
ADD scripts/run_pipeline.py /pipeline/scripts/

# Change permissions
RUN chmod 755 /pipeline/scripts/add_pop_ids_to_fam_files.pl
RUN chmod 755 /pipeline/scripts/assign_ancestry_mahalanobis.R
RUN chmod 755 /pipeline/scripts/assign_ids_to_dataset_bim.pl
RUN chmod 755 /pipeline/scripts/entrypoint.sh
RUN chmod 755 /pipeline/scripts/get_ancestry_assignment.pl
RUN chmod 755 /pipeline/scripts/get_ref_samples.pl
RUN chmod 755 /pipeline/scripts/get_ref_variants_from_dataset_gvcf.pl
RUN chmod 755 /pipeline/scripts/prepare_smartpca_input.pl
RUN chmod 755 /pipeline/scripts/process_smartpca_results.pl
RUN chmod 755 /pipeline/scripts/run_pipeline.py

WORKDIR /data

ENTRYPOINT [ "/pipeline/scripts/entrypoint.sh" ]

