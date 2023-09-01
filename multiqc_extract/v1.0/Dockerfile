# Docker image name: multiqc_extract
# Sample build: docker build -t multiqc_extract:v1 .
# Sample run: docker run -it -v $PWD:/usr/local/src/myscripts multiqc_extract:v1.0

# FROM arm64v8/r-base
FROM r-base

LABEL maintainer=dnwilliams@rti.org

RUN apt update && apt install -y jq && jq --version

COPY . /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts

SHELL ["/bin/bash", "-c"]
RUN ["chmod", "+x", "./unzip_extract_stats.sh"]
CMD ["bash","./unzip_extract_stats.sh"]