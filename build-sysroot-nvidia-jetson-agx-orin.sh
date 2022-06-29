#!/bin/bash

set -euf -o pipefail

CURRENT_DIRECTORY=$PWD
WORKING_DIRECTORY=$CURRENT_DIRECTORY/nvidia_sysroot
L4T_DIRECTORY=$WORKING_DIRECTORY/Linux_for_Tegra
SYSROOT_DIRECTORY=$L4T_DIRECTORY/rootfs
SYSROOT_ARCHIVE_FILE=sysroot-nvidia_jetson_agx_orin_ubuntu_20_04_aarch64.tar.xz

# Nvidia defines
SOC_NAME=t234
NVIDIA_DOWNLOAD_LOCATION=https://developer.nvidia.com/embedded/l4t/r34_release_v1.0/release
L4T_DRIVER_PACKAGE=jetson_linux_r34.1.0_aarch64.tbz2
SAMPLE_ROOT_FILESYSTEM=tegra_linux_sample-root-filesystem_r34.1.0_aarch64.tbz2

# Install needed tools to the host PC
sudo apt-get -y install \
    build-essential \
    g++-aarch64-linux-gnu \
    gcc-aarch64-linux-gnu \
    libopencv-dev \
    qemu-user-static \

# Fetch and unpack NVidia packages
rm -rf $WORKING_DIRECTORY
mkdir $WORKING_DIRECTORY
cd $WORKING_DIRECTORY
wget -P . $NVIDIA_DOWNLOAD_LOCATION/$L4T_DRIVER_PACKAGE
wget -P . $NVIDIA_DOWNLOAD_LOCATION/$SAMPLE_ROOT_FILESYSTEM
sudo rm -rf $L4T_DIRECTORY
echo "Extracting the Linux for Tegra driver package"
sudo tar xf $L4T_DRIVER_PACKAGE
sudo rm $SYSROOT_DIRECTORY/README.txt
echo "Extracting the root file system"
sudo tar xf $SAMPLE_ROOT_FILESYSTEM -C $SYSROOT_DIRECTORY

# Prepare the rootfs
cd $L4T_DIRECTORY
sudo ./apply_binaries.sh
sudo chown -R $USER.$USER $SYSROOT_DIRECTORY/
sudo rm $SYSROOT_DIRECTORY/etc/resolv.conf
sudo cp -av /usr/bin/qemu-aarch64-static $SYSROOT_DIRECTORY/usr/bin/
sudo cp -av /run/systemd/resolve/stub-resolv.conf $SYSROOT_DIRECTORY/etc/resolv.conf

# Add the missing SOC name to source list
sudo sed -i "s/<SOC>/$SOC_NAME/" $SYSROOT_DIRECTORY/etc/apt/sources.list.d/nvidia-l4t-apt-source.list

# Mount necessary host directories.
sudo mount -t sysfs -o ro none $SYSROOT_DIRECTORY/sys
sudo mount -t proc -o ro none $SYSROOT_DIRECTORY/proc
sudo mount -t tmpfs none $SYSROOT_DIRECTORY/tmp
sudo mount -o bind,ro /dev $SYSROOT_DIRECTORY/dev
sudo mount -t devpts none $SYSROOT_DIRECTORY/dev/pts
sudo mount -o bind,ro /etc/resolv.conf $SYSROOT_DIRECTORY/run/resolvconf/resolv.conf

sudo chroot $SYSROOT_DIRECTORY/ dpkg --configure -a
sudo chroot $SYSROOT_DIRECTORY/ apt update

sudo chroot $SYSROOT_DIRECTORY/ chown -R man: /var/cache/man/
sudo chroot $SYSROOT_DIRECTORY/ chmod -R 775 /var/cache/man/

# Install required packages
sudo chroot $SYSROOT_DIRECTORY/ apt -y install extra-cmake-modules nvidia-jetpack

# Fix CUDA library path
echo "/usr/lib/aarch64-linux-gnu/tegra" >> $SYSROOT_DIRECTORY/etc/ld.so.conf.d/000_cuda.conf

# Unmount all that was mounted
sudo umount $SYSROOT_DIRECTORY/sys
sudo umount $SYSROOT_DIRECTORY/proc
sudo umount $SYSROOT_DIRECTORY/tmp
sudo umount $SYSROOT_DIRECTORY/dev/pts
sudo umount $SYSROOT_DIRECTORY/dev
sudo umount $SYSROOT_DIRECTORY/run/resolvconf/resolv.conf

# Fix some symlinks
ln -sf ../../../lib/aarch64-linux-gnu/librt.so.1 $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/librt.so
ln -sf ../../../lib/aarch64-linux-gnu/libm.so.6 $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libm.so
ln -sf ../../../lib/aarch64-linux-gnu/libdl.so.2 $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libdl.so
ln -sf ../../../lib/aarch64-linux-gnu/libpthread.so.0 $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libpthread.so
ln -sf tegra/libcuda.so.1.1 $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libcuda.so.1
ln -sf tegra/libnvrm.so $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libnvrm.so
ln -sf tegra/libnvll.so $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libnvll.so
ln -sf tegra/libnvos.so $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libnvos.so
ln -sf tegra/libnvrm_graphics.so $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libnvrm_graphics.so
ln -sf tegra/libnvdc.so $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libnvdc.so
ln -sf tegra/libnvimp.so $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libnvimp.so
ln -sf libcudnn.so.8 $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libcudnn.so
ln -sf libz.so.1.2.11 $SYSROOT_DIRECTORY/usr/lib/aarch64-linux-gnu/libz.so

# Archive the sysroot
echo "Archiving the sysroot"
cd $CURRENT_DIRECTORY
sudo tar cf $SYSROOT_ARCHIVE_FILE --use-compress-program="xz -9T0" -C $SYSROOT_DIRECTORY .
