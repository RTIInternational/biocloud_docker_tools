FROM r-base:4.3.2

#----------------------------------------------------------------
# Install R Packages
#----------------------------------------------------------------
RUN echo "r <- getOption('repos'); r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile
RUN Rscript -e "install.packages('getopt')"
RUN Rscript -e "install.packages('pdftools')"
RUN Rscript -e "install.packages('openxlsx', dependencies = T)"
RUN Rscript -e "install.packages('dplyr', dependencies = T)"
RUN Rscript -e "library('getopt');##### R SESSION INFORMATION #####; sessionInfo()"

#----------------------------------------------------------------
# Copy over analysis scripts
#----------------------------------------------------------------
RUN wget --no-check-certificate https://github.com/ExpressionAnalysis/CNV_Radar/archive/master.zip -O /opt/CNVRadar.zip && \
    unzip /opt/CNVRadar.zip -d /opt/CNVRadar && \
    mv /opt/CNVRadar/CNV_Radar-master/* /opt/CNVRadar/ && \
    rm -r /opt/CNVRadar/CNV_Radar-master/ && \
    rm /opt/CNVRadar.zip

#----------------------------------------------------------------
# Set working dir
#----------------------------------------------------------------
WORKDIR /data/
