#!/bin/bash
# Snort3 Basic Setup
#
# Description: The following shell script sets up Snort3 with basic configuration
#
# Author: Tariro Mukute
# Version: 1.0.0

# set -o errexit
# set -o pipefail
# set -o nounset
# set -o xtrace


function install_dependencies {
    echo "Update APT and installing required build tools for Snort"
    apt update
    sudo dpkg-reconfigure tzdata

    mkdir ~/snort_src
    cd ~/snort_src

    apt install wget git systemctl -y
    apt-get install -y build-essential autotools-dev libdumbnet-dev libluajit-5.1-dev libpcap-dev \
    zlib1g-dev pkg-config libhwloc-dev cmake liblzma-dev openssl libssl-dev cpputest libsqlite3-dev \
    libtool uuid-dev  git autoconf bison flex libcmocka-dev libnetfilter-queue-dev libunwind-dev \
    libmnl-dev ethtool -y
}

function  install_safec {
    cd ~/snort_src
    wget https://github.com/rurban/safeclib/releases/download/v02092020/libsafec-02092020.tar.gz
    tar -xzvf libsafec-02092020.tar.gz
    cd libsafec-02092020.0-g6d921f
    ./configure
    make
    sudo make install
}

function install_pcre {
    cd ~/snort_src/
    wget wget https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.gz
    tar -xzvf pcre-8.45.tar.gz
    cd pcre-8.45
    ./configure
    make
    sudo make install
}

function install_gperftools {
    cd ~/snort_src
    wget https://github.com/gperftools/gperftools/releases/download/gperftools-2.9.1/gperftools-2.9.1.tar.gz 
    tar xzvf gperftools-2.9.1.tar.gz
    cd gperftools-2.9.1
    ./configure
    make
    sudo make install
}

function install_ragel {
    cd ~/snort_src
    wget http://www.colm.net/files/ragel/ragel-6.10.tar.gz
    tar -xzvf ragel-6.10.tar.gz
    cd ragel-6.10
    ./configure
    make
    sudo make install
}

function download_boost {
    cd ~/snort_src
    wget https://boostorg.jfrog.io/artifactory/main/release/1.77.0/source/boost_1_77_0.tar.gz
    
    tar -xvzf boost_1_77_0.tar.gz
}

function install_hyperscan {
    cd ~/snort_src
    wget https://github.com/intel/hyperscan/archive/refs/tags/v5.4.0.tar.gz
    tar -xvzf v5.4.0.tar.gz
    mkdir ~/snort_src/hyperscan-5.4.0-build
    cd hyperscan-5.4.0-build/
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=~/snort_src/boost_1_77_0/ ../hyperscan-5.4.0
    make
    sudo make install
}

function install_flatbuffers {
    cd ~/snort_src
    wget https://github.com/google/flatbuffers/archive/refs/tags/v2.0.0.tar.gz -O flatbuffers-v2.0.0.tar.gz
    tar -xzvf flatbuffers-v2.0.0.tar.gz
    mkdir flatbuffers-build
    cd flatbuffers-build
    cmake ../flatbuffers-2.0.0
    make
    sudo make install
}

function install_libdaq {
    cd ~/snort_src
    wget https://github.com/snort3/libdaq/archive/refs/tags/v3.0.5.tar.gz -O libdaq-3.0.5.tar.gz
    tar -xzvf libdaq-3.0.5.tar.gz
    cd libdaq-3.0.5
    ./bootstrap
    ./configure
    make
    sudo make install
}

function update_shared_libaries {
    sudo ldconfig
}

function install_snort_default_settings {
    cd ~/snort_src
    wget https://github.com/snort3/snort3/archive/refs/tags/3.1.17.0.tar.gz -O snort3-3.1.17.0.tar.gz
    tar -xzvf snort3-3.1.17.0.tar.gz
    cd snort3-3.1.17.0
    ./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc
    cd build
    make
    sudo make install

    echo "Verify Snort3"
    /usr/local/bin/snort -V

    echo "Test Snort with the default configuration"
    snort -c /usr/local/etc/snort/snort.lua

}

function install_pulledpork3 {
    cd ~/snort_src/
    git clone https://github.com/shirkdog/pulledpork3.git

    cd ~/snort_src/pulledpork3
    sudo mkdir /usr/local/bin/pulledpork3
    sudo cp pulledpork.py /usr/local/bin/pulledpork3
    sudo cp -r lib/ /usr/local/bin/pulledpork3
    sudo chmod +x /usr/local/bin/pulledpork3/pulledpork.py
    sudo mkdir /usr/local/etc/pulledpork3
    sudo cp etc/pulledpork.conf /usr/local/etc/pulledpork3/

    echo "Verify the PulledPork3 runs"
    /usr/local/bin/pulledpork3/pulledpork.py -V
}

function install_openappid {
    cd ~/snort_src/
    wget https://snort.org/downloads/openappid/23020 -O OpenAppId-23020.tgz
    tar -xzvf OpenAppId-23020.tgz
    sudo cp -R odp /usr/local/lib/
}

function install_snort_extras {
    cd ~/snort_src/
    wget https://github.com/snort3/snort3_extra/archive/refs/tags/3.1.17.0.tar.gz -O snort3_extra-3.1.17.0.tar.gz 
    tar -xzvf snort3_extra-3.1.17.0.tar.gz
    cd snort3_extra-3.1.17.0/
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/
    ./configure_cmake.sh --prefix=/usr/local
    cd build
    make
    sudo make install
}

function main {
    install_dependencies
    install_safec
    install_pcre
    install_gperftools
    install_ragel
    download_boost
    install_hyperscan
    install_flatbuffers
    install_libdaq
    update_shared_libaries
    install_snort_default_settings
    install_pulledpork3
    install_openappid
    install_snort_extras
}
# # Make sure that this is being run from the build-util folder
# pwd=`pwd`
# dirname=`basename ${pwd}`
# if [ ! ${dirname} = "build-util" ]
#         then
#         echo "Must run from build-util folder"
#         exit 1
# fi

# # Get the location where this script is located since it may have been run from any folder
# scriptFolder=`cd $(dirname "$0") && pwd`
# # Also determine the script name, for example for usage and version.
# # - this is useful to prevent issues if the script name has been changed by renaming the file
# scriptName=$(basename $scriptFolder)

main

