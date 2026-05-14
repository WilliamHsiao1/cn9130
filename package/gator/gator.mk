################################################################################
#
# gator
#
################################################################################

GATOR_VERSION = $(call qstrip,$(BR2_PACKAGE_GATOR_VERSION))

ifeq ($(BR2_PACKAGE_GATOR_GIT),y)
GATOR_SITE = https://github.com/ARM-software/gator.git
GATOR_SITE_METHOD = git
endif

BR_NO_CHECK_HASH_FOR += $(GATOR_SOURCE)

GATOR_INSTALL_STAGING = YES

define GATOR_BUILD_CMDS
	$(Q)cd $(@D/daemon)
	$(TARGET_MAKE_ENV) CROSS_COMPILE=$(TARGET_CROSS) $(MAKE)  -C $(@D)/daemon
endef

define GATOR_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/daemon/gatord $(TARGET_DIR)/usr/bin/gatord
endef

$(eval $(generic-package))
