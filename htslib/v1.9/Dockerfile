FROM ubuntu:18.04
LABEL maintainer="Alex Waldrop <awaldrop@rti.org>"
LABEL version="1.9"

RUN apt-get update

RUN apt-get install -y wget gcc make bzip2 zlib1g-dev libbz2-dev liblzma-dev

RUN wget -nv https://github.com/samtools/htslib/releases/download/1.9/htslib-1.9.tar.bz2 && \
    tar xf htslib-1.9.tar.bz2 && \
    cd htslib-1.9 && \
    ./configure --prefix=/htslib-1.9 && \
    make && \
    make install && \
    make clean && \
    cp /htslib-1.9/bin/* /opt/ && \
    cd / && \
    rm -rf htslib-1.9.tar.bz2 htslib-1.9

RUN apt-get remove -y wget gcc make && \
    apt-get autoclean -y

WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/

CMD ["bgzip"]

