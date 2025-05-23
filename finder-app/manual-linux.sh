#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

SYSROOT=$(${CROSS_COMPILE}gcc --print-sysroot)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    sudo apt-get update && sudo apt-get install -y --no-install-recommends libssl-dev # fatal error: openssl/bio.h: No such file or directory
    echo "Kernel build steps started......"
    echo "****************** mrproper step **********************"
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- mrproper
    echo "****************** defconfig step **********************"
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig
    echo "****************** All step **********************"
    make -j10 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- all
    # make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- modules
    echo "****************** dtbs step **********************"
    make -j10 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- dtbs


fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/arm64/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
echo "Creating necessary base directories in ${OUTDIR}/rootfs"
mkdir -p ${OUTDIR}/rootfs
mkdir -p ${OUTDIR}/rootfs/{bin,dev,etc,home,lib,lib64,proc,sbin,sys,tmp,usr,var,conf}
mkdir -p ${OUTDIR}/rootfs/usr/{bin,lib,sbin}
mkdir -p ${OUTDIR}/rootfs/var/log


cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    
else
    cd busybox
fi

# TODO: Make and install busybox
echo "Building busybox"
make distclean
make defconfig
make -j10 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make -j10 CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
sudo chown -R root:root ${OUTDIR}/busybox

echo "Library dependencies"
cd ${OUTDIR}/rootfs
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

###################################################################
# TODO: Add library dependencies to rootfs
cp ${SYSROOT}/lib/ld-linux-aarch64.so.1 lib
cp ${SYSROOT}/lib64/libm.so.6 lib64
cp ${SYSROOT}/lib64/libresolv.so.2 lib64
cp ${SYSROOT}/lib64/libc.so.6 lib64
##################################################################

# TODO: Make device nodes
echo "Making device nodes"
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/console c 5 1
echo "Device nodes created"
# TODO: Clean and build the writer utility
make -C ${FINDER_APP_DIR} clean 
make -C ${FINDER_APP_DIR} CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
sudo cp -r $FINDER_APP_DIR/finder.sh $OUTDIR/rootfs/home
sudo cp -r $FINDER_APP_DIR/writer $OUTDIR/rootfs/home
sudo cp -r $FINDER_APP_DIR/finder-test.sh $OUTDIR/rootfs/home
sudo cp -r $FINDER_APP_DIR/conf $OUTDIR/rootfs/home
sudo cp -r $FINDER_APP_DIR/Makefile $OUTDIR/rootfs/home
sudo cp -r $FINDER_APP_DIR/autorun-qemu.sh $OUTDIR/rootfs/home
# TODO: Chown the root directory
sudo chown -R root:root $OUTDIR/rootfs

# TODO: Create initramfs.cpio.gz
cd "$OUTDIR/rootfs"
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio
echo "Created initramfs.cpio.gz"