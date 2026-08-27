FROM bioconductor/bioconductor_docker:RELEASE_3_23

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Install R packages
RUN Rscript -e 'install.packages("devtools"); library("devtools");'
RUN Rscript -e 'install.packages("optparse"); library("optparse");'
RUN Rscript -e 'install.packages("magrittr"); library("magrittr");'
RUN Rscript -e 'install.packages("R.utils"); library("R.utils");'
RUN Rscript -e 'pak::pak("GenomicSEM/GenomicSEM"); require(GenomicSEM); require(Matrix); require(stats)'

# Add R helper script
ADD gsem_*.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/gsem_*.R

# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Parallel settings
ENV OPENBLAS_NUM_THREADS=1
ENV OMP_NUM_THREADS=1
ENV MKL_NUM_THREADS=1
ENV NUMEXPR_NUM_THREADS=1
ENV VECLIB_MAXIMUM_THREADS=1
