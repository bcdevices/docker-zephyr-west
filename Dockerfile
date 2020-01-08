FROM buildpack-deps:cosmic-scm

# Setup environment
ENV DEBIAN_FRONTEND noninteractive
ENV TERM=xterm

#Setup locale
RUN apt-get update && apt-get install -y --no-install-recommends \
		locales \
	  && rm -rf /var/lib/apt/lists/*
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV LANG=C.UTF-8

# Install needed packages
RUN apt-get update && apt-get install -y --no-install-recommends \
		ccache \
		device-tree-compiler \
		dfu-util \
		file \
		g++ \
		gcc \
		gcc-multilib \
		git \
		gperf \
		lbzip2 \
		libc6-dev \
		ninja-build \
		make \
		pkg-config \
		python3-pip \
		python3-setuptools \
		python3-tk \
		python3-wheel \
		unzip \
		wget \
		xz-utils \
		zip \
	  && rm -rf /var/lib/apt/lists/*

ENV CMAKE_VERSION 3.13.2
RUN wget -q https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-Linux-x86_64.sh \
  && chmod +x cmake-$CMAKE_VERSION-Linux-x86_64.sh \
  && ./cmake-$CMAKE_VERSION-Linux-x86_64.sh --skip-license --prefix=/usr/local \
  && rm -f ./cmake-$CMAKE_VERSION-Linux-x86_64.sh

ENV ZEPHYR_ZSDK_VERSION 0.10.3
RUN wget -nv https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v$ZEPHYR_ZSDK_VERSION/zephyr-sdk-$ZEPHYR_ZSDK_VERSION-setup.run \
  && sh zephyr-sdk-$ZEPHYR_ZSDK_VERSION-setup.run \
  && rm zephyr-sdk-$ZEPHYR_ZSDK_VERSION-setup.run
ENV ZEPHYR_TOOLCHAIN_VARIANT zephyr
ENV ZEPHYR_SDK_INSTALL_DIR /opt/zephyr-sdk

RUN pip3 install --upgrade \
	pip==19.2.3 \
	setuptools==41.0.1 \
	wheel==0.33.4
RUN pip3 install west==0.6.3

RUN mkdir -p /usr/src/zephyrproject
WORKDIR /usr/src/zephyrproject
RUN west init --mr v2.1.0 && west update
RUN pip3 install -r zephyr/scripts/requirements.txt
