################################################################################
#
# This file is MAKEFILE containing the list of PACKAGEs/TARGETs which have
# override-source-directory (for development purpose).
#
# $(MV_REPO_ROOT) tree:
#  Buildroot environment
#    distributions/buildroot/* (buildroot, sdk-base, sdk-ext-*)
#  Code-sources
#    kernel/linux*  (4.14, 4.18, 4.4)
#    boot/*         (atf, sdk, uboot, uefi,...)
#    dataplane/*    (dpdk, snap,...)
#
# MV_REPO_ROOT path is releative to the "buildroot" folder
#
MV_REPO_ROOT := ../../..

export BR2_OVERRIDE_SRCDIR_WITH_PATCHES=y

# LINUX_OVERRIDE_SRCDIR = $(MV_REPO_ROOT)/kernel/linux
# DPDK_OVERRIDE_SRCDIR = $(MV_REPO_ROOT)/dataplane/dpdk-19.08
# UEFI_OVERRIDE_SRCDIR = $(MV_REPO_ROOT)/boot/uefi
# UBOOT_OVERRIDE_SRCDIR = $(MV_REPO_ROOT)/boot/u-boot
# MARVELL_BDK_OVERRIDE_SRCDIR = $(MV_REPO_ROOT)/boot/bdk
# ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR = $(MV_REPO_ROOT)/boot/atf
