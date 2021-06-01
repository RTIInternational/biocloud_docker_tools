
# Base image
FROM python:3

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

#### Install python modules ####
RUN pip3 install tabulate biopython cgecore gitpython python-dateutil

#### Clone ResFinder repo ####
RUN git clone -b 4.1 https://bitbucket.org/genomicepidemiology/resfinder.git

#### Install blastn ####
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.11.0/ncbi-blast-2.11.0+-x64-linux.tar.gz \
    && tar -xvzf ncbi-blast-2.11.0+-x64-linux.tar.gz \
    && mv /ncbi-blast-2.11.0+/bin/blastn /resfinder/cge/

#### Install KMA ####
RUN cd /resfinder/cge/ \
    && git clone https://bitbucket.org/genomicepidemiology/kma.git \
    && cd kma \
    && make
ENV PATH=$PATH:/resfinder/cge/kma

#### Install databases ####
RUN cd /resfinder \
    && git clone https://git@bitbucket.org/genomicepidemiology/resfinder_db.git db_resfinder \
    && git clone https://git@bitbucket.org/genomicepidemiology/pointfinder_db.git db_pointfinder

#### Index databases ####
RUN cd /resfinder/db_resfinder/ \
    && python INSTALL.py \
    && cd /resfinder/db_pointfinder/ \
    && python INSTALL.py

WORKDIR /resfinder/

CMD ["python run_resfinder.py"]
