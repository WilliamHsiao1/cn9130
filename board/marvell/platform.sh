#!/bin/sh

# Do nothing for stop - rcK on reboot
if [[ $1 == stop ]]; then
	exit 0
fi

# find out the CPU type
cpuid=`cat /proc/cpuinfo |grep -m1 "CPU part" | cut -c 12- -`

case $cpuid in
	0xd08)
		platform="ARMADA"
		;;
	0x0a3)
		platform="OCTEONTX"
		;;
	0x0b2 | 0x0b1)  # cn96xx or cn98xx same platform
		platform="OCTEONTX2"
		;;
	*)
		echo "WARNING! unknown CPU ID ($cpuid) detected!"
		exit 1
		;;
esac

# To run this script to be run on PC/Intel:
# - replace the /bin/sh with /bin/bash in first line
# - Set root=$PWD
# - Set $kver wit target Kernel version (like 4.14.76-16.0.0)
# - Set platform variable for required ARMADA or OCTEONTX or OCTEONTX2
root=/
prefix=$root/usr
kver=`uname -r`
#platform=...

plat1=`find $prefix/marvell -type d -name ARMADA    2>/dev/null`
plat2=`find $prefix/marvell -type d -name OCTEONTX  2>/dev/null`
plat3=`find $prefix/marvell -type d -name OCTEONTX2 2>/dev/null`

# Do nothing for canonical root-fs
[[ "$plat1" == "" && "$plat2" == "" && "$plat3" == "" ]] && exit 0

if [[ "$plat1" == "" || "$plat2" == "" || "$plat3" == "" ]]; then
  unified_fs=
  echo "Running on $platform SoC"
else
  unified_fs=true
  echo "Running on $platform SoC with unified file-system"
fi

# Remove Marvell interfaces from the common list, they are not available
# when startup script /etc/init.d/S40network is executing
sed -i '/Marvell  network configuration/,$d' /etc/network/interfaces

# ---------- Install-Update -------------------------------------------
# Run once disregarding to the NFS or single-plat or unified root-FS.
# Exit only if install-update already done.
#
[[ -f $prefix/marvell/_installed_plat.$platform ]] && exit 0

echo "Platform update started ..."

if [[ $unified_fs ]]; then
  # Set new /lib/modules/kernel-ver.<PLAT>.
  # But need to know the current~old for renaming
  base=$PWD
  cd $root/lib/modules
  curr_plat=`ls ./curr_platform/`
  if [[ "$curr_plat" == "" ]]; then
    mkdir -p ./curr_platform/
    echo "$platform" > ./curr_platform/$platform
    sync
    curr_plat=$platform
    echo "Cannot stat current platform for </lib/modules/$kver>. Force to $platform"
  fi
  if [[ $curr_plat != $platform ]]; then
    # Move old->new if not already set
    mv $kver $kver.$curr_plat
    mv $kver.$platform $kver
    mv curr_platform/$curr_plat curr_platform/$platform
    sync
  fi
  cd $base
fi

# Sync platform folders to the system default locations
plat_path=`find $prefix/marvell -type d -name $platform 2>/dev/null`
plat_folders=`find $plat_path -maxdepth 1 -type d 2>/dev/null`
for fldr in $plat_folders
do
	# remove the $plat_path from the folder name
	# to get the destination system folder name
	# /path/to/ARMADA/lib => $prefix/lib
	if [[ "$fldr" != "$plat_path" ]]; then
		cp -r ${fldr}/* ${prefix}/${fldr##$plat_path}/
	fi
done

depmod

# Create done marker file
echo "Platform folders successfully updated for $platform" > $prefix/marvell/_installed_plat.$platform
sync
echo "Platform folders successfully updated for $platform"

exit 0
