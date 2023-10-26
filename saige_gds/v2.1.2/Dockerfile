FROM bioconductor/bioconductor_docker:RELEASE_3_15

# author
LABEL maintainer="Eric Earley <eearley@rti.org>"

# add R script
ADD saige_gds.R /

# Move scripts to
RUN mv /saige_gds.R /opt/

# Change permissions to make things exectuable
RUN chmod -R u+x /opt/

CMD ["ls", "/opt/"]


# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Install libraries
#RUN Rscript -e 'BiocManager::install(c("R.utils"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("SeqArray"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("SAIGEgds"), ask = FALSE)'
RUN Rscript -e 'BiocManager::install(c("SNPRelate"), ask = FALSE)'

# add to PATH variable
RUN PATH=$PATH:/opt/

ENTRYPOINT ["Rscript", "/opt/saige_gds.R"]
