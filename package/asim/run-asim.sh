#!/bin/bash

# Locations of image files
SHARE_DIR=/tmp

SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
# Locations of files from ASIM .rpm or .deb archives
# $ASIM -- for *.asim configuration files
# it should point to a directory that has subdirectory 'configs'
# containing the ASIM configuration files from ASIM repo
ASIM="/usr/share/asim"
# $ASIM_LIBRARY_PATH -- directory containing device model shared objects
ASIM_LIBRARY_PATH="/usr/lib/asim"
# $ASIM_MANUAL_PATH -- directory containing manual pages for asim
ASIM_MANUAL_PATH="/usr/share/man"
# $ASIM_EXEC -- ASIM executable; by default from $PATH
UART0_BASE=${UART0_BASE:-2000}

print_help() {
cat << EOF
run-asim.sh [-a ASIM_PATH] [-s SHARE_DIR] [-h|--help] [(-i|--instance) INSTANCE] [-m] \\
            [-f SPI_BOOT_STRAP] --spi SPI_SOURCE [--mmc MMC_SOURCE] \\
	    [ --usb USB_SOURCE ] -r --rom ROM_SOURCE \\
            [ -b BPHYCNT ] [ -v BPHYTYPE ]
            [--use-dsp] [-e ASIM_ENV] --spi1 SPI_SOURCE1 PLAT

This script runs ASIM simulator.

PLAT -- platform to simulate (t96, f95, t98, cn10ka, cn10kas, loki, cnf10ka,
cnf10kb, cn10kb cn20ka cn20kas cnf20ka)

-a ASIM_PATH
	Specify the location of ASIM build.  By default, the scripts uses
	configuration files, device model shared objects and
	man pages installed in the system from DEB or RPM packages.
	If ASIM simulator was built from sources use this option
	to specify where to find these items.

-s SHARE_DIR
	Specify the location of to store SPI/MMC image files. By default, the script uses
	$SHARE_DIR .
	This path can be redefined with this -s option.

-b BPHYCNT
	Specify the number of chiplets in a given SOC. Applies only to cnf20k platform.

-v BPHYTYPE
	Specify BPHY variant to use. 0 = MP, 1 = RF. Apples only to cnf20k platform

--spi SPI_SOURCE
	Specify the SPI image source file.

--spi1 SPI1_SOURCE
	Specify the SPI1 image source file.

--mmc MMC_SOURCE
	Specify the MMC source file.

--dual	Primary device is dual, boot secondary using offset

--sdual	Secondary boot is dual, use offset for secondary boot

-m
	Simulate booting from MMC (T9x, T8x). Doesn't apply to cn10k/cn20k.

--usb USB_SOURCE
	Specify the USB source file. If not specific then same MMC_SOURCE image will be used for USB devices
	Available only for cn10k, cn20k platforms

--rom ROM_SOURCE
	Specify the BootROM binary file.  Optional for cn20k

--use-dsp
	Enable DSP engines while lauching asim (fusion platforms only).

-e ASIM_ENV
	Specify the env to be passed to asim command.
	Syntax is -e "VAR VALUE".
	User can pass this option more than once for each env variable.

-h
	Print this help.

-i INSTANCE
	Specify ASIM instance number.  If developer plans to run
	several instances of the simulator on one host he can specify
	instance number with this option so that ASIM uses network
	interfaces and port numbers for uart utility that do not clash.

-f SPI_BOOT_STRAP
	Simulate booting from SPI, specify spi boot source, the following options are available:
	spi0cs0, spi0cs1, spi1cs0, spi1cs1 (T9x)
	s0cs0s1cs0, s1cs0s0cs0, mmcs0cs0, mmcs1cs0 (cn10k cn20k)
	s0cs0dual, s0cs1dual, s1cs0dual, s1cs1dual, mmcdual, (cn20k)
	duals0cs0, duals0cs1, duals1cs0, duals1cs1, dualmmc (cn20k)
	s0cs0, s0cs1, s1cs0, s1cs1, mmc (cn20k) uses --dual or --sdual

-r
	Run asim without preparing the flash image or overwriting the rootfs.
	Make sure flash image and rootfs is already present

-u PORT
       Set the base TCP port number for the UART (UAA) block
        listeners.    Defaults to 2000 if not specified.
-E PEM
       Mark the specified PEM to leave reset in endpoint mode.
       The PEM parameter must be the numeric PEM instance
       number.   This argument may be specified more than once
       to select multiple PEMs.
EOF
}

