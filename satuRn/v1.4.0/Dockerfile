FROM bioconductor/bioconductor_docker:RELEASE_3_15

# author
LABEL maintainer="Eric Earley <eearley@rti.org>"
LABEL description="This image contains all the packages needed to run satuRn differential transcript usage analysis"
LABEL software-website="https://github.com/statOmics/satuRn"
LABEL software-version="1.4.0"
LABEL license="https://github.com/statOmics/satuRn?tab=coc-ov-file"


# Install libraries
RUN Rscript -e 'BiocManager::install(c("R.utils"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("satuRn"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("AnnotationHub"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("ensembldb"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("edgeR"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("SummarizedExperiment"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("ggplot2"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("DEXSeq"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("stageR"), ask = FALSE)'





# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Default command
CMD ["R"]
