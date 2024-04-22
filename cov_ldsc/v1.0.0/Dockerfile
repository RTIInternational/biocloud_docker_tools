FROM python:2

# Maintainer and author
LABEL maintainer="Ravi Mathur <rmathur@rti.org>"

# clone cov-ldsc repo
ADD ldsc.py /opt/
RUN mkdir /opt/ldscore
ADD ldscore/ /opt/ldscore

# Change permissions to make things exectuable
RUN chmod 755 /opt/ldsc.py

# Install python modules
RUN pip install numpy pandas bitarray scipy

# Set working directory
RUN mkdir /data
WORKDIR /data

CMD [ "python", "/opt/ldsc.py"
