# Use the latest slim Debian stable image as the base
FROM debian:unstable-slim

# Default to the development branch of LLVM (currently 10)
# User can override this to a stable branch (like 8 or 9)
ARG LLVM_VERSION=10

# Make sure that all packages are up to date then
# install the base Debian packages that we need for
# building the kernel
RUN apt-get update -qq && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
        bc \
        binutils \
        binutils-aarch64-linux-gnu \
        binutils-arm-linux-gnueabi \
        binutils-mips-linux-gnu \
        binutils-mipsel-linux-gnu \
        binutils-powerpc-linux-gnu \
        binutils-powerpc64-linux-gnu \
        binutils-powerpc64le-linux-gnu \
        bison \
        ca-certificates \
        ccache \
        curl \
        expect \
        flex \
        git \
        gnupg \
        libelf-dev \
        libssl-dev \
        make \
        openssl \
        qemu-skiboot \
        qemu-system-arm \
        u-boot-tools \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

RUN cd /tmp/ && curl -O https://ozlabs.org/~joel/qemu-system-arm_4.2.0~rc2-0joel0_amd64.deb && curl -O https://ozlabs.org/~joel/qemu-system-data_4.2.0~rc2-0joel0_all.deb && curl -O https://ozlabs.org/~joel/qemu-system-common_4.2.0~rc2-0joel0_amd64.deb && dpkg -i *.deb && rm *.deb

# Install the latest nightly Clang/lld packages from apt.llvm.org
# Delete all the apt list files since they're big and get stale quickly
RUN curl https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/buster/ llvm-toolchain-buster$(test ${LLVM_VERSION} -ne 10 && echo "-${LLVM_VERSION}") main" | tee -a /etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        clang-${LLVM_VERSION} \
        lld-${LLVM_VERSION} \
        llvm-${LLVM_VERSION} && \
    chmod -f +x /usr/lib/llvm-${LLVM_VERSION}/bin/* && \
    rm -rf /var/lib/apt/lists/*

# Check and see Clang has not been rebuilt in more than five days if we are on the master branch and fail the build if so
# We copy, execute, then remove because it is not necessary to carry this script in the image once it's built
COPY scripts/check-clang.sh /
RUN bash /check-clang.sh && \
    rm /check-clang.sh

# Add a function to easily clone torvalds/linux, linux-next, and linux-stable
COPY env/clone_tree /root
RUN cat /root/clone_tree >> /root/.bashrc && \
    rm /root/clone_tree
