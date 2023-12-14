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

#### Install plink ####
ENV DEBIAN_FRONTEND noninteractive
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

#### Install custom scripts ####
# Add scripts
ADD entrypoint.sh /opt/
ADD run_pipeline.py /opt/
ADD ancestry_pipeline_config.json /opt/
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

RUN mkdir /data

#### Add reference data
# Note: prior to build get new presigned URLs and insert below
RUN mkdir /data/.ref
WORKDIR /data/.ref
RUN wget -O all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bed "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bed?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA2WXCECDUNAXEDTC7%2F20231214%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231214T213042Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Security-Token=FwoGZXIvYXdzEOL%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDLsQ9zOvlvM6kSMbRiKCA1TcKckp5wYtLHAIUTiZmmVdvjfcx8OmLYKuQR2oFHeK2UWpZBuI1fONSqNYvKzE4jDkH5tk3eX5VOHnwy7XpIfES9RKEFAH87bdQSKGJvPygwkHgs0FcBDmOyEP%2FAxgQaVrOFS30u37SWZVIfnDbkeMWYzx2gLxEskJPpo0jdHgFAnePhD3Ah4fLV7gkqorlxqylVwUQH%2B48LLlw4UtWXY%2FZu1ks85pmV4PdtZZA0daF7bvcy8Wsq%2BY8mlaMQfOzpAcgWUv%2B7OynuO8yOWaHLcv1XxYyzbCtlDRfJrTCA9dw5G%2BCJvwimz2iWTNh8k7REeBkphREC%2Bvgi5AszhJ7aSZL%2Fb9q0wCIzNT1cKiw0yPyQkWccjOoXzPIKGD%2FYEtTlhYMfhRwyCIQyOcpR8ZdrosJxIDPCvwUXH2Ie9RJFaMZGduvF8dZHOmivFkOPUjIDmGmrXql4bctdbJ35PcrdxTJ2jKcVoSpCBPQD6SmE%2BmLF2VWjIK3gEEU2q%2FieE%2BN6H%2FKJut56sGMjME3QePG%2FcpftacJUZxI4q6T7ADCBt88IdSyQtc4bDDKqr08mC3tUNL5tJwy%2BZdO7JvraU%3D&X-Amz-Signature=29ea79c7d5185931e02f49586d463aa7c989fe1e8f135e6dda64803c114eb486"
RUN wget -O all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bim "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bim?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA2WXCECDUNAXEDTC7%2F20231214%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231214T213042Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Security-Token=FwoGZXIvYXdzEOL%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDLsQ9zOvlvM6kSMbRiKCA1TcKckp5wYtLHAIUTiZmmVdvjfcx8OmLYKuQR2oFHeK2UWpZBuI1fONSqNYvKzE4jDkH5tk3eX5VOHnwy7XpIfES9RKEFAH87bdQSKGJvPygwkHgs0FcBDmOyEP%2FAxgQaVrOFS30u37SWZVIfnDbkeMWYzx2gLxEskJPpo0jdHgFAnePhD3Ah4fLV7gkqorlxqylVwUQH%2B48LLlw4UtWXY%2FZu1ks85pmV4PdtZZA0daF7bvcy8Wsq%2BY8mlaMQfOzpAcgWUv%2B7OynuO8yOWaHLcv1XxYyzbCtlDRfJrTCA9dw5G%2BCJvwimz2iWTNh8k7REeBkphREC%2Bvgi5AszhJ7aSZL%2Fb9q0wCIzNT1cKiw0yPyQkWccjOoXzPIKGD%2FYEtTlhYMfhRwyCIQyOcpR8ZdrosJxIDPCvwUXH2Ie9RJFaMZGduvF8dZHOmivFkOPUjIDmGmrXql4bctdbJ35PcrdxTJ2jKcVoSpCBPQD6SmE%2BmLF2VWjIK3gEEU2q%2FieE%2BN6H%2FKJut56sGMjME3QePG%2FcpftacJUZxI4q6T7ADCBt88IdSyQtc4bDDKqr08mC3tUNL5tJwy%2BZdO7JvraU%3D&X-Amz-Signature=d90a84b960566249856e7930c15af597f9ef10a0a8ea514dfbcbeff62834ee2e"
RUN wget -O all_phase3_unique_grch37_dbsnp_b153_ld_pruned.fam "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.fam?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA2WXCECDUNAXEDTC7%2F20231214%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231214T213043Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Security-Token=FwoGZXIvYXdzEOL%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDLsQ9zOvlvM6kSMbRiKCA1TcKckp5wYtLHAIUTiZmmVdvjfcx8OmLYKuQR2oFHeK2UWpZBuI1fONSqNYvKzE4jDkH5tk3eX5VOHnwy7XpIfES9RKEFAH87bdQSKGJvPygwkHgs0FcBDmOyEP%2FAxgQaVrOFS30u37SWZVIfnDbkeMWYzx2gLxEskJPpo0jdHgFAnePhD3Ah4fLV7gkqorlxqylVwUQH%2B48LLlw4UtWXY%2FZu1ks85pmV4PdtZZA0daF7bvcy8Wsq%2BY8mlaMQfOzpAcgWUv%2B7OynuO8yOWaHLcv1XxYyzbCtlDRfJrTCA9dw5G%2BCJvwimz2iWTNh8k7REeBkphREC%2Bvgi5AszhJ7aSZL%2Fb9q0wCIzNT1cKiw0yPyQkWccjOoXzPIKGD%2FYEtTlhYMfhRwyCIQyOcpR8ZdrosJxIDPCvwUXH2Ie9RJFaMZGduvF8dZHOmivFkOPUjIDmGmrXql4bctdbJ35PcrdxTJ2jKcVoSpCBPQD6SmE%2BmLF2VWjIK3gEEU2q%2FieE%2BN6H%2FKJut56sGMjME3QePG%2FcpftacJUZxI4q6T7ADCBt88IdSyQtc4bDDKqr08mC3tUNL5tJwy%2BZdO7JvraU%3D&X-Amz-Signature=c35fe7561696780028a43ef11d03c978c5cb4837ab6f792d30ed6dca1161f252"
RUN wget -O 1000g_variants.tsv "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/1000g_variants.tsv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA2WXCECDUNAXEDTC7%2F20231214%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231214T213044Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Security-Token=FwoGZXIvYXdzEOL%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDLsQ9zOvlvM6kSMbRiKCA1TcKckp5wYtLHAIUTiZmmVdvjfcx8OmLYKuQR2oFHeK2UWpZBuI1fONSqNYvKzE4jDkH5tk3eX5VOHnwy7XpIfES9RKEFAH87bdQSKGJvPygwkHgs0FcBDmOyEP%2FAxgQaVrOFS30u37SWZVIfnDbkeMWYzx2gLxEskJPpo0jdHgFAnePhD3Ah4fLV7gkqorlxqylVwUQH%2B48LLlw4UtWXY%2FZu1ks85pmV4PdtZZA0daF7bvcy8Wsq%2BY8mlaMQfOzpAcgWUv%2B7OynuO8yOWaHLcv1XxYyzbCtlDRfJrTCA9dw5G%2BCJvwimz2iWTNh8k7REeBkphREC%2Bvgi5AszhJ7aSZL%2Fb9q0wCIzNT1cKiw0yPyQkWccjOoXzPIKGD%2FYEtTlhYMfhRwyCIQyOcpR8ZdrosJxIDPCvwUXH2Ie9RJFaMZGduvF8dZHOmivFkOPUjIDmGmrXql4bctdbJ35PcrdxTJ2jKcVoSpCBPQD6SmE%2BmLF2VWjIK3gEEU2q%2FieE%2BN6H%2FKJut56sGMjME3QePG%2FcpftacJUZxI4q6T7ADCBt88IdSyQtc4bDDKqr08mC3tUNL5tJwy%2BZdO7JvraU%3D&X-Amz-Signature=1f5873911aeb4ed114af371e2d3ef9d418033e10c5d7162d4c56481123981f61"
RUN wget -O phase3_orig.psam "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/phase3_orig.psam?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA2WXCECDUNAXEDTC7%2F20231214%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231214T213043Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Security-Token=FwoGZXIvYXdzEOL%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDLsQ9zOvlvM6kSMbRiKCA1TcKckp5wYtLHAIUTiZmmVdvjfcx8OmLYKuQR2oFHeK2UWpZBuI1fONSqNYvKzE4jDkH5tk3eX5VOHnwy7XpIfES9RKEFAH87bdQSKGJvPygwkHgs0FcBDmOyEP%2FAxgQaVrOFS30u37SWZVIfnDbkeMWYzx2gLxEskJPpo0jdHgFAnePhD3Ah4fLV7gkqorlxqylVwUQH%2B48LLlw4UtWXY%2FZu1ks85pmV4PdtZZA0daF7bvcy8Wsq%2BY8mlaMQfOzpAcgWUv%2B7OynuO8yOWaHLcv1XxYyzbCtlDRfJrTCA9dw5G%2BCJvwimz2iWTNh8k7REeBkphREC%2Bvgi5AszhJ7aSZL%2Fb9q0wCIzNT1cKiw0yPyQkWccjOoXzPIKGD%2FYEtTlhYMfhRwyCIQyOcpR8ZdrosJxIDPCvwUXH2Ie9RJFaMZGduvF8dZHOmivFkOPUjIDmGmrXql4bctdbJ35PcrdxTJ2jKcVoSpCBPQD6SmE%2BmLF2VWjIK3gEEU2q%2FieE%2BN6H%2FKJut56sGMjME3QePG%2FcpftacJUZxI4q6T7ADCBt88IdSyQtc4bDDKqr08mC3tUNL5tJwy%2BZdO7JvraU%3D&X-Amz-Signature=4593293a3eb5f10d87dc9d1cf0614461bb91a68aedae4900d798b633fafe182e"

WORKDIR /data

ENTRYPOINT [ "/opt/entrypoint.sh" ]