INST=1
MMC_BOOT=false
spi_boot_source=false
RUN_ASIM=false
USE_DSP=0
DUAL=false
SDUAL=false
EP_SELECT=0

append_env() {
	echo "export $1=$2" >> $SHARE_DIR/asimconf.conf
}

# check_mmc_source <error|warning>
# Validates that an MMC image is available either via --mmc (MMC_SOURCE) or
# via -e "MMC_IMAGE <path>" (USER_ENV).  Callers where MMC is the primary
# boot device pass "error" (script exits on failure); callers where MMC is
# only the secondary device pass "warning" (script continues).
check_mmc_source() {
    if [ -z "$MMC_SOURCE" ] && [[ "$USER_ENV" != *MMC_IMAGE* ]]; then
        if [ "$1" = "error" ]; then
            echo "Error: Missing --mmc option, will fail to boot"
            exit
        else
            echo "Warning: Missing --mmc option, some operations will not work"
        fi
    fi
}

while true ; do
    case "$1" in
    -a)
	shift
	ASIM_LIBRARY_PATH="$1/lib"
	ASIM_MANUAL_PATH="$1/man"
	ASIM="$1"
	ASIM_EXEC="$1/bin/asim"
	shift
	;;
    -s)
	shift
	SHARE_DIR="$1"
	shift
	;;
    -h|--help)
	print_help
	exit
	;;
    -i|--instance)
	shift
	INST="$1"
	shift
	case $INST in
	    1|2|3|4|5|6|7|8)
		;;
	    *)
		echo "incorrect value for instance number: \"$INST\""
		exit
		;;
	esac
	;;
    -f)
	shift
	SOURCE="$1"
	spi_boot_source=true
	shift
	#case $SOURCE in
		#spi0cs0|spi0cs1|spi1cs0|spi1cs1)
		#;;
		#*)
		#echo "illegal boot source: \"$SOURCE\" allowed sources: spi0cs0, sspi0cs1, spi1cs0, spi1cs1"
		#exit
		#;;
	#esac
	;;
   -m)
	shift
	if [ "$spi_boot_source" == "true" ]; then
		echo "incorrect boot source: do not use SPI_BOOT_SOURCE and mmc together, chooose only one of them"
		exit
	fi
	MMC_BOOT=true
	;;
    -u)
       shift
       UART0_BASE="$1"
       shift
       ;;
    -b)
	shift
	BPHYCNT="$1"
	shift
	;;
    -v)
	shift
	BPHYTYPE="$1"
	shift
	;;
    --spi)
	shift
	SPI_SOURCE="$1"
	shift
	;;
    --spi1)
	shift
	SPI1_SOURCE="$1"
	shift
	;;
    --mmc)
	shift
	MMC_SOURCE="$1"
	shift
	;;
    --dual)
	shift
	DUAL=true
	;;
    --sdual)
	shift
	SDUAL=true
	;;
    --usb)
	shift
	USB_SOURCE="$1"
	shift
	;;
    --rom)
	shift
	ROM_SOURCE="$1"
	shift
	;;
    -r)
	shift
	RUN_ASIM=true
	;;
    --use-dsp)
        shift
	USE_DSP=1
	;;
    -e)
	shift
	USER_ENV="$1"
	shift
	;;
    -E)
	shift
	EPNUM="${1}"
	EP_SELECT=$(( EP_SELECT | (1 << EPNUM) ))
	shift
        ;;
    -*)
	echo "unknown option: \"$1\""
	exit
	;;
    *)
	break
	;;
   esac
done

PLAT=$1

