#!/bin/bash
#Simple shell scirpt to partition mmc disk.

set -e

MB=$((1024*1024))
FW_SZ=$((32*1024*1024))

FAT32_PART_TYPE=0C
NO_FORMAT=

function copy_data()
{
	if [[ $IMAGE != "" && $fat_part_id != "" ]];then
		echo "Copying kernel to FAT partition $fat_part_id"
		mkdir -p rootfs/fat
		if [[ $mmcdev == 1 ]];then
			devstr=$dev'p'$fat_part_id
		else
			devstr=$dev$fat_part_id
		fi
		 umount $devstr 2> /dev/null || true
		 mount $devstr ./rootfs/fat
		 cp $IMAGE rootfs/fat
		 umount ./rootfs/fat
		rmdir rootfs/fat
		rmdir rootfs
	else
		if [[ $IMAGE != "" && $ext_part_id != "" ]];then
			echo "Copying kernel to extX partition $ext_part_id under /boot"
			mkdir -p rootfs/ext
			if [[ $mmcdev == 1 ]];then
				devstr=$dev'p'$ext_part_id
			else
				devstr=$dev$ext_part_id
			fi
			 umount $devstr 2> /dev/null || true
			 mount $devstr ./rootfs/ext
			 mkdir -p ./rootfs/ext/boot
			 cp $IMAGE ./rootfs/ext/boot/Image
			 umount ./rootfs/ext
			rmdir rootfs/ext
			rmdir rootfs
		fi
	fi

	if [[ $ROOTFS_IMG != "" ]];then
		if [[ $mmcdev == 1 ]];then
			devstr=$dev'p'$ext_part_id
		else
			devstr=$dev$ext_part_id
		fi
		if [[ ${ROOTFS_IMG} =~ \.tar ]];then
			mkdir -p rootfs/ext
			 umount $devstr 2> /dev/null || true
			 mount $devstr ./rootfs/ext
			if [[ ${OVERLAY_PATH} != "" ]]; then
				 rsync -av ${OVERLAY_PATH}/* ./rootfs/ext/
			fi
			 tar -C ./rootfs/ext -xvf ${ROOTFS_IMG}
			 umount ./rootfs/ext
			rmdir rootfs/ext
			rmdir rootfs
		else
			mkdir -p rootfs/ext
			mkdir -p rootfs/rfs
			 mount -o loop ${ROOTFS_IMG} rootfs/rfs
			 umount $devstr 2> /dev/null || true
			 mount $devstr ./rootfs/ext
			 rsync -a rootfs/rfs/* rootfs/ext
			 mkdir -p rootfs/ext/efi
			 cp $IMAGE rootfs/ext/efi
			 umount ./rootfs/ext
			 umount ./rootfs/rfs
			rmdir rootfs/ext
			rmdir rootfs/rfs
			rmdir rootfs
		fi
	fi
}

function format_partitions()
{
	# Only format fat partition if it is a new partition
	if [[ $fatpart == 1 ]];then
		echo $dev$fat_part_id
		if [[ $mmcdev == 1 ]];then
			devstr=$dev'p'$fat_part_id
		else
			devstr=$dev$fat_part_id
		fi
		 mkfs.vfat -F${fatfmt} -s 2 $devstr
		sleep 1
	fi

	# Always format extX partition
	if [[ $extpart == 1 || $ROOTFS_IMG ]];then
		echo $dev$ext_part_id
		if [[ $mmcdev == 1 ]];then
			devstr=$dev'p'$ext_part_id
		else
			devstr=$dev$ext_part_id
		fi
		 mke2fs -t ext${extfmt} $devstr || true
	fi
}

function create_partitions()
{
	cur_part_id=2
	#32MB sector offset after firmware image
	stsect=65536
	fatsect=0
	fatsectend=0
	extsect=0
	extsectend=0

	echo $fatsz $extsz
	if [[ $fatpart == 1 ]]; then
		fatsect=$stsect
		fatsectend=$(echo $fatsz 512 | awk '{printf "%f", $1 / $2}')
		sectmod=$(echo $fatsz 512 | awk '{printf "%f", $1 % $2}')
		if [[ ${sectmod%%.*} -gt 0 ]];then
			fatsectend=$(echo $fatsectend 1 | awk '{printf "%f", $1 + $2}')
		fi
		fatsectend=$(echo $fatsectend $fatsect | awk '{printf "%f", $1 + $2 - 1}')
		echo $fatsect $fatsectend $cur_part_id
		echo ${fatsect%%.*} ${fatsectend%%.*}

 fdisk $dev <<EOF
n
p
$cur_part_id
${fatsect%%.*}
${fatsectend%%.*}
t
$cur_part_id
$FAT32_PART_TYPE
p
w
EOF
		fat_part_id=$cur_part_id
		cur_part_id=3
		sleep 2
	fi

	if [[ $extpart == 1 ]]; then
		if [[ $fatpart == 1 ]];then
			extsect=$(echo $fatsectend 1 | awk '{printf "%f", $1 + $2}')
		else
			extsect=$stsect
		fi
		extsectend=$(echo $extsz 512 | awk '{printf "%f", $1 / $2}')
		extsectend=$(echo $extsectend $extsect | awk '{printf "%f", $1 + $2 - 1}')
		echo $extsect $extsectend
		echo ${extsect%%.*} ${extsectend%%.*}
 fdisk $dev <<EOF
n
p
$cur_part_id
${extsect%%.*}
${extsectend%%.*}
p
w
EOF
		ext_part_id=$cur_part_id
		sleep 2
	fi
}

function flash_firmware()
{
	if [[ $FWIMG != "" ]];then
		 dd if=$FWIMG of=$dev
	fi
}

function validate_part_size()
{
	calsz=$FW_SZ
	if [[ $fatpart == 1 ]];then
		fatsz=$(echo $fatsz $MB | awk '{printf "%f", $1 * $2}')
		calsz=$(echo $calsz $fatsz | awk '{printf "%f", $1 + $2}')
	fi
	if [[ $extpart == 1 ]];then
        if [[ "$extsz" == "0" ]]; then
            extsz=$(echo $totalsz $calsz | awk '{printf "%f", $1 - $2}')
            calsz=$totalsz
        else
            extsz=$(echo $extsz $MB | awk '{printf "%f", $1 * $2}')
            calsz=$(echo $calsz $extsz | awk '{printf "%f", $1 + $2}')
        fi
	fi
	echo $calsz $totalsz
	if [[ $(awk -v a="$calsz" -v b="$totalsz" 'BEGIN{print(a > b)}') == 1 ]];
	then
		echo "Partitions cumulative size exceeds total device size"
		echo "Leave 32MB for firmware image"
		exit 1
	fi
}

function get_device_size()
{
	totalsz=$(lsblk -n -b -d $dev --output SIZE)
	totalsz=$(echo $totalsz | awk '{printf "%f", $1}')
}

function check_args_images()
{
	if [[ $dev == "" ]];then
		echo "missing device parameter"
		exit 1
	fi

	case "$dev" in
		*/dev/mmc*)
		mmcdev=1
		;;
	esac

	if [[ $fatfmt == "" ]];then
		fatpart=0
	elif [[ $fatfmt != "12" && $fatfmt != "16" && $fatfmt != "32" && $fatfmt != "" ]];then
		echo "invalid fat format parameter"
		exit 1
	else
		if [[ $fat_part_id != "" ]];then
			echo "Kernel/FAT partition ID cannot be specified if repartitioning"
			exit 1
		fi
		fatpart=1
	fi

	if [[ $extfmt == "" ]];then
		extpart=0
		extfmt=4
	elif [[ $extfmt != "" && $extfmt != "4" ]];then
		echo "invalid ext format parameter"
		exit 1
	else
		if [[ $ext_part_id != "" ]];then
			echo "Rootfs/extX partition ID cannot be specified if repartitioning"
			exit 1
		fi
		extpart=1
	fi

	if [[ $fatpart == 1 && $fatsz == "" ]];then
		echo "missing fat size parameter"
		exit 1
	fi

	if [[ $extpart == 1 && $extsz == "" ]];then
		echo "missing ext size parameter"
		exit 1
	fi

	if [[ $FWIMG != "" ]];then
		if [ ! -f $FWIMG ];then
			echo "firmware image not found"
			exit 1
		fi
	fi

	if [[ $ROOTFS_IMG != "" ]];then
		if [ ! -f $ROOTFS_IMG ];then
			echo "No valid rootfs image/tarball found. Exiting"
			exit 1
		fi
	fi

	if [[ $IMAGE != "" ]];then
		if [ ! -f "$IMAGE" ];then
			echo "No valid kernel image found. Exiting"
			exit 1
		fi
	fi
}

