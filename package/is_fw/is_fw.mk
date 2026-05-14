################################################################################
#
# is_fw
#
################################################################################

IS_FW_VERSION = $(call qstrip,$(BR2_PACKAGE_IS_FW_VERSION))

ifeq ($(BR2_PACKAGE_IS_FW_CUSTOM_GIT),y)
IS_FW_SITE = $(call qstrip,$(BR2_PACKAGE_IS_FW_CUSTOM_REPO_URL))
IS_FW_SITE_METHOD = git
else
ifeq ($(BR2_PACKAGE_IS_FW_CUSTOM_TARBALL),y)
IS_FW_TARBALL = $(call qstrip,$(BR2_PACKAGE_IS_FW_CUSTOM_TARBALL_LOCATION))
IS_FW_SITE = $(patsubst %/,%,$(dir $(IS_FW_TARBALL)))
IS_FW_SOURCE = $(notdir $(IS_FW_TARBALL))
IS_FW_SITE_METHOD = file
else
ifeq ($(BR2_PACKAGE_IS_FW_GIT),y)
IS_FW_SITE = https://github.com/Marvell-Lab/armada-isfw.git
IS_FW_SITE_METHOD = git
else
IS_FW_SITE = $(TOPDIR)/../base-sources-$(IS_FW_VERSION)/is_fw
IS_FW_SITE_METHOD = file
IS_FW_SOURCE = sources-is_fw-$(IS_FW_VERSION).tar.bz2
endif
endif
endif

BR_NO_CHECK_HASH_FOR += $(IS_FW_SOURCE)

IS_FW_INSTALL_STAGING = NO

define IS_FW_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/inside-secure/eip197b/ifpp.bin $(TARGET_DIR)/lib/firmware/inside-secure/eip197b/ifpp.bin
	$(INSTALL) -D -m 0644 $(@D)/inside-secure/eip197b/ipue.bin $(TARGET_DIR)/lib/firmware/inside-secure/eip197b/ipue.bin
endef

$(eval $(generic-package))