# Automatically apply ROM source to CN20K
if [ -z ${ROM_SOURCE} ]; then
    case ${PLAT} in
	cn20ka|cn20kas|cn20kb|cnf20ka)
	    ROM_SOURCE=${ASIM}/marvell/octeon/o20x/bootrom/scp_bl0_cn20k.bin
	    ;;
	*)
	    ;;
    esac
fi

((INST--))

mkdir -p ${SHARE_DIR}
rm -f "$SHARE_DIR/asimconf.conf"

[[ ! -z "$USER_ENV" ]] && append_env $USER_ENV

if [[ $# -ne 1 ]] ; then
    echo "provide platform name"
    exit
fi

COUNT=16
MP_VARIANT=1
RF_VARIANT=0

case "${PLAT}" in
   cnf20ka)
       if [ -z "$BPHYCNT" ] ; then
           BPHYCNT=2
       fi

       if [ -v BPHYTYPE ] ; then
	       case "${BPHYTYPE}" in
		       0)
			  MP_VARIANT=1
			  RF_VARIANT=0
			  ;;
		       1)
			  MP_VARIANT=0
			  RF_VARIANT=1
			  ;;
		esac
	fi
	   ;;
   *)
       if [ -z "$BPHYCNT" ] ; then
           BPHYCNT=0
       fi
	   ;;
esac

append_env ASIM_BPHYCOUNT  $BPHYCNT
append_env BPHY_TYPE_MP $MP_VARIANT
append_env BPHY_TYPE_RF $RF_VARIANT

case "${PLAT}" in
    cn20ka)
	ASIM_CHIP=cn20ka
	append_env ASIM_ALT_CFG cn20ka-base.asim
	COUNT=64
	;;
    cn20kas)
	ASIM_CHIP=cn20ka
	append_env ASIM_ALT_CFG cn20kas-base.asim
	COUNT=64
	;;
    cnf20ka)
	ASIM_CHIP=cnf20ka
	if [ "$BPHYCNT" -eq 1 ] ; then
	   if [ "$RF_VARIANT" == 1 ] ; then
	      append_env ASIM_ALT_CFG cnf20ka-rf-half.asim
	  else
	      append_env ASIM_ALT_CFG cnf20ka-mp-half.asim
	  fi
        elif [ "$BPHYCNT" -eq 2 ] ; then
	  if [ "$MP_VARIANT" == 1 ] ; then
	      append_env ASIM_ALT_CFG cnf20ka-mp-full.asim
	  else
	      append_env ASIM_ALT_CFG cnf20ka-rf-full.asim
	  fi
	fi
	append_env ASIM_BPHY_LOAD_DSPS $USE_DSP
	COUNT=64
	;;
    cn10ka)
	ASIM_CHIP=cn10ka
	append_env ASIM_ALT_CFG cn10ka-base.asim
	COUNT=32
	;;
    cn10kas)
	ASIM_CHIP=cn10ka
	append_env ASIM_ALT_CFG cn10kas-base.asim
	COUNT=32
	;;
    cn10kb)
	ASIM_CHIP=cn10kb
	append_env ASIM_ALT_CFG cn10kb-base.asim
	COUNT=32
	;;
    cnf10ka)
	ASIM_CHIP=cnf10ka
	append_env ASIM_ALT_CFG cnf10ka-base.asim
	append_env ASIM_INCLUDE_DSP_MODELS $USE_DSP
	COUNT=32
	;;
    cnf10kb)
	ASIM_CHIP=cnf10kb
	append_env ASIM_ALT_CFG cnf10kb-base.asim
	append_env ASIM_INCLUDE_DSP_MODELS $USE_DSP
	;;
    t96)
	ASIM_CHIP=cn96xx
	;;
    f95)
	ASIM_CHIP=cnf95xx
	append_env ASIM_95XX_CFG cnf95xx-1s6p.asim
	;;
    t98)
	ASIM_CHIP=cn98xx
	;;
    loki)
	ASIM_CHIP=loki
	append_env ASIM_95XX_CFG loki-1s6p.asim
	;;
    *)
	echo "platform \"$PLAT\" is not supported for now"
	exit
	;;
esac

