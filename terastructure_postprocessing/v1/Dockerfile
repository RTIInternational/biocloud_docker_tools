FROM r-base:3.6.2

# =====================================================================
# Install R
# =====================================================================

# Maintainer and author
LABEL maintainer="Alex Waldrop <awaldrop@rti.org>"

# Install R packages
RUN R -e 'install.packages(c("vcd", "reshape2", "ggplot2"), repos="http://cran.us.r-project.org")'

# Add R helper script
ADD terastructure_postprocessing.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/terastructure_postprocessing.R

# Set wrkdir
RUN mkdir /data
WORKDIR /data

CMD = ["Rscript /opt/terastructure_postprocessing.R"]