################################################################################
#
# Asimcp package, copy files from host to asim guest
#
################################################################################

ASIMCP_VERSION = v0.1.0
ASIMCP_SITE = $(TOPDIR)/../sdk-base/package/asimcp/source
ASIMCP_LICENSE = BSD-3-Clause, Marvell Commercial
ASIMCP_SITE_METHOD = local
ASIMCP_LICENSE_FILES = README
ASIMCP_INSTALL_STAGING = YES

define ASIMCP_BUILD_CMDS
       CROSS_COMPILE=$(TARGET_CROSS) $(MAKE)  -C $(@D) all
endef

define ASIMCP_INSTALL_STAGING_CMDS
       $(INSTALL) -D -m 0755 $(@D)/asimcp $(STAGING_DIR)/bin/asimcp
endef

define ASIMCP_INSTALL_TARGET_CMDS
       $(INSTALL) -D -m 0755 $(@D)/asimcp $(TARGET_DIR)/bin
endef

$(eval $(generic-package))