case "${PLAT}" in
    t96|f95|t98)
	SPI_STRAP=0x100a
	MMC_STRAP=0x0008
	;;
    loki)
	    case "${SOURCE}" in
	        spi0cs0)
		    SPI_STRAP=0x0002
		    ;;
		spi0cs1)
		    SPI_STRAP=0x0003
		    ;;
		spi1cs0)
		    SPI_STRAP=0x0004
		    ;;
		spi1cs1)
		    SPI_STRAP=0x0005
		    ;;
                *)
	            SPI_STRAP=0x100a
	            MMC_STRAP=0x0008
		    ;;
            esac
	    ;;
    cn10ka|cn10kas|cnf10ka|cnf10kb|cn10kb)
	     # P:spi0cs0 S:spi0cs1
	     case "${SOURCE}" in
	        s0cs0s0cs1)
		    SPI_STRAP=0x100a
		    ;;
		# P:spi0cs1 S:spi0cs0
		s0cs1s0cs0)
		    SPI_STRAP=0x1013
		    ;;
		# P:spi0cs0 S:spi1cs0
		s0cs0s1cs0)
		    SPI_STRAP=0x2002
		    ;;
		# P:spi1cs0 S:spi0cs0
		s1cs0s0cs0)
		    SPI_STRAP=0x1004
		    ;;
		# P:spi0cs0 S:mmc
		s0cs0mmc)
		    SPI_STRAP=0x2
		    check_mmc_source warning
		    ;;
		# P:spi1cs0 S:mmc
		s1cs0mmc)
		    SPI_STRAP=0x4
		    check_mmc_source warning
		    ;;
		# P:mmc S:spi0cs0
		mmcs0cs0)
		    check_mmc_source error
		    SPI_STRAP=0x1000
		    ;;
		# P:mmc S:spi1cs0
		mmcs1cs0)
		    check_mmc_source error
		    SPI_STRAP=0x2000
		    ;;
		*)
	            SPI_STRAP=0x100a
	            ;;
	     esac
	     ;;
    cn20ka|cn20kas|cnf20ka)
	     # CN20K uses GPIOs 0-3 and 12, 13, 17, and 18 for boot methods
	     # 0: EMMC CS0
	     # 1: I3C Master 0
	     # 2: S0CS0
	     # 3: S0CS1
	     # 4: S1CS0
	     # 5: S1CS1
	     # 6: Dual
	     # 7: Remote
	     # 8: I3C Master 1
	     # 9: UART

	     case "${SOURCE}" in
	        s0cs0s0cs1)
		# P:spi0cs0 S:spi0cs1
		    SPI_STRAP=0x3002
		    ;;
		# P:spi0cs1 S:spi0cs0
		s0cs1s0cs0)
		    SPI_STRAP=0x2003
		    ;;
		# P:spi0cs0 S:spi1cs0
		s0cs0s1cs0)
		    SPI_STRAP=0x20002
		    ;;
		# P:spi0cs0 S:spi1cs1
		s0cs0s1cs1)
		    SPI_STRAP=0x21002
		    ;;
		# P:spi1cs0 S:spi0cs0
		s1cs0s0cs0)
		    SPI_STRAP=0x2004
		    ;;
		# P:spi1cs0 S:spi0cs1
		s1cs0s0cs1)
		    SPI_STRAP=0x3004
		    ;;
		# P:spi1cs0 S:spi1cs1
		s1cs0s1cs1)
		    SPI_STRAP=0x21004
		    ;;
		# P:spi0cs0 S:mmc
		s0cs0mmc)
		    SPI_STRAP=0x2
		    check_mmc_source warning
		    ;;
		# P:spi0cs1 S:mmc
		s0cs1mmc)
		    SPI_STRAP=0x3
		    check_mmc_source warning
		    ;;
		# P:spi1cs0 S:mmc
		s1cs0mmc)
		    SPI_STRAP=0x4
		    check_mmc_source warning
		    ;;
		# P:spi1cs1 S:mmc
		s1cs1mmc)
		    SPI_STRAP=0x5
		    check_mmc_source warning
		    ;;
		# P:mmc S:spi0cs0
		mmcs0cs0)
		    check_mmc_source error
		    SPI_STRAP=0x2000
		    ;;
		# P:mmc S:spi0cs1
		mmcs0cs1)
		    check_mmc_source error
		    SPI_STRAP=0x3000
		    ;;
		# P:mmc S:spi1cs0
		mmcs1cs0)
		    check_mmc_source error
		    SPI_STRAP=0x20000
		    ;;
		# P:mmc S:spi1cs1
		mmcs1cs1)
		    check_mmc_source error
		    SPI_STRAP=0x21000
		    ;;
		# P:mmc S:dual
		mmcdual)
		    check_mmc_source error
		    SPI_STRAP=0x22000
		    ;;
		# P: spi0cs0 S: dual
		s0cs0dual)
		    SPI_STRAP=0x22002
		    ;;
		# P: spi0cs1 S: dual
		s0cs1dual)
		    SPI_STRAP=0x22003
		    ;;
		# P: spi1cs0 S: dual
		s1cs0dual)
		    SPI_STRAP=0x22004
		    ;;
		# P: spi1cs1 S: dual
		s1cs1dual)
		    SPI_STRAP=0x22005
		    ;;
		# P: dual S: mmc
		dualmmc)
		    check_mmc_source error
		    SPI_STRAP=0x0006
		    ;;
		# P: dual S: spi0cs0
		duals0cs0)
		    SPI_STRAP=0x2006
		    ;;
		# P: dual S: spi0cs1
		duals0cs1)
		    SPI_STRAP=0x3006
		    ;;
		# P: dual S: spi1cs0
		duals1cs0)
		    SPI_STRAP=0x20006
		    ;;
		# P: dual S: spi1cs1
		duals1cs1)
		    SPI_STRAP=0x21006
		    ;;
		# s0cs0 dual or sdual
		s0cs0)
		    if [ "${DUAL}" = true ]; then
			SPI_STRAP=0x2006
		    elif [ "${SDUAL}" = true ]; then
			SPI_STRAP=0x22002
		    else
			echo "S0CS0"
			SPI_STRAP=0x2002
		    fi
		    ;;
		# s0cs1 dual or sdual
		s0cs1)
		    if [ "${DUAL}" = true ]; then
			SPI_STRAP=0x3006
		    elif [ "${SDUAL}" = true ]; then
			SPI_STRAP=0x22003
		    else
			SPI_STRAP=0x3003
		    fi
		    ;;
		# s1cs0 dual or sdual
		s1cs0)
		    if [ "${DUAL}" = true ]; then
			SPI_STRAP=0x20006
		    elif [ "${SDUAL}" = true ]; then
			SPI_STRAP=0x22004
		    else
			SPI_STRAP=0x20004
		    fi
		    ;;
		# s1cs1 dual or sdual
		s1cs1)
		    if [ "${DUAL}" = true ]; then
			SPI_STRAP=0x21006
		    elif [ "${SDUAL}" = true ]; then
			SPI_STRAP=0x22005
		    else
			SPI_STRAP=0x21005
		    fi
		    ;;
		# mmc dual or sdual
		mmc)
		    SPI_STRAP=0x0000
		    [[ "${DUAL}" = true ]] && SPI_STRAP=0x0006
		    [[ "${SDUAL}" = true ]] && SPI_STRAP=0x22000
		    ;;
		# P: i3cX/UART/remote not yet implemented
		*)
	            SPI_STRAP=0x3002
	            ;;
             esac
		# cn20k supports dual endpoint with PEM0 and either PEM1 or PEM3.
	     case "$EP_SELECT" in
	     1)
		   EP_STRAPS=$(( EP_STRAPS | (1 << 15) ))
		   ;;
	     2)
		   EP_STRAPS=$(( EP_STRAPS | (1 << 7) ))
		   ;;
	     8)
		   EP_STRAPS=$(( EP_STRAPS | (1 << 16) ))
		   ;;
	     3)
		   EP_STRAPS=$(( EP_STRAPS | (1 << 15) | (1 << 7) ))
		   ;;
	     9)
		   EP_STRAPS=$(( EP_STRAPS | (1 << 15) | (1 << 16) ))
		   ;;
	     *)
		   EP_STRAPS=0
		   ;;
	     esac
	     ;;
    *)
	MMC_STRAP=0x3
	SPI_STRAP=0x5
	;;
