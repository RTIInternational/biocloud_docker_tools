FROM python:2

# Maintainer and author
LABEL maintainer="Ravi Mathur <rmathur@rti.org>"

# update the OD related packages
#RUN apt-get update

#WORKDIR /usr/src/app

#COPY requirements.txt ./
#RUN pip install --no-cache-dir -r requirements.txt

#COPY . .

# clone cov-ldsc repo
ADD ldsc.py /opt/

# Change permissions to make things exectuable
RUN chmod 755 /opt/ldsc.py

# Install python modules
RUN pip install numpy
RUN pip install pandas

# Set wrkdir
RUN mkdir /data
WORKDIR /data

CMD [ "python", "/opt/ldsc.py" \
