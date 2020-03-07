FROM r-base:3.6.2 

# =====================================================================
# Install R
# =====================================================================

# Maintainer and author
LABEL maintainer="Alex Waldrop <awaldrop@rti.org>"

# Add R helper script
ADD generate_gwas_plots.R /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/generate_gwas_plots.R

# Set wrkdir
RUN mkdir /data
WORKDIR /data