esac

#echo SPI STRAP: ${SPI_STRAP}

if [ "$MMC_BOOT" = true ] ; then
	append_env BOOT_STRAP "$((MMC_STRAP | EP_STRAPS))"
else
	append_env BOOT_STRAP "$((SPI_STRAP | EP_STRAPS))"
fi

if [ "$RUN_ASIM" = false ] ; then
  dd if=/dev/zero ibs=1M count=$COUNT | tr "\000" "\377" > $SHARE_DIR/spi.img
  dd if=$SPI_SOURCE of=$SHARE_DIR/spi.img conv=notrunc
  if [ ! -z "$USB_SOURCE" ] ; then
      cp $USB_SOURCE $SHARE_DIR/usb.img
      truncate -s 5g $SHARE_DIR/usb.img
  fi
  if [ ! -z "$MMC_SOURCE" ] ; then
      cp $MMC_SOURCE $SHARE_DIR/mmc.img
      truncate -s 5g $SHARE_DIR/mmc.img
  fi
fi

append_env ASIM              "$ASIM"
append_env ASIM_LIBRARY_PATH "$ASIM_LIBRARY_PATH"
append_env ASIM_MANUAL_PATH  "$ASIM_MANUAL_PATH"
append_env SPI_IMAGE         "$SHARE_DIR/spi.img"

