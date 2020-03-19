FROM r-base:3.6.2

# =====================================================================
# Install R
# =====================================================================

# Maintainer and author
LABEL maintainer="Alex Waldrop <awaldrop@rti.org>"

# Install R packages
RUN R -e 'install.packages(c("optparse", "igraph"), repos="http://cran.us.r-project.org")'

# Add R helper script
ADD process_king_kinship.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/process_king_kinship.R

# Set wrkdir
RUN mkdir /data
WORKDIR /data

CMD = ["Rscript", "/opt/process_king_kinship.R", "--help"]