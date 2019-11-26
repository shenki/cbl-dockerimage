# Use the latest slim Debian stable image as the base
FROM debian:unstable-slim

# Default to the development branch of LLVM (currently 12)
# User can override this to a stable branch (like 10 or 11)
ARG LLVM_VERSION=12

# Make sure that all packages are up to date then
# install the base Debian packages that we need for
# building the kernel
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        bc \
        binutils \
        binutils-arm-linux-gnueabi \
        bison \
        ca-certificates \
        ccache \
        cpio \
        curl \
        expect \
        flex \
        git \
        gnupg \
        libelf-dev \
        libssl-dev \
        lz4 \
        make \
        openssl \
        qemu-system-arm \
        u-boot-tools \
        xz-utils \
        zstd && \
    rm -rf /var/lib/apt/lists/*

# Install the latest nightly Clang/lld packages from apt.llvm.org
# Delete all the apt list files since they're big and get stale quickly
RUN curl https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/unstable/ llvm-toolchain$(test ${LLVM_VERSION} -ne 12 && echo "-${LLVM_VERSION}") main" | tee -a /etc/apt/sources.list && \
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
