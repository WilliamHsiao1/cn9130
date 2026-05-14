################################################################################
#
# cavium-ipfwd-offload
#
################################################################################

# For now, use SDK GIT with this package.
# TODO: use dedicated GIT for the package
ifeq ($(BR2_PACKAGE_CAVIUM_IPFWD_OFFLOAD_GIT),y)
CAVIUM_IPFWD_OFFLOAD_SITE = https://github.com/Marvell-Lab/octeon-sdk.git
CAVIUM_IPFWD_OFFLOAD_VERSION = sdk-devel
CAVIUM_IPFWD_OFFLOAD_SITE_METHOD = git
else
CAVIUM_IPFWD_OFFLOAD_VERSION = $(call qstrip,$(BR2_MARVELL_RELEASE_ID))
CAVIUM_IPFWD_OFFLOAD_SITE = $(TOPDIR)/../base-sources-$(CAVIUM_IPFWD_OFFLOAD_VERSION)/sdk
CAVIUM_IPFWD_OFFLOAD_SITE_METHOD = file
CAVIUM_IPFWD_OFFLOAD_SOURCE = sources-sdk-$(CAVIUM_IPFWD_OFFLOAD_VERSION).tar.bz2
endif

CAVIUM_IPFWD_OFFLOAD_DEPENDENCIES = linux
CAVIUM_IPFWD_OFFLOAD_FOLDER = linux/cavium-rootfs/source/cavium-ipfwd-offload/src
CAVIUM_IPFWD_OFFLOAD_MODULE_MAKE_OPTS = CAVIUM_PLATFORM=octeontx KDIR=$(LINUX_DIR) MODULE_TOPDIR=$(@D)/$(CAVIUM_IPFWD_OFFLOAD_FOLDER)

$(eval $(kernel-module))
$(eval $(generic-package))