if [ "$SPI1_SOURCE" ] ; then
    dd if=/dev/zero ibs=1M count=$COUNT | tr "\000" "\377" > $SHARE_DIR/spi1.img
    if [ "$RUN_ASIM" = false ] ; then
        dd if=$SPI1_SOURCE of=$SHARE_DIR/spi1.img conv=notrunc
    fi
    append_env SPI1_IMAGE        "$SHARE_DIR/spi1.img"
else
    append_env SPI1_IMAGE        "$SHARE_DIR/spi.img"
fi

if [ "$BPHYCNT" ] ; then
    if [ "$RUN_ASIM" = false ] ; then
        dd if=/dev/zero ibs=1M count=$COUNT | tr "\000" "\377" > $SHARE_DIR/spi2.img
    fi
  append_env SPI2_IMAGE        "$SHARE_DIR/spi2.img"
fi

if [ "$BPHYCNT" -eq 2 ] ; then
    if [ "$RUN_ASIM" = false ] ; then
        dd if=/dev/zero ibs=1M count=$COUNT | tr "\000" "\377" > $SHARE_DIR/spi3.img
    fi
  append_env SPI3_IMAGE        "$SHARE_DIR/spi3.img"
fi

if [ ! -z "$MMC_SOURCE" ] ; then
    append_env MMC_IMAGE         "$SHARE_DIR/mmc.img"
fi

if [ ! -z "$USB_SOURCE" ] ; then
    append_env USB_IMAGE         "$SHARE_DIR/usb.img"
fi

append_env ROM_IMAGE         "$ROM_SOURCE"
append_env ASIM_DIMM_SIZE    "4"
append_env ASIM_DIMM_PER_LMC "1"

