FROM ubuntu:21.10
MAINTAINER Julien Salort, julien.salort@ens-lyon.fr

# For some reason, it gets stuck later on if ca-certificates-java is not installed first
RUN apt update && \
    apt upgrade -y
RUN apt install -y ca-certificates-java

# Create the ptluser
ARG USER_NAME=ptluser
ARG USER_HOME=/home/ptluser
ARG USER_ID=1000
ARG USER_GECOS=ptluser

RUN adduser \
  --home "$USER_HOME" \
  --uid $USER_ID \
  --gecos "$USER_GECOS" \
   --disabled-password \
  "$USER_NAME"

# Set timezone
RUN echo Europe/Paris > /etc/timezone && \
    ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

# Tools and compilers
RUN apt install -y build-essential git cmake pkg-config unzip yasm checkinstall gcc-10 gfortran-10 doxygen wget

# We use gcc 10 because opencv does not support GNU compiler > 10
ENV CC "/usr/bin/gcc-10"
ENV CXX "/usr/bin/g++-10"
ENV F70 "/usr/bin/gfortran-10"
ENV F90 "/usr/bin/gfortran-10"

# Python 3
RUN apt install -y python3-dev python3-pip python3-numpy python3-testresources  python3-venv

# Libraries
RUN apt install -y libeigen3-dev libtinyxml2-dev libtinyxml2.6.2v5 libboost-dev libboost-all-dev libtbb-dev libvtk7-dev libvtk7.1p libpcl-dev libusb-1.0-0-dev vim libmkl-tbb-thread python3-vtk7 vtk7 libvtk7-qt-dev tcl-vtk7 libgflags-dev libsuitesparse-dev libgoogle-glog-dev libatlas-base-dev libjpeg-dev libpng-dev libtiff-dev libavcodec-dev libavformat-dev libswscale-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libxvidcore-dev x264 libx264-dev libfaac-dev libmp3lame-dev libtheora-dev libfaac-dev libmp3lame-dev libvorbis-dev libopencore-amrnb-dev libopencore-amrwb-dev libdc1394-22-dev libxine2-dev libv4l-dev v4l-utils libgtk-3-dev libatlas-base-dev libprotobuf-dev protobuf-compiler libgoogle-glog-dev libgflags-dev libgphoto2-dev libeigen3-dev libhdf5-dev nvidia-cuda-dev nvidia-cuda-toolkit
#RUN apt install -y libopencv-dev libceres-dev

RUN update-alternatives --install /usr/bin/vtk vtk /usr/bin/vtk7 1
RUN ln -s -f /usr/include/linux/libv4l1-videodev.h /usr/include/videodev.h
RUN python3 -m venv /home/ptluser/ve39

# Install CERES from source
USER "$USER_NAME"

RUN cd /home/ptluser && \
    git clone https://ceres-solver.googlesource.com/ceres-solver && \
    mkdir /home/ptluser/ceres-build && \
    cd /home/ptluser/ceres-build && \
    cmake /home/ptluser/ceres-solver && \
    make && \
    make test

USER root

RUN cd /home/ptluser/ceres-build && \
    make install

# Install CNPY from source
USER "$USER_NAME"

RUN cd /home/ptluser && \
    git clone https://github.com/rogersce/cnpy.git && \
    mkdir /home/ptluser/cnpy-build && \
    cd /home/ptluser/cnpy-build && \
    cmake /home/ptluser/cnpy && \
    make

USER root
RUN cd /home/ptluser/cnpy-build && \
    make install

# Install OpenCV from fource
USER "$USER_NAME"

RUN mkdir /home/ptluser/opencv-build && \
    cd /home/ptluser/opencv-build && \
    wget -O opencv.zip https://github.com/opencv/opencv/archive/refs/tags/4.5.2.zip && \
    wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/refs/tags/4.5.2.zip && \
    unzip opencv.zip && \
    unzip opencv_contrib.zip && \
    mkdir /home/ptluser/opencv-build/opencv-4.5.2/build


RUN cd /home/ptluser/opencv-build/opencv-4.5.2/build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D WITH_TBB=ON \
          -D ENABLE_FAST_MATH=1 \
          -D CUDA_FAST_MATH=1 \
          -D WITH_CUBLAS=1 \
          -D WITH_CUDA=ON \
          -D BUILD_opencv_cudacodec=OFF \
          -D WITH_CUDNN=OFF \
          -D OPENCV_DNN_CUDA=OFF \
          -D CUDA_ARCH_BIN=7.5 \
          -D WITH_V4L=ON \
          -D WITH_QT=OFF \
          -D WITH_OPENGL=ON \
          -D WITH_GSTREAMER=ON \
          -D OPENCV_GENERATE_PKGCONFIG=ON \
          -D OPENCV_PC_FILE_NAME=opencv.pc \
          -D OPENCV_ENABLE_NONFREE=ON \
          -D OPENCV_PYTHON3_INSTALL_PATH=/home/ptluser/ve39/lib/python3.9/site-packages \
          -D PYTHON_EXECUTABLE=/home/ptluser/ve39/bin/python \
          -D OPENCV_EXTRA_MODULES_PATH=/home/ptluser/opencv-build/opencv_contrib-4.5.2/modules \
          -D INSTALL_PYTHON_EXAMPLES=OFF \
          -D INSTALL_C_EXAMPLES=OFF \
          -D BUILD_EXAMPLES=OFF /home/ptluser/opencv-build/opencv-4.5.2

RUN cd /home/ptluser/opencv-build/opencv-4.5.2/build && \    
    make

USER root

RUN cd /home/ptluser/opencv-build/opencv-4.5.2/build && \
    make install
    

# Install PTL
USER "$USER_NAME"

RUN cd /home/ptluser && \
    git clone https://bitbucket.org/eatgreen/ptl-light/src/master
ENV PTL_PATH "/home/ptluser/master"
ENV PTVDATA_PATH "/home/ptluser/data"
RUN mkdir /home/ptluser/data

RUN cd /home/ptluser/master && \
    cmake -Wno-dev -D PARALLEL_SCHEME=TBB build && \
    make

ENV HOME "$USER_HOME"
WORKDIR "$USER_HOME"
