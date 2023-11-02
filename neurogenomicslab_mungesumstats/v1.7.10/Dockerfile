##################### Set Inital Image to work from ############################
# uses R v4.3.0
FROM neurogenomicslab/mungesumstats:1.7.10 

##################### Add Container Labels #####################################
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL description="Perform genomic liftover"
LABEL software-website="https://github.com/neurogenomics/MungeSumstats"
LABEL software-version="1.7.10"
LABEL base-image="https://hub.docker.com/layers/neurogenomicslab/mungesumstats/1.7.10/images/sha256-5710a42222645be376d0e746b8ffb20df1dd315515d7d3e4190f11fb27e3e7e3?context=explore"


# Set the locale to C.UTF-8 for consistent character encoding behavior
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# argparse needed for parsing command line arguments
RUN R -e "install.packages('argparse')"

# Copy your custom R script into the container
COPY neurogenomics_liftover.R /opt/neurogenomics_liftover.R

# Set the working directory
WORKDIR /data/

# Define the command to run the R script
CMD ["Rscript", "/opt/neurogenomics_liftover.R --help"]
