FROM r-base:3.5.3

LABEL maintainer=awaldrop@rti.org
LABEL author=jmarks@rti.org

# Install R packages
RUN R -e 'install.packages(c("ggplot2", "optparse", "viridis"), repos="http://cran.us.r-project.org")'

# =====================================================================
# Standard docker image stuff
# =====================================================================
# Add source files to /opt folder
ADD plot_ld_regression_results.R /

RUN mkdir /opt/plot_ld_regression
RUN mv plot_ld_regression_results.R /opt/plot_ld_regression

# Change permissions to make things exectuable
RUN chmod -R u+x /opt/plot_ld_regression

# Set wrkdir
RUN mkdir -p /data
WORKDIR /data
