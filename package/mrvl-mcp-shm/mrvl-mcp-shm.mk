################################################################################
#
# mrvl-mcp-shm
#
################################################################################

MRVL_MCP_SHM_VERSION = $(call qstrip,$(BR2_PACKAGE_MRVL_MCP_SHM_VERSION))

ifeq ($(BR2_PACKAGE_MRVL_MCP_SHM_GIT),y)
MRVL_MCP_SHM_SITE = https://github.com/Marvell-Lab/cpc-mcp-shm.git
MRVL_MCP_SHM_SITE_METHOD = git
else
MRVL_MCP_SHM_SITE = $(TOPDIR)/../base-sources-$(MRVL_MCP_SHM_VERSION)/mrvl-mcp-shm
MRVL_MCP_SHM_SOURCE = sources-mrvl-mcp-shm-$(MRVL_MCP_SHM_VERSION).tar.bz2
MRVL_MCP_SHM_SITE_METHOD = file
endif


MRVL_MCP_SHM_DEPENDENCIES += libnl liboping inih
MRVL_MCP_SHM_CFLAGS = -I$(STAGING_DIR)/usr/include/libnl3 -DCONFIG_LIBNL32 -Wall

MRVL_MCP_SHM_MODULE_SUBDIRS = kmod
MRVL_MCP_SHM_MODULE_MAKE_OPTS = LINUX_DIR="$(LINUX_DIR)"

define MRVL_MCP_SHM_BUILD_CMDS
	$(MAKE) -C $(@D)/utils $(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS) $(MRVL_MCP_SHM_CFLAGS)" all
endef

define MRVL_MCP_SHM_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/kmod/shm-channel.ko $(TARGET_DIR)/lib/modules/$(LINUX_VERSION_PROBED)/kernel/drivers/shm/shm-channel.ko
	$(INSTALL) -D -m 0755 $(@D)/utils/channel-util $(TARGET_DIR)/usr/bin
	$(INSTALL) -D -m 0755 $(@D)/utils/cb-channeld $(TARGET_DIR)/usr/bin
	$(INSTALL) -D -m 0755 $(@D)/utils/ras_collectd $(TARGET_DIR)/usr/bin
        mkdir -p $(TARGET_DIR)/etc/init.d
	$(INSTALL) -D -m 0755 $(@D)/utils/S98linux-load $(TARGET_DIR)/etc/init.d
	$(INSTALL) -D -m 0755 $(@D)/utils/system_monitord $(TARGET_DIR)/usr/bin
	mkdir -p $(TARGET_DIR)/usr/share/system_monitord
	$(INSTALL) -D -m 0755 $(@D)/conf/system_monitord.ini $(TARGET_DIR)/usr/share/system_monitord/
endef

$(eval $(kernel-module))
$(eval $(generic-package))
