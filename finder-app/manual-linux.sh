#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-


if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi



mkdir -p ${OUTDIR}

#Check that OUTDIR was actually created
if [ -d "$OUTDIR" ]
	then
		echo "$OUTDIR created"
	else
		exit 1
fi


#Save scritps for later
mkdir -p ${OUTDIR}/finder-app
mkdir -p ${OUTDIR}/conf
cp -r ../conf/* ${OUTDIR}/conf/
cp -r * ${OUTDIR}/finder-app/

cd ${OUTDIR}

if [ ! -d "${OUTDIR}/linux" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux/arch/${ARCH}/boot/Image ]; then
    cd linux
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # DONE: Add your kernel build steps here

    #STEP0 install cross compiler
    wget -O gcc-arm.tar.xz https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu.tar.xz
    mkdir ${OUTDIR}/install
    tar x -C ${OUTDIR}/install -f gcc-arm.tar.xz
    rm -r gcc-arm.tar.xz
    export PATH=${PATH}:${OUTDIR}/install/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/bin

    #STEP1: Install necessary packages
    sudo apt-get update && apt-get install -y --no-install-recommends \
    bc git u-boot-tools kmod cpio flex bison libssl-dev psmisc fakeroot && \
    xz-utils build-essential ncurses-dev libelf-dev bsdmainutils && \
    sudo apt-get install -y qemu-system-arm

    #STEP2_a): Build kernel deep clean, remove any .config file
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper

    #STEP2_b): Build kernel configure to be used with "virt" ARM board
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

    #STEP2_c): Build kernel image
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all

    #STEP3): Build kernel modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules

    #STEP4): Build device tree
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs

fi

#not necessary for this assignment... vmlinux is already in the outdir
echo "Adding the Image in outdir"
cp ${OUTDIR}/linux/arch/${ARCH}/boot/Image ${OUTDIR}/Image


echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"

if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# DONE: Create necessary base directories
mkdir ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
mkdir bin dev etc home lib lib64 proc sbin sys tmp
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # DONE:  Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

# DONE: Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# DONE: Add library dependencies to rootfs
cp ${OUTDIR}/install/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/libc.so.6
cp ${OUTDIR}/install/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/libm.so.6
cp ${OUTDIR}/install/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/libresolv.so.2
cp ${OUTDIR}/install/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/ld-linux-aarch64.so.1

# DONE: Make device nodes
cd ${OUTDIR}/rootfs
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1

# DONE: Clean and build the writer utility
#Copy the writer utility

cd ${OUTDIR}/finder-app
make CROSS_COMPILE=${CROSS_COMPILE} clean
make CROSS_COMPILE=${CROSS_COMPILE} all


# DONE: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -r  ${OUTDIR}/conf ${OUTDIR}/rootfs/home/conf
cp ${OUTDIR}/finder-app/writer  ${OUTDIR}/rootfs/home/writer
cp -r ${OUTDIR}/finder-app/finder.sh  ${OUTDIR}/rootfs/home/
cp -r ${OUTDIR}/finder-app/finder-test.sh  ${OUTDIR}/rootfs/home/

# DONE: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs/

# DONE: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
cd ${OUTDIR}
gzip -f initramfs.cpio
