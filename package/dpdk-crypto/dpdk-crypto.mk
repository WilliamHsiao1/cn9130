################################################################################
#
# dpdk-crypto
#
################################################################################
DPDK_CRYPTO_VERSION = a38967c975496a29136f908bd46855d7d355bb8a

DPDK_CRYPTO_SITE = https://github.com/ARM-software/AArch64cryptolib/archive
DPDK_CRYPTO_SOURCE = $(DPDK_CRYPTO_VERSION).tar.gz

DPDK_CRYPTO_INSTALL_STAGING = YES

define DPDK_CRYPTO_BUILD_CMDS
	$(TARGET_MAKE_ENV) CROSS_COMPILE=$(TARGET_CROSS) $(MAKE1) -C $(@D) CC=$(TARGET_CC)
endef

define DPDK_CRYPTO_INSTALL_TARGET_CMDS
endef

define DPDK_CRYPTO_INSTALL_STAGING_CMDS
	mkdir -p $(STAGING_DIR)/usr/lib/pkgconfig/
	$(INSTALL) -D -m 0755 $(@D)/pkgconfig/libAArch64crypto.pc $(STAGING_DIR)/usr/lib/pkgconfig/
	$(INSTALL) -D -m 0755 $(@D)/libAArch64crypto.a $(STAGING_DIR)/usr/lib/
	$(INSTALL) -D -m 0755 $(@D)/AArch64cryptolib.h $(STAGING_DIR)/usr/include/
endef

$(eval $(generic-package))

