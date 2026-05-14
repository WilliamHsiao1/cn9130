################################################################################
#
# cavium-xdp-ipfwd
#
################################################################################

# For now, use SDK GIT with this package.
# TODO: use dedicated GIT for the package
ifeq ($(BR2_PACKAGE_CAVIUM_XDP_IPFWD_GIT),y)
CAVIUM_XDP_IPFWD_SITE = https://github.com/Marvell-Lab/octeon-sdk.git
CAVIUM_XDP_IPFWD_VERSION = sdk-devel
CAVIUM_XDP_IPFWD_SITE_METHOD = git
else
CAVIUM_XDP_IPFWD_VERSION = $(call qstrip,$(BR2_MARVELL_RELEASE_ID))
CAVIUM_XDP_IPFWD_SITE = $(TOPDIR)/../base-sources-$(CAVIUM_XDP_IPFWD_VERSION)/sdk
CAVIUM_XDP_IPFWD_SITE_METHOD = file
CAVIUM_XDP_IPFWD_SOURCE = sources-sdk-$(CAVIUM_XDP_IPFWD_VERSION).tar.bz2
endif

CAVIUM_XDP_IPFWD_DEPENDENCIES = linux elfutils libzlib clang llvm
CAVIUM_XDP_IPFWD_FOLDER = linux/cavium-rootfs/source/cavium-xdp-ipfwd

define CAVIUM_XDP_IPFWD_APPEND_SRCS
	cp $(LINUX_DIR)/samples/bpf/bpf_helpers.h $(@D)/$(CAVIUM_XDP_IPFWD_FOLDER)
	cp $(LINUX_DIR)/samples/bpf/bpf_load.c $(@D)/$(CAVIUM_XDP_IPFWD_FOLDER)
	cp $(LINUX_DIR)/samples/bpf/libbpf.c $(@D)/$(CAVIUM_XDP_IPFWD_FOLDER)
endef
# This should be changed to CAVIUM_XDP_IPFWD_POST_EXTRACT_HOOKS
# when use tarball instead of source directory
CAVIUM_XDP_IPFWD_POST_RSYNC_HOOKS += CAVIUM_XDP_IPFWD_APPEND_SRCS

CAVIUM_XDP_IPFWD_MAKE_OPTIOINS = \
	ARCH=$(KERNEL_ARCH) \
	CROSS_COMPILE=$(TARGET_CROSS) \
	ZLIB_PATH=$(LIBZLIB_DIR) \
	LIBELF_PATH=$(ELFUTILS_DIR)/libelf \
	KERNEL_DIR=$(LINUX_DIR) \
	BUILD_DIR=$(@D)/$(CAVIUM_XDP_IPFWD_FOLDER) \
	CLANG=$(HOST_DIR)/bin/clang \
	LLC=$(HOST_DIR)/bin/llc


define CAVIUM_XDP_IPFWD_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(CAVIUM_XDP_IPFWD_MAKE_OPTIOINS) $(MAKE) -C $(@D)/$(CAVIUM_XDP_IPFWD_FOLDER)
endef

define CAVIUM_XDP_IPFWD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/$(CAVIUM_XDP_IPFWD_FOLDER)/cavium-xdp-ipfwd $(TARGET_DIR)/usr/bin/cavium-xdp-ipfwd
	$(INSTALL) -D -m 0644 $(@D)/$(CAVIUM_XDP_IPFWD_FOLDER)/xdp3_kern.o $(TARGET_DIR)/lib/firmware/bpf/xdp3_kern.o
endef

$(eval $(generic-package))
