# Base image
FROM r-base:3.5.1

# Maintainer and author
LABEL maintainer="Jesse Marks <jmarks@rti.org>"

# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8


WORKDIR /

# Install REdiscoverTE 
RUN wget http://research-pub.gene.com/REdiscoverTEpaper/software/REdiscoverTE_1.0.1.tar.gz 
RUN tar -xvzf  REdiscoverTE_1.0.1.tar.gz \
  && mv REdiscoverTE /opt/ \
  && ln -s /opt/REdiscoverTE/rollup.R /opt/ 

# Install Salmon
RUN wget https://github.com/COMBINE-lab/salmon/releases/download/v0.8.2/Salmon-0.8.2_linux_x86_64.tar.gz \
  && tar -xvzf Salmon-0.8.2_linux_x86_64.tar.gz \
  && mv Salmon-0.8.2_linux_x86_64 /opt/ \
  && ln -s /opt/Salmon-0.8.2_linux_x86_64/bin/salmon /opt/ 

# Add /opt to executables path list
ENV PATH=pkg-config:$PATH:/opt/

# Install R packages
RUN Rscript -e "install.packages('optparse')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); BiocInstaller::biocLite(c('tibble', 'readr', 'dplyr', 'edgeR', 'Biobase'))"

# Clean up 
RUN rm REdiscoverTE_1.0.1.tar.gz Salmon-0.8.2_linux_x86_64.tar.gz


# Default command 
CMD ["Rscript /opt/rollup.R --help"]

