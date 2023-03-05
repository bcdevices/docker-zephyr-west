FROM buildpack-deps:jammy-scm

ARG CMAKE_VERSION="3.20.5"
ARG ZSDK_VERSION="0.15.2"
ARG ZEPHYR_ZREPO_VERSION="3.3.0"
ARG WGET_ARGS="-q --progress=dot:giga --no-check-certificate"

# Container host platform, set automatically by `docker build`
ARG TARGETPLATFORM

# Setup environment
ENV DEBIAN_FRONTEND="noninteractive"
ENV TERM="xterm"

# Setup locale
# hadolint ignore=DL3008
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		locales \
	&& rm -rf /var/lib/apt/lists/* \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' "/etc/locale.gen" \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& update-locale

ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV LANG="C.UTF-8"

# Install needed packages
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
		ccache \
		clang-format \
		device-tree-compiler \
		dfu-util \
		file \
		g++ \
		gcc \
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
		srecord \
		qemu \
		unzip \
		wget \
		xz-utils \
		zip \
	  && rm -rf /var/lib/apt/lists/*

#
# Install CMake
#

# hadolint ignore=DL3047,DL3066
RUN case "${TARGETPLATFORM}" in linux/arm64) HOSTTYPE="aarch64";; linux/amd64|*) HOSTTYPE="x86-64";; esac \
	&& CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-${CMAKE_VERSION}-Linux-${HOSTTYPE}.sh" \
	&& wget ${WGET_ARGS} "${CMAKE_URL}" \
	&& chmod +x "cmake-${CMAKE_VERSION}-Linux-${HOSTTYPE}.sh" \
	&& "./cmake-${CMAKE_VERSION}-Linux-${HOSTTYPE}.sh" --skip-license --prefix="/usr/local" \
	&& rm -f "./cmake-${CMAKE_VERSION}-Linux-${HOSTTYPE}.sh" \
	&& mkdir "/opt/toolchains"

WORKDIR "/opt/toolchains"

#
# Install Zephyr SDK
#

# hadolint ignore=DL3047,DL3066
RUN case "${TARGETPLATFORM}" in linux/arm64) HOSTTYPE="aarch64";; linux/amd64|*) HOSTTYPE="x86-64";; esac \
	&& ZEPHYR_SDK_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}_linux-${HOSTTYPE}.tar.gz" \
	&& wget ${WGET_ARGS} "${ZEPHYR_SDK_URL}" \
	&& tar xf "zephyr-sdk-${ZSDK_VERSION}_linux-${HOSTTYPE}.tar.gz" \
	&& "zephyr-sdk-${ZSDK_VERSION}/setup.sh" -c -t "arm-zephyr-eabi" \
	&& rm -f "zephyr-sdk-${ZSDK_VERSION}_linux-${HOSTTYPE}.tar.gz"

ENV ZEPHYR_TOOLCHAIN_VARIANT="zephyr"
ENV ZEPHYR_SDK_INSTALL_DIR="/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}"

#
# Install Zephyr
#

# hadolint ignore=DL3013,DL3042
RUN python3 -m pip install -U pip \
	&& pip3 install --upgrade west \
	&& mkdir -p "/usr/src/zephyr-${ZEPHYR_ZREPO_VERSION}"

WORKDIR "/usr/src/zephyr-${ZEPHYR_ZREPO_VERSION}"

# hadolint ignore=DL3042
RUN west init --mr "v${ZEPHYR_ZREPO_VERSION}" \
	&& west update \
	&& west zephyr-export \
	&& pip3 install -r "zephyr/scripts/requirements.txt"
