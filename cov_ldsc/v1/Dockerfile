FROM python:2.7-slim

#WORKDIR /usr/src/app

#COPY requirements.txt ./

# Maintainer and author
LABEL maintainer="Ravi Mathur <rmathur@rti.org>"

# Add R helper script
RUN cd /opt \
    git clone https://github.com/immunogenomics/cov-ldsc.git
#ADD ldsc.py /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/ldsc.py
#RUN pip install --no-cache-dir -r requirements.txt

#COPY . .

# Install python modules


# Set wrkdir
RUN mkdir /data
WORKDIR /data