start=0
UART_N=2
# NET_N -- number of network interfaces
case "${PLAT}" in
    f95|loki|f95mm|f95mm-dsp)
	NET_N=4
	;;
    cn10kas)
	NET_N=4
	start=3
	append_env "NIC0" "$(($INST * $NET_N + 55555))"  # from asim config file
	append_env "NIC1" "$(($INST * $NET_N + 55556))"  # from asim config file
	append_env "NIC2" "$(($INST * $NET_N + 55557))"  # from asim config file

	SWITCH_NET_N=16
	for i in `seq 0 $((SWITCH_NET_N - 1))` ; do
	    append_env "ASIM_SWITCH_TAP$i" "wmcable$(($INST * $SWITCH_NET_N + $i))"
	done
	UART_N=8
	;;
    t96)
	NET_N=12
	;;
    cn10ka)
	NET_N=12
	UART_N=8
	;;
    t98)
	NET_N=20
	;;
    cnf10ka)
	NET_N=16
	;;
    cnf10kb)
	NET_N=20
	UART_N=4
	;;
    cn10kb)
	NET_N=20
	UART_N=4
	;;
    cn20kas)
	NET_N=20
	start=0
	# rpm2
	append_env "NIC16" "$(($INST * $NET_N + 55555))"  # from asim config file
	append_env "NIC17" "$(($INST * $NET_N + 55556))"  # from asim config file
	append_env "NIC18" "$(($INST * $NET_N + 55557))"  # from asim config file
	append_env "NIC19" "$(($INST * $NET_N + 55558))"  # from asim config file
	# rpm0
	append_env "NIC0"  "$(($INST * $NET_N + 66660))"  # from asim config file
	append_env "NIC1"  "$(($INST * $NET_N + 66661))"  # from asim config file
	append_env "NIC2"  "$(($INST * $NET_N + 66662))"  # from asim config file
	append_env "NIC3"  "$(($INST * $NET_N + 66663))"  # from asim config file
	append_env "NIC4"  "$(($INST * $NET_N + 66664))"  # from asim config file
	append_env "NIC5"  "$(($INST * $NET_N + 66665))"  # from asim config file
	append_env "NIC6"  "$(($INST * $NET_N + 66666))"  # from asim config file
	append_env "NIC7"  "$(($INST * $NET_N + 66667))"  # from asim config file
	# rpm1
	append_env "NIC8"  "$(($INST * $NET_N + 66668))"  # from asim config file
	append_env "NIC9"  "$(($INST * $NET_N + 66669))"  # from asim config file
	append_env "NIC10" "$(($INST * $NET_N + 66670))"  # from asim config file
	append_env "NIC11" "$(($INST * $NET_N + 66671))"  # from asim config file
	append_env "NIC12" "$(($INST * $NET_N + 66672))"  # from asim config file
	append_env "NIC13" "$(($INST * $NET_N + 66673))"  # from asim config file
	append_env "NIC14" "$(($INST * $NET_N + 66674))"  # from asim config file
	append_env "NIC15" "$(($INST * $NET_N + 66675))"  # from asim config file
	SWITCH_NET_N=16
	for i in `seq 0 $((SWITCH_NET_N - 1))` ; do
	    append_env "ASIM_SWITCH_TAP$i" "wmcable$(($INST * $SWITCH_NET_N + $i))"
	done
	UART_N=16
	# Total memory to configure in simulation platform
	append_env ASIM_DIMM_SIZE    "24"
	;;
    cn20ka)
	UART_N=16
	NET_N=20
	# Total memory to configure in simulation platform
	append_env ASIM_DIMM_SIZE    "24"
	;;
    cnf20ka)
	UART_N=16
	NET_N=4
	if [ "$BPHYCNT" -ge 1 ] ; then
		((NET_N+=8))
		if [ "$MP_VARIANT" -ge 1 ] & [ "$BPHYCNT" -eq 1 ] ; then
			((NET_N+=4))
		fi
	fi

	if [ "$BPHYCNT" -eq 2 ] ; then
		((NET_N+=8))
	fi


	# Total memory to configure in simulation platform
	append_env ASIM_DIMM_SIZE    "64"
	;;
    *)
	NET_N=0
	;;
esac

for i in `seq ${start} $((NET_N - 1))` ; do
    append_env "NIC$i" "asimnic$(($INST * $NET_N + $i))"
done

for i in `seq 0 $((UART_N - 1))` ; do
    append_env "UART${i}PORT" "$((UART0_BASE + $INST * UART_N + $i))"
done

append_env ASIM_SHARE_DIR "$SHARE_DIR"

chmod 777 $SHARE_DIR/asimconf.conf
source $SHARE_DIR/asimconf.conf
"$ASIM_EXEC" -e "$SCRIPT_DIR/configs/$ASIM_CHIP.asim"
