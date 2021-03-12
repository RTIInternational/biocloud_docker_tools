FROM rticode/deseq2:1.24.0

LABEL maintainer=awaldrop@rti.org

# Install R packages
RUN R -e 'install.packages(c("optparse", "readr"), repos="http://cran.us.r-project.org")'

# =====================================================================
# Standard docker image stuff
# =====================================================================
# Add source files to /opt folder
ADD merge_salmon_quant.R /

RUN mv merge_salmon_quant.R /opt/

# Change permissions to make things exectuable
RUN chmod -R u+x /opt/

# Set wrkdir
RUN mkdir -p /data
WORKDIR /data

ENV PATH=pkg-config:$PATH

CMD ["Rscript", "/opt/merge_salmon_quant.R", "--help"]