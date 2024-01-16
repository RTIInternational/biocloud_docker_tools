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
COPY plink_common.h /plink_tmp/1.9/plink_common.h
COPY sse2neon.h /plink_tmp/1.9/sse2neon.h 
COPY SFMT.h /plink_tmp/1.9/SFMT.h
RUN cd /plink_tmp/1.9/ \
    && ./plink_first_compile \
    && cp /plink_tmp/1.9/plink /opt/plink \
    && cd / \
    && rm -rf b15c19f.tar.gz plink_tmp

#### Install plink2 ####
ENV DEBIAN_FRONTEND noninteractive
RUN wget https://s3.amazonaws.com/plink2-assets/alpha3/plink2_linux_x86_64_20220519.zip \
    && unzip plink2_linux_x86_64_20220519.zip -d /plink_tmp \
    && cp /plink_tmp/plink2 /opt/ \
    && rm -rf plink2_linux_x86_64_20220519.zip plink_tmp
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
RUN wget -O all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bed "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bed?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20240116%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240116T194454Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=4e1d35f5cf1a974d6519f8bf2d0b10ddf1058de4b0edbe539a9114bd11484f18"
RUN wget -O all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bim "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bim?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20240116%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240116T194455Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=b640c40d591b95b81748a960faf89c4a14f2402760d119d6a0e260854fdd5306"
RUN wget -O all_phase3_unique_grch37_dbsnp_b153_ld_pruned.fam "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.fam?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20240116%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240116T194455Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=a48ddfc0865df40133e5e5ec9be62c036ac5bca343a138791cd18220f932773e"
RUN wget -O 1000g_variants.tsv "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/1000g_variants.tsv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20240116%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240116T194456Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=f34cdfdbeac23635960c7de7ec42d080d5ee04b4d63b2129a584bcbd1df46b0e"
RUN wget -O phase3_orig.psam "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/phase3_orig.psam?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAV4MGIV2ZNAT4GLK2%2F20240116%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240116T194456Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Signature=db9c37e896413b41679253136c7951c0d476091751644eb75ad0e2781c0a738e"

#### Install custom scripts ####
# Add scripts
ADD entrypoint.sh /opt/
ADD run_pipeline.py /opt/
ADD ancestry_pipeline.json /opt/
ADD ancestry_tasks.json /opt/
ADD get_dataset_variants.pl /opt/
ADD get_ref_samples.pl /opt/
ADD add_pop_ids_to_fam_files.pl /opt/
ADD prepare_smartpca_input.pl /opt/
ADD process_smartpca_results.pl /opt/
ADD assign_ancestry_mahalanobis.R /opt/
ADD get_ancestry_assignment.pl /opt/
# Change permissions
RUN chmod 755 /opt/entrypoint.sh
RUN chmod 755 /opt/run_pipeline.py
RUN chmod 755 /opt/get_dataset_variants.pl
RUN chmod 755 /opt/get_ref_samples.pl
RUN chmod 755 /opt/add_pop_ids_to_fam_files.pl
RUN chmod 755 /opt/prepare_smartpca_input.pl
RUN chmod 755 /opt/process_smartpca_results.pl
RUN chmod 755 /opt/assign_ancestry_mahalanobis.R
RUN chmod 755 /opt/get_ancestry_assignment.pl

WORKDIR /data

ENTRYPOINT [ "/opt/entrypoint.sh" ]

