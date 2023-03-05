# bcdevices/zsdk-zephyr-jammy
FROM buildpack-deps:jammy-scm

ARG CMAKE_VERSION="3.20.5"
ARG ZSDK_VERSION="0.15.2"
ARG ZEPHYR_ZREPO_VERSION="3.3.0"
ARG WGET_ARGS="-q --show-progress --progress=bar:force:noscroll --no-check-certificate"

ARG PKGS
ARG PKGS_amd64
ENV PKGS="${PKGS} ccache"
ENV PKGS="${PKGS} clang-format"
ENV PKGS="${PKGS} device-tree-compiler"
ENV PKGS="${PKGS} dfu-util"
ENV PKGS="${PKGS} file"
ENV PKGS="${PKGS} g++"
ENV PKGS_amd64="${PKGS_amd64} g++-multilib"
ENV PKGS="${PKGS} gcc"
ENV PKGS_amd64="${PKGS_amd64} gcc-multilib"
ENV PKGS="${PKGS} git"
ENV PKGS="${PKGS} gperf"
ENV PKGS="${PKGS} lbzip2"
ENV PKGS="${PKGS} libc6-dev"
ENV PKGS="${PKGS} libsdl2-dev"
ENV PKGS="${PKGS} ninja-build"
ENV PKGS="${PKGS} make"
ENV PKGS="${PKGS} pkg-config"
ENV PKGS="${PKGS} python3-dev"
ENV PKGS="${PKGS} python3-pip"
ENV PKGS="${PKGS} python3-setuptools"
ENV PKGS="${PKGS} python3-tk"
ENV PKGS="${PKGS} python3-wheel"
ENV PKGS="${PKGS} srecord"
ENV PKGS="${PKGS} qemu"
ENV PKGS="${PKGS} unzip"
ENV PKGS="${PKGS} wget"
ENV PKGS="${PKGS} xz-utils"
ENV PKGS="${PKGS} zip"

## Setup environment

ENV DEBIAN_FRONTEND="noninteractive"
ENV TERM="xterm"

## Setup locale

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

## Install needed packages

# hadolint ignore=DL3008
RUN arch="$(dpkg --print-architecture)" \
	&& if [ "${arch}" = "amd64" ]; then PKGS="${PKGS} ${PKGS_amd64}"; fi \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends ${PKGS} \
	&& rm -rf /var/lib/apt/lists/*

## Install CMake

# hadolint ignore=DL3047
RUN case "$(dpkg --print-architecture)" in arm64) arch="aarch64";; amd64) arch="x86_64";; esac \
	&& CMAKE_INSTALLER="cmake-${CMAKE_VERSION}-Linux-${arch}.sh" \
	&& CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_INSTALLER}" \
	&& wget ${WGET_ARGS} "${CMAKE_URL}" \
	&& chmod +x "${CMAKE_INSTALLER}" \
	&& "./${CMAKE_INSTALLER}" --skip-license --prefix="/usr/local" \
	&& rm -f "./${CMAKE_INSTALLER}" \
	&& mkdir "/opt/toolchains"
WORKDIR "/opt/toolchains"

## Install Zephyr SDK

# hadolint ignore=DL3047
RUN case "$(dpkg --print-architecture)" in arm64) arch="aarch64";; amd64) arch="x86_64";; esac \
	&& ZSDK_TGZ="zephyr-sdk-${ZSDK_VERSION}_linux-${arch}.tar.gz" \
 	&& ZSDK_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/${ZSDK_TGZ}" \
	&& ZSDK_INSTALLER="./zephyr-sdk-${ZSDK_VERSION}/setup.sh" \
	&& wget ${WGET_ARGS} "${ZSDK_URL}" \
	&& tar xf "${ZSDK_TGZ}" \
	&& "./${ZSDK_INSTALLER}" -c -t "arm-zephyr-eabi" \
	&& rm -f "${ZSDK_TGZ}"

ENV ZEPHYR_TOOLCHAIN_VARIANT="zephyr"
ENV ZEPHYR_SDK_INSTALL_DIR="/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}"

## Install Zephyr

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
