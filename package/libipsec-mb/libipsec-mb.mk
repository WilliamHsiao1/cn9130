################################################################################
#
# Intel ipsec MB
#
################################################################################

LIBIPSEC_MB_VERSION=$(call qstrip,$(BR2_PACKAGE_LIBIPSEC_MB_VERSION))
LIBIPSEC_MB_SITE=https://gitlab.arm.com/arm-reference-solutions/ipsec-mb/-/archive/$(LIBIPSEC_MB_VERSION)
LIBIPSEC_MB_SOURCE=ipsec-mb-$(LIBIPSEC_MB_VERSION).tar.gz
LIBIPSEC_MB_DEPENDENCIES=host-nasm
LIBIPSEC_MB_INSTALL_STAGING=YES
LIBIPSEC_MB_INSTALL_TARGET=YES

define LIBIPSEC_MB_BUILD_CMDS
	SHARED=y CC=$(TARGET_CC) $(MAKE) -C $(@D)/lib AESNI_EMU=y ARCH=aarch64 PREFIX=$(STAGING_DIR)/usr NOLDCONFIG=y
endef

define LIBIPSEC_MB_INSTALL_TARGET_CMDS
	SHARED=y CC=$(TARGET_CC) $(MAKE) -C $(@D)/lib AESNI_EMU=y ARCH=aarch64 PREFIX=$(TARGET_DIR)/usr install STRIP=$(TARGET_STRIP) NOLDCONFIG=y
endef

define LIBIPSEC_MB_INSTALL_STAGING_CMDS
	SHARED=y CC=$(TARGET_CC) $(MAKE) -C $(@D)/lib AESNI_EMU=y ARCH=aarch64 PREFIX=$(STAGING_DIR)/usr install STRIP=$(TARGET_STRIP) NOLDCONFIG=y
endef

define LIBIPSEC_MB_COPY_BINARIES
	cp $(@D)/lib/libIPSec_MB.* $(TARGET_DIR)/lib/
endef

LIBIPSEC_MB_POST_INSTALL_TARGET_HOOKS += LIBIPSEC_MB_COPY_BINARIES

$(eval $(generic-package))
