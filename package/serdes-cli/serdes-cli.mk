################################################################################
#
# serdes-cli
#
################################################################################

SERDES_CLI_VERSION = $(call qstrip,$(BR2_PACKAGE_SERDES_CLI_VERSION))

ifeq ($(BR2_PACKAGE_SERDES_CLI_GIT),y)
SERDES_CLI_SITE = https://github.com/Marvell-Lab/hsio-cli.git
SERDES_CLI_SITE_METHOD = git
else

ifeq ($(BR2_PACKAGE_SERDES_CLI_CN10K),y)
SERDES_CLI_SITE = $(TOPDIR)/../base-sources-$(SERDES_CLI_VERSION)/serdes-cli
SERDES_CLI_SOURCE = sources-serdes-cli-$(SERDES_CLI_VERSION).tar.bz2
#SERDES_CLI_NAME_BIN = serdes-cli-cn10k
endif #IF CN10k

ifeq ($(BR2_PACKAGE_SERDES_CLI_CN9K),y)
SERDES_CLI_SITE = $(TOPDIR)/../base-sources-$(SERDES_CLI_VERSION)/serdes-cli-cn9k
SERDES_CLI_SOURCE = sources-serdes-cli-cn9k-$(SERDES_CLI_VERSION).tar.bz2
#SERDES_CLI_NAME_BIN = serdes-cli
endif #IF CN9K

SERDES_CLI_SITE_METHOD = file
endif

BR_NO_CHECK_HASH_FOR += $(SERDES_CLI_SOURCE)

SERDES_CLI_INSTALL_STAGING = YES

define SERDES_CLI_BUILD_CMDS
	$(TARGET_MAKE_ENV) CROSS_COMPILE=$(TARGET_CROSS) $(MAKE) -C $(@D)
endef

define SERDES_CLI_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/$(call qstrip,$(SERDES_CLI_NAME_BIN)) $(TARGET_DIR)/usr/bin/$(call qstrip,$(SERDES_CLI_NAME_BIN))
endef

$(eval $(generic-package))
