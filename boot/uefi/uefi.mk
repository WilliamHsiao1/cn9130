################################################################################
#
# uefi
#
################################################################################

# Select source
ifeq ($(BR2_TARGET_UEFI_GIT),y)
UEFI_SITE = https://github.com/Marvell-Lab/octeon-uefi.git
UEFI_VERSION = uefi-2.9-devel
UEFI_SITE_METHOD = git
UEFI_GIT_SUBMODULES = YES
else
UEFI_VERSION = $(call qstrip,$(BR2_MARVELL_RELEASE_ID))
UEFI_SITE = $(TOPDIR)/../base-sources-$(UEFI_VERSION)/uefi
UEFI_SITE_METHOD = file
UEFI_SOURCE = sources-uefi-$(UEFI_VERSION).tar.bz2
endif

UEFI_INSTALL_IMAGES = YES

UEFI_DEPENDENCIES = host-acpica

UEFI_PLATFORM=$(call qstrip,$(BR2_TARGET_UEFI_PLATFORM))
UEFI_MAKE_OPTS = PLAT=$(UEFI_PLATFORM)

#WA: Toolchain installation for RELEASE/Tarball is full whilst DEVEL/GIT
# is "partial". This "partial" causes for UEFI compilation failure.
# Let's use shell-env 'export CROSS_COMPILE' for DEVEL/GIT build.
#
ifeq ($(BR2_TARGET_UEFI_GIT),y)
ifeq ($(CROSS_COMPILE),)
$(error export-env CROSS_COMPILE must be defined)
endif
UEFI_MAKE_OPTS += CROSS_COMPILE=$(CROSS_COMPILE)
else
UEFI_MAKE_OPTS += CROSS_COMPILE=$(BR2_TOOLCHAIN_EXTERNAL_CUSTOM_CROSS_COMPILE)
endif

ifeq ($(BR2_TARGET_UEFI_DEBUG),y)
UEFI_MAKE_OPTS += DEBUG=1
endif

# NOTE: No time-difference seen between MAKE(make -jN) and MAKE1(make -j1)
# The original build has used MAKE1, let's keep it
define UEFI_BUILD_CMDS
	$(MAKE1) $(UEFI_MAKE_OPTS) -C $(@D)
endef

# OcteonTX makes flash-image by Marvell-BDK
# ARMADAs have no Marvell-BDK and make flash image to be here
#
ifeq ($(BR2_TARGET_MARVELL_BDK),y)
UEFI_IMAGE=$(shell readlink -f $(@D)/octeontx_efi-$(UEFI_PLATFORM).fd)
define UEFI_INSTALL_IMAGES_CMDS
	cp -f $(UEFI_IMAGE) $(BINARIES_DIR)/octeontx_efi-$(UEFI_PLATFORM).fd
	ln -fs octeontx_efi-$(UEFI_PLATFORM).fd $(BINARIES_DIR)/octeontx_efi.fd
endef
else
UEFI_IMAGE=$(shell readlink -f $(@D)/armada_efi-$(UEFI_PLATFORM).fd)
define UEFI_INSTALL_IMAGES_CMDS
	cp -f $(UEFI_IMAGE) $(BINARIES_DIR)/armada_efi-$(UEFI_PLATFORM).fd
	ln -fs armada_efi-$(UEFI_PLATFORM).fd $(BINARIES_DIR)/armada_efi.fd
endef
endif #BR2_TARGET_MARVELL_BDK

$(eval $(generic-package))
