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

#### Add reference data
# Note: prior to build get new presigned URLs and insert below
RUN mkdir /data
RUN mkdir /data/.ref
WORKDIR /data/.ref
RUN wget -O all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bed "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bed?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA2WXCECDUNAXEDTC7%2F20240111%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240111T221949Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Security-Token=FwoGZXIvYXdzEOL%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDLsQ9zOvlvM6kSMbRiKCA1TcKckp5wYtLHAIUTiZmmVdvjfcx8OmLYKuQR2oFHeK2UWpZBuI1fONSqNYvKzE4jDkH5tk3eX5VOHnwy7XpIfES9RKEFAH87bdQSKGJvPygwkHgs0FcBDmOyEP%2FAxgQaVrOFS30u37SWZVIfnDbkeMWYzx2gLxEskJPpo0jdHgFAnePhD3Ah4fLV7gkqorlxqylVwUQH%2B48LLlw4UtWXY%2FZu1ks85pmV4PdtZZA0daF7bvcy8Wsq%2BY8mlaMQfOzpAcgWUv%2B7OynuO8yOWaHLcv1XxYyzbCtlDRfJrTCA9dw5G%2BCJvwimz2iWTNh8k7REeBkphREC%2Bvgi5AszhJ7aSZL%2Fb9q0wCIzNT1cKiw0yPyQkWccjOoXzPIKGD%2FYEtTlhYMfhRwyCIQyOcpR8ZdrosJxIDPCvwUXH2Ie9RJFaMZGduvF8dZHOmivFkOPUjIDmGmrXql4bctdbJ35PcrdxTJ2jKcVoSpCBPQD6SmE%2BmLF2VWjIK3gEEU2q%2FieE%2BN6H%2FKJut56sGMjME3QePG%2FcpftacJUZxI4q6T7ADCBt88IdSyQtc4bDDKqr08mC3tUNL5tJwy%2BZdO7JvraU%3D&X-Amz-Signature=697240185a5b208e7ba6fcfb892c10bfcc68c029fab850a2a7cbdc60625005f2"
RUN wget -O all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bim "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bim?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA2WXCECDUNAXEDTC7%2F20240111%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240111T221949Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Security-Token=FwoGZXIvYXdzEOL%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDLsQ9zOvlvM6kSMbRiKCA1TcKckp5wYtLHAIUTiZmmVdvjfcx8OmLYKuQR2oFHeK2UWpZBuI1fONSqNYvKzE4jDkH5tk3eX5VOHnwy7XpIfES9RKEFAH87bdQSKGJvPygwkHgs0FcBDmOyEP%2FAxgQaVrOFS30u37SWZVIfnDbkeMWYzx2gLxEskJPpo0jdHgFAnePhD3Ah4fLV7gkqorlxqylVwUQH%2B48LLlw4UtWXY%2FZu1ks85pmV4PdtZZA0daF7bvcy8Wsq%2BY8mlaMQfOzpAcgWUv%2B7OynuO8yOWaHLcv1XxYyzbCtlDRfJrTCA9dw5G%2BCJvwimz2iWTNh8k7REeBkphREC%2Bvgi5AszhJ7aSZL%2Fb9q0wCIzNT1cKiw0yPyQkWccjOoXzPIKGD%2FYEtTlhYMfhRwyCIQyOcpR8ZdrosJxIDPCvwUXH2Ie9RJFaMZGduvF8dZHOmivFkOPUjIDmGmrXql4bctdbJ35PcrdxTJ2jKcVoSpCBPQD6SmE%2BmLF2VWjIK3gEEU2q%2FieE%2BN6H%2FKJut56sGMjME3QePG%2FcpftacJUZxI4q6T7ADCBt88IdSyQtc4bDDKqr08mC3tUNL5tJwy%2BZdO7JvraU%3D&X-Amz-Signature=bafee3f83324a420082f77b5717bd4f7f8ba8aadabd11f91012acf9cf6e6451a"
RUN wget -O all_phase3_unique_grch37_dbsnp_b153_ld_pruned.fam "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.fam?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA2WXCECDUNAXEDTC7%2F20240111%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240111T221950Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Security-Token=FwoGZXIvYXdzEOL%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDLsQ9zOvlvM6kSMbRiKCA1TcKckp5wYtLHAIUTiZmmVdvjfcx8OmLYKuQR2oFHeK2UWpZBuI1fONSqNYvKzE4jDkH5tk3eX5VOHnwy7XpIfES9RKEFAH87bdQSKGJvPygwkHgs0FcBDmOyEP%2FAxgQaVrOFS30u37SWZVIfnDbkeMWYzx2gLxEskJPpo0jdHgFAnePhD3Ah4fLV7gkqorlxqylVwUQH%2B48LLlw4UtWXY%2FZu1ks85pmV4PdtZZA0daF7bvcy8Wsq%2BY8mlaMQfOzpAcgWUv%2B7OynuO8yOWaHLcv1XxYyzbCtlDRfJrTCA9dw5G%2BCJvwimz2iWTNh8k7REeBkphREC%2Bvgi5AszhJ7aSZL%2Fb9q0wCIzNT1cKiw0yPyQkWccjOoXzPIKGD%2FYEtTlhYMfhRwyCIQyOcpR8ZdrosJxIDPCvwUXH2Ie9RJFaMZGduvF8dZHOmivFkOPUjIDmGmrXql4bctdbJ35PcrdxTJ2jKcVoSpCBPQD6SmE%2BmLF2VWjIK3gEEU2q%2FieE%2BN6H%2FKJut56sGMjME3QePG%2FcpftacJUZxI4q6T7ADCBt88IdSyQtc4bDDKqr08mC3tUNL5tJwy%2BZdO7JvraU%3D&X-Amz-Signature=b7e756b0d1c95e7aa162d8f55c467bfdf3f852c615adff770a02ef8bc5675835"
RUN wget -O 1000g_variants.tsv "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/1000g_variants.tsv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA2WXCECDUNAXEDTC7%2F20240111%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240111T221951Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Security-Token=FwoGZXIvYXdzEOL%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDLsQ9zOvlvM6kSMbRiKCA1TcKckp5wYtLHAIUTiZmmVdvjfcx8OmLYKuQR2oFHeK2UWpZBuI1fONSqNYvKzE4jDkH5tk3eX5VOHnwy7XpIfES9RKEFAH87bdQSKGJvPygwkHgs0FcBDmOyEP%2FAxgQaVrOFS30u37SWZVIfnDbkeMWYzx2gLxEskJPpo0jdHgFAnePhD3Ah4fLV7gkqorlxqylVwUQH%2B48LLlw4UtWXY%2FZu1ks85pmV4PdtZZA0daF7bvcy8Wsq%2BY8mlaMQfOzpAcgWUv%2B7OynuO8yOWaHLcv1XxYyzbCtlDRfJrTCA9dw5G%2BCJvwimz2iWTNh8k7REeBkphREC%2Bvgi5AszhJ7aSZL%2Fb9q0wCIzNT1cKiw0yPyQkWccjOoXzPIKGD%2FYEtTlhYMfhRwyCIQyOcpR8ZdrosJxIDPCvwUXH2Ie9RJFaMZGduvF8dZHOmivFkOPUjIDmGmrXql4bctdbJ35PcrdxTJ2jKcVoSpCBPQD6SmE%2BmLF2VWjIK3gEEU2q%2FieE%2BN6H%2FKJut56sGMjME3QePG%2FcpftacJUZxI4q6T7ADCBt88IdSyQtc4bDDKqr08mC3tUNL5tJwy%2BZdO7JvraU%3D&X-Amz-Signature=c6bcd97c62b05ec76ac94e266a10f4adc2ac6f392ebf46f858e57ec04c67defc"
RUN wget -O phase3_orig.psam "https://rti-common.s3.us-east-1.amazonaws.com/ancestry/smartpca_mahal_pipeline/phase3_orig.psam?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA2WXCECDUNAXEDTC7%2F20240111%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240111T221950Z&X-Amz-Expires=8640&X-Amz-SignedHeaders=host&X-Amz-Security-Token=FwoGZXIvYXdzEOL%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDLsQ9zOvlvM6kSMbRiKCA1TcKckp5wYtLHAIUTiZmmVdvjfcx8OmLYKuQR2oFHeK2UWpZBuI1fONSqNYvKzE4jDkH5tk3eX5VOHnwy7XpIfES9RKEFAH87bdQSKGJvPygwkHgs0FcBDmOyEP%2FAxgQaVrOFS30u37SWZVIfnDbkeMWYzx2gLxEskJPpo0jdHgFAnePhD3Ah4fLV7gkqorlxqylVwUQH%2B48LLlw4UtWXY%2FZu1ks85pmV4PdtZZA0daF7bvcy8Wsq%2BY8mlaMQfOzpAcgWUv%2B7OynuO8yOWaHLcv1XxYyzbCtlDRfJrTCA9dw5G%2BCJvwimz2iWTNh8k7REeBkphREC%2Bvgi5AszhJ7aSZL%2Fb9q0wCIzNT1cKiw0yPyQkWccjOoXzPIKGD%2FYEtTlhYMfhRwyCIQyOcpR8ZdrosJxIDPCvwUXH2Ie9RJFaMZGduvF8dZHOmivFkOPUjIDmGmrXql4bctdbJ35PcrdxTJ2jKcVoSpCBPQD6SmE%2BmLF2VWjIK3gEEU2q%2FieE%2BN6H%2FKJut56sGMjME3QePG%2FcpftacJUZxI4q6T7ADCBt88IdSyQtc4bDDKqr08mC3tUNL5tJwy%2BZdO7JvraU%3D&X-Amz-Signature=718dc4214ee4a56a4150c66b69ec08960d4e7584658b0240c17437abfca59c4b"

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

