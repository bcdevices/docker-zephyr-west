FROM buildpack-deps:bionic-scm

ARG CMAKE_VERSION=3.20.5
ARG ZSDK_VERSION=0.13.1
ARG ZEPHYR_ZREPO_VERSION=2.7.0-rc4
ARG WGET_ARGS="-q --show-progress --progress=bar:force:noscroll --no-check-certificate"

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
		g++-multilib \
		git \
		gperf \
		lbzip2 \
		libc6-dev \
		libsdl2-dev \
		ninja-build \
		make \
		pkg-config \
		python3-dev \
		python3-pip \
		python3-setuptools \
		python3-tk \
		python3-wheel \
		unzip \
		wget \
		xz-utils \
		zip \
	  && rm -rf /var/lib/apt/lists/*

RUN wget ${WGET_ARGS} https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
  && chmod +x cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
  && ./cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local \
  && rm -f ./cmake-${CMAKE_VERSION}-Linux-x86_64.sh

RUN wget ${WGET_ARGS} https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}-linux-x86_64-setup.run && \
	sh "zephyr-sdk-${ZSDK_VERSION}-linux-x86_64-setup.run" --quiet -- -d /opt/toolchains/zephyr-sdk-${ZSDK_VERSION} && \
	rm "zephyr-sdk-${ZSDK_VERSION}-linux-x86_64-setup.run"

ENV ZEPHYR_TOOLCHAIN_VARIANT zephyr
ENV ZEPHYR_SDK_INSTALL_DIR /opt/toolchains/zephyr-sdk-${ZEPHYR_ZSDK_VERSION}

RUN python3 -m pip install -U pip

RUN pip3 install --upgrade west

RUN mkdir -p /usr/src/zephyr-${ZEPHYR_ZREPO_VERSION}
WORKDIR /usr/src/zephyr-${ZEPHYR_ZREPO_VERSION}
RUN west init --mr v${ZEPHYR_ZREPO_VERSION} && west update && west zephyr-export
RUN pip3 install -r zephyr/scripts/requirements.txt
