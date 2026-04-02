FROM opensuse/tumbleweed

WORKDIR /tmp

# Base
RUN zypper install -y --no-recommends pam-extra
RUN zypper install -y --no-recommends tar gzip sed awk findutils grep coreutils e2fsprogs \
	    xfsprogs btrfsprogs fio duperemove keyutils lvm xfsdump quota \
	    perl libcap-progs device-mapper bind-utils \
	    util-linux util-linux-systemd udev acl attr xz wget \
	    less vim file hostname gzip diff hostname iputils iproute2 \
	    cpio sg3_utils elfutils dracut git socat busybox

# Basic build for kernel, btrfs-progs, fstests
RUN zypper install -y --no-recommends autoconf automake libtool make gcc bc m4 \
	    flex bison libopenssl-devel libelf-devel \
	    libudev-devel libattr-devel libblkid-devel libext2fs-devel \
	    libuuid-devel libzstd-devel lzo-devel pkg-config zlib-ng-devel \
	    xfsprogs-devel gdbm-devel libacl-devel \
	    libaio-devel libattr-devel libbtrfs-devel openssl-devel \
	    ccache
# Virtme
RUN zypper install -y virtme zstd virtiofsd \
	    openssh-common openssh-clients openssh-server \
	    qemu-headless qemu-microvm qemu-tools

# GH runner
RUN zypper install -y --no-recommends mono-core sudo lttng-ust libicu krb5

# The kvmmall is only for quick tests, lacks many modules
#RUN zypper install -y --no-recommends kernel-kvmsmall
RUN zypper install -y --no-recommends kernel-default

# Setup for fstests
RUN useradd -m fsgqa
RUN useradd 123456-fsgqa
RUN useradd fsgqa2
#RUN groupadd fsgqa
# Supposed to be mounted externally and contain prepopulated git trees
RUN mkdir /mnt/workspace

# Use fsgqa for the runner
RUN echo 'fsgqa ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/fsgqa

RUN zypper install -y --no-recommends rsync

# Run quick test against kernel-default
COPY ./test-vng .

CMD ["./test-vng"]
