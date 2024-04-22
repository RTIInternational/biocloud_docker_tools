FROM bioconductor/bioconductor_docker:RELEASE_3_15

# author
LABEL maintainer="Eric Earley <eearley@rti.org>"
LABEL description="This image contains all the packages necessary to perform differential transcript usage analysis using satuRn."
LABEL software-website="https://github.com/statOmics/satuRn"
LABEL software-version="1.4.0"

# Install libraries
RUN Rscript -e 'BiocManager::install(c(
  "R.utils",
  "satuRn",
  "AnnotationHub",
  "ensembldb",
  "edgeR",
  "SummarizedExperiment",
  "ggplot2",
  "DEXSeq",
  "stageR"
 ), ask = FALSE)'

# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Default command
CMD ["R"]