function cleanup()
{
	if [ -e ./rootfs/ext ]; then
		 umount ./rootfs/ext > /dev/null 2>&1 || true
	fi
	if [ -e ./rootfs/fat ]; then
		 umount ./rootfs/fat > /dev/null 2>&1 || true
	fi
	if [ -e ./rootfs/rfs ]; then
		 umount ./rootfs/rfs > /dev/null 2>&1 || true
	fi
	if [ -e ./rootfs ]; then
		 rm -rf ./rootfs
	fi
}

show_help()
{
	echo "Usage: $0 -d/--dev <Device file> \\"
	echo "          -f/--fat <fat partition format> -fs/--fatsz <fat partition size> \\"
	echo "          -e/--ext <ext partition format> -es/--extsz <ext partition size> \\"
	echo "		-r/--rootfs <rootfs image file/tarball> \\"
	echo "		-k/--kernel <kernel image file> \\"
	echo "		-w/--firmware <firmware file>"
	echo "		-1  just update -w/--firmware <fw-file>, no re-format partitions"
	echo "Optional arguments"
	echo "		--extid <ext partition ID>"
	echo "		--fatid <fat partition ID>"
	echo "Note: make sure all partitions on device are un-mounted"
	echo "      acceptable unit of -fs and -es are M and G"
	echo "      Set es to \"MAX\" to occupy whole device"
	echo "Examples:"
	echo "   $0 -d /dev/sdb -w octeontx-bootfs-uboot-txx.img -k Image -r root.tar -e 4 -es MAX"
	echo "   $0 -d /dev/sdb -w octeontx-bootfs-uboot-txx.img -k Image -r root.tar -e 4 -es 4G"
	echo "   $0 -d /dev/sdb -w octeontx-bootfs-uboot-txx.img -1"
	echo " Guaranteed multi-step:"
	echo "   $0 -d /dev/sdb -w octeontx-bootfs-uboot-txx.img"
	echo "      this only creates Boot partition and destroys Linux partition"
	echo "   fdisk /dev/sdb"
	echo "      create partition2 from startSector 32768 (16MB) and size +4G"
	echo "      create partition3 from part2endSector+1 and size +4G"
	echo "   mkdir mtmp; mount /dev/sdb2 mtmp; create rootfs here"
	echo "NOTE(!):"
	echo " On startup check the correctness of Board Model/Revision"
	echo "    Board Model:    cn96xx-crb-r3   or   CN98XX-CRB"
	echo "    Board Revision: R3                   R2"
	echo " Correct them over BDK menu if needed"
	exit
}

