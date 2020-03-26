FROM r-base:3.6.2

# =====================================================================
# Install R
# =====================================================================

# Maintainer and author
LABEL maintainer="Alex Waldrop <awaldrop@rti.org>"

# Install R packages
RUN R -e 'install.packages(c("optparse"), repos="http://cran.us.r-project.org")'

# Add R helper script
ADD terastructure_merger.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/terastructure_merger.R

# Set wrkdir
RUN mkdir /data
WORKDIR /data

CMD = ["Rscript /opt/terastructure_merger.R"]