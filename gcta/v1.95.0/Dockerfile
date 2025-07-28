FROM ubuntu@sha256:1ec65b2719518e27d4d25f104d93f9fac60dc437f81452302406825c46fcc9cb
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

WORKDIR "/home"

ENV DEBIAN_FRONTEND=noninteractive
ENV SPECTRA_LIB="/home/spectra/include"
ENV MKLROOT="/home/mkl_pkg/mkl/latest"
ENV MKL_DIR="/home/mkl_pkg/mkl/2025.2/lib/cmake/mkl/"
ENV BOOST_LIB="/usr/include/boost"
ENV EIGEN3_INCLUDE_DIR="/home/eigen_pkg/share/eigen3"
ENV Eigen3_DIR=/home/eigen_pkg/share/eigen3/cmake/

RUN apt update && apt install -y \
        build-essential=12.9ubuntu3 \
        wget=1.21.2-2ubuntu1 \
        git=1:2.34.1-1ubuntu1.15 \
        unzip=6.0-26ubuntu3.1 \
        libboost-all-dev=1.74.0.3ubuntu7 \
        zlib1g-dev=1:1.2.11.dfsg-2ubuntu9.2 \
        libgomp1=12.3.0-1ubuntu1~22.04 \
        libsqlite3-dev=3.37.2-2ubuntu0.5 \
        libzstd-dev=1.4.8+dfsg-3build1 \
        libgsl-dev=2.7.1+dfsg-3 \
        ca-certificates=20240203~22.04.1 \
        gnupg=2.2.27-3ubuntu2.4 \
        software-properties-common=0.99.22.9 \
        cmake=3.22.1-1ubuntu1.22.04.2 \
        tcl=8.6.11+1build2

RUN cd /home && \
    wget --no-check-certificate --quiet https://registrationcenter-download.intel.com/akdlm/IRC_NAS/47c7d946-fca1-441a-b0df-b094e3f045ea/intel-onemkl-2025.2.0.629_offline.sh && \
    chmod +x intel-onemkl-2025.2.0.629_offline.sh && \
    ./intel-onemkl-2025.2.0.629_offline.sh -a -s --eula accept --install-dir /home/mkl_pkg && \
    rm intel-onemkl-2025.2.0.629_offline.sh

RUN cd /home && \
    git clone https://gitlab.com/libeigen/eigen.git && \
    cd eigen && \
    git checkout tags/3.3.7 && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/home/eigen_pkg .. && \
    make -j 12 && \
    make install -j 12 && \
    rm -rf /home/eigen

RUN cd /home && \
    git clone https://github.com/yixuan/spectra/ && \
    cd spectra && \
    git checkout tags/v1.0.1 && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX="/home/spectra_pkg" ..

RUN cd /home && \
    git clone https://github.com/JianYang-Lab/GCTA.git && \
    cd GCTA && \
    git checkout a66e042faa38c2441ce204522f7fbf7d282f3631 && \
    git submodule update --init && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j 12

ENV PATH="/home/GCTA/build:${PATH}"

CMD ["gcta64"]