if [[ $# -lt 2 ]]; then
	show_help;
fi

while [[ $# -gt 1 ]]
do
case $1 in
	-d|--dev)
		dev=$2
		shift
		;;
	-p|--plat)
		plat=$2
		shift
		;;
	-f|--fat)
		fatfmt=$2
		shift
		;;
	-fs|--fatsz)
                case $(echo $2 | grep -o "[a-zA-Z]") in
                    m|M)
		        fatsz=$(echo $2 | grep -o "[0-9]*")
                        ;;
                    g|G)
		        fatsz=$(echo $(echo $2 | grep -o "[0-9]*") 1024 | awk '{printf("%f"), $1 * $2}')
                        ;;
                    *)
                        echo can not recognize value of fs
                        exit 1
                        ;;
                esac
		shift
		;;
	-k|--kernel)
		IMAGE=$2
		shift
		;;
	-r|--rootfs)
		ROOTFS_IMG=$2
		shift
		;;
	-s|--overlay)
		OVERLAY_PATH=$2
		shift
		;;
	-w|--firmware)
		FWIMG=$2
		shift
		;;
	-1)
		NO_FORMAT=true
		shift
		;;
	-e|--ext)
		extfmt=$2
		shift
		;;
	--fatid)
		fat_part_id=$2
		shift
		;;
	--extid)
		ext_part_id=$2
		shift
		;;
	-es|--extsz)
                case $(echo $2 | grep -o "[a-zA-Z]*") in
                    m|M)
		        extsz=$(echo $2 | grep -o "[0-9]*")
                        ;;
                    g|G)
		        extsz=$(echo $(echo $2 | grep -o "[0-9]*") 1024 | awk '{printf("%f"), $1 * $2}')
                        ;;
                    max|MAX)
                        extsz=0
                        ;;
                    *)
                        echo can not recognize value of es
                        exit 1
                        ;;
                esac
		shift
		;;
	*)
		show_help
	;;
esac
    shift
done
cleanup
check_args_images
get_device_size
validate_part_size
flash_firmware
if [[ $NO_FORMAT ]]; then
 exit 0
fi
create_partitions || true
format_partitions || true
copy_data

