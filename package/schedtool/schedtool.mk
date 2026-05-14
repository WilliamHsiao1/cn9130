################################################################################
#
# schedtool
#
################################################################################

SCHEDTOOL_VERSION = schedtool-1.3.0
SCHEDTOOL_SITE = $(call github,freequaos,schedtool,$(SCHEDTOOL_VERSION))

define SCHEDTOOL_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) CC="$(TARGET_CC)"
endef

define SCHEDTOOL_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		DESTDIR=$(TARGET_DIR) DESTPREFIX=/usr install
endef

$(eval $(generic-package))
