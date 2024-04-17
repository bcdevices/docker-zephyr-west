#
# Copyright (c) 2019-2023 Blue Clover Devices
#
# SPDX-License-Identifier: Apache-2.0
#

# bcdevices/zsdk-zephyr-jammy
FROM buildpack-deps:jammy-scm

ARG ZSDK_VERSION="0.16.5"
ARG ZEPHYR_VERSION="3.6.0"

ARG ZSDK_ROOT_DIR="/opt/toolchains"
ARG ZEPHYR_SRC_DIR="/usr/src"
ARG ZEPHYR_INSTALL_DIR="${ZEPHYR_SRC_DIR}/zephyr-${ZEPHYR_VERSION}"

ARG PKGS
ENV PKGS="${PKGS} ccache"
ENV PKGS="${PKGS} clang-format"
ENV PKGS="${PKGS} cmake"
ENV PKGS="${PKGS} device-tree-compiler"
ENV PKGS="${PKGS} dfu-util"
ENV PKGS="${PKGS} file"
ENV PKGS="${PKGS} g++"
ENV PKGS="${PKGS} gcc"
ENV PKGS="${PKGS} git"
ENV PKGS="${PKGS} gnupg"
ENV PKGS="${PKGS} gperf"
ENV PKGS="${PKGS} lbzip2"
ENV PKGS="${PKGS} libc6-dev"
ENV PKGS="${PKGS} libmagic1"
ENV PKGS="${PKGS} libsdl2-dev"
ENV PKGS="${PKGS} lsb-release"
ENV PKGS="${PKGS} ninja-build"
ENV PKGS="${PKGS} make"
ENV PKGS="${PKGS} ovmf"
ENV PKGS="${PKGS} parallel"
ENV PKGS="${PKGS} pkg-config"
ENV PKGS="${PKGS} python3-dev"
ENV PKGS="${PKGS} python3-pip"
ENV PKGS="${PKGS} python3-setuptools"
ENV PKGS="${PKGS} python3-tk"
ENV PKGS="${PKGS} python3-wheel"
ENV PKGS="${PKGS} software-properties-common"
ENV PKGS="${PKGS} srecord"
ENV PKGS="${PKGS} qemu"
ENV PKGS="${PKGS} qemu-system"
ENV PKGS="${PKGS} unzip"
ENV PKGS="${PKGS} wget"
ENV PKGS="${PKGS} xz-utils"
ENV PKGS="${PKGS} zip"

ARG PKGS_amd64
ENV PKGS_amd64="${PKGS_amd64} g++-multilib"
ENV PKGS_amd64="${PKGS_amd64} gcc-multilib"

ARG WGET_ARGS="--progress=bar:force:noscroll --no-check-certificate"

ENV DEBIAN_FRONTEND="noninteractive"
ENV TERM="xterm"

# DL3008: `apt-get install <package>=<version>`
# hadolint ignore=DL3008
RUN apt-get update \
	&& apt-get install -y --no-install-recommends locales \
	&& rm -rf /var/lib/apt/lists/* \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& update-locale \
	&& mkdir -p "${ZEPHYR_SRC_DIR}" "${ZSDK_ROOT_DIR}"

ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV LANG="C.UTF-8"

# DL3008: `apt-get install <package>=<version>`
# hadolint ignore=DL3008
RUN apt-get update \
	&& apt-get install -y --no-install-recommends ${PKGS} \
	&& if [ "$(dpkg --print-architecture)" = amd64 ]; then \
		apt-get install -y --no-install-recommends ${PKGS_amd64}; \
		fi \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR "${ZSDK_ROOT_DIR}"

RUN zsdk_txz="zephyr-sdk-${ZSDK_VERSION}_linux-$(uname -m).tar.xz" \
 	&& url="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/${zsdk_txz}" \
	&& wget -O zsdk.txz "${url}" --progress=dot:giga ${WGET_ARGS} \
	&& tar xf zsdk.txz \
	&& rm -f zsdk.txz \
	&& "./zephyr-sdk-${ZSDK_VERSION}/setup.sh" -c -t arm-zephyr-eabi

ENV ZEPHYR_TOOLCHAIN_VARIANT="zephyr"
ENV ZEPHYR_SDK_INSTALL_DIR="${ZSDK_ROOT_DIR}/zephyr-sdk-${ZSDK_VERSION}"

# DL3013: `pip install <package>==<version>`
# DL3042: `pip install --no-cache-dir <package>`
# hadolint ignore=DL3013,DL3042
RUN python3 -m pip install -U pip \
	&& pip3 install --upgrade west

WORKDIR "${ZEPHYR_INSTALL_DIR}"

# DL3042: `pip install --no-cache-dir <package>
# hadolint ignore=DL3042
RUN west init --mr "v${ZEPHYR_VERSION}" \
	&& west update \
	&& west zephyr-export \
	&& pip3 install -r zephyr/scripts/requirements.txt
