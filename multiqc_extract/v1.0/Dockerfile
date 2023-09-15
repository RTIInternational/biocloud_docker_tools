# FROM arm64v8/r-base
FROM r-base:4.3.1

LABEL maintainer=dnwilliams@rti.org

RUN apt update && apt install -y jq && jq --version

# Add scripts to make it run
ADD unzip_extract_stats.sh /

# Add to /opt folder
RUN mv unzip_extract_stats.sh /opt/

# Change permissions to make things exectuable
RUN chmod u+x /opt/unzip_extract_stats.sh

# Set wrkdir
RUN mkdir /data
COPY ./*.r /data
COPY ./*.zip /data
WORKDIR /data

# Add to environment
ENV PATH $PATH:/opt/