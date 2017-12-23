#!/bin/zsh

HOME=~$USER
ZPREZTO_HOME=${HOME}/.zprezto

sudo apt-get update -y
sudo apt-get install -y build-essential python3 python3-dev cmake git \
	libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev \
	python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev \
	libtiff-dev libjasper-dev libdc1394-22-dev libgtk2.0-dev

echo "Bootstrap cmake? (yes/no [no])"
read input

if [[ "x${input}" == "x" ]]; then
    input="yes"
fi

if [[ "${input}" == "yes" ]]; then
	cd ${HOME}/Downloads
    wget https://cmake.org/files/v3.10/cmake-3.10.1.tar.gz
    tar -xzf cmake-3.10.1.tar.gz
    rm -f cmake-3.10.1.tar.gz
    cd cmake-3.10.1
    ./bootstrap
    make -j8
    make install
fi

if [[ -a ~/opencv/opencv ]]; then
    echo "Using existing opencv repo"
    cd ${HOME}/opencv/opencv
    git reset HEAD --hard
    rm -rf ${HOME}/opencv/opencv/build
else
    mkdir ${HOME}/opencv
    git clone https://github.com/opencv/opencv.git ${HOME}/opencv/opencv
    # git clone https://github.com/opencv/opencv_contrib.git ${HOME}/opencv/opencv_contrib
    cd ${HOME}/opencv/opencv
    git checkout 3.3.1
fi

mkdir ${HOME}/opencv/opencv/build
cd ${HOME}/opencv/opencv/build

cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local ..
make -j8

# cd ~/opencv/build/doc/
# make -j8 doxygen

sudo make install
