################################################################################
#
# xmem
#
################################################################################

MEMUTILS_VERSION = $(call qstrip,$(BR2_PACKAGE_MEMUTILS_VERSION))

ifeq ($(BR2_PACKAGE_MEMUTILS_CUSTOM_GIT),y)
MEMUTILS_SITE = $(call qstrip,$(BR2_PACKAGE_MEMUTILS_CUSTOM_REPO_URL))
MEMUTILS_SITE_METHOD = git
MEMUTILS_GIT_SUBMODULES = YES
else ifeq ($(BR2_PACKAGE_MEMUTILS_CUSTOM_TARBALL),y)
MEMUTILS_SITE = $(patsubst %/,%,$(dir $(MEMUTILS_VERSION)))
MEMUTILS_SITE_METHOD = file
MEMUTILS_SOURCE = $(notdir $(MEMUTILS_VERSION))
else ifeq ($(BR2_PACKAGE_MEMUTILS_GIT),y)
MEMUTILS_SITE = https://github.com/Marvell-Lab/memutils.git
MEMUTILS_SITE_METHOD = git
MEMUTILS_GIT_SUBMODULES = YES
else
MEMUTILS_SITE = $(TOPDIR)/../base-sources-$(MEMUTILS_VERSION)/memutils
MEMUTILS_SITE_METHOD = file
MEMUTILS_SOURCE = sources-memutils-$(MEMUTILS_VERSION).tar.bz2
endif

BR_NO_CHECK_HASH_FOR += $(MEMUTILS_SOURCE)

MEMUTILS_LICENSE = BSD-3-Clause GPL-2.0
MEMUTILS_LICENSE_FILES = xmem/xmem.c.license pcimem/LICENSE.txt

define MEMUTILS_EXTRACT_LICENSE
	head -n 20 $(@D)/xmem/xmem.c >$(@D)/xmem/xmem.c.license
endef
MEMUTILS_PRE_PATCH_HOOKS += MEMUTILS_EXTRACT_LICENSE

define MEMUTILS_BUILD_CMDS
	$(TARGET_MAKE_ENV) CROSS_COMPILE=$(TARGET_CROSS) $(MAKE) -C $(@D)
endef

define MEMUTILS_INSTALL_TARGET_CMDS
	$(INSTALL) -D $(@D)/xmem/xmem $(TARGET_DIR)/sbin/xmem
	$(INSTALL) -D $(@D)/pcimem/pcimem $(TARGET_DIR)/sbin/pcimem
endef

$(eval $(generic-package))
