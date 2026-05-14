################################################################################
#
# txcsr
#
################################################################################

TXCSR_VERSION = $(call qstrip,$(BR2_PACKAGE_TXCSR_VERSION))

ifeq ($(BR2_PACKAGE_TXCSR_CUSTOM_GIT),y)
TXCSR_SITE = $(call qstrip,$(BR2_PACKAGE_TXCSR_CUSTOM_REPO_URL))
TXCSR_SITE_METHOD = git
else
ifeq ($(BR2_PACKAGE_TXCSR_CUSTOM_TARBALL),y)
TXCSR_TARBALL = $(call qstrip,$(BR2_PACKAGE_TXCSR_CUSTOM_TARBALL_LOCATION))
TXCSR_SITE = $(patsubst %/,%,$(dir $(TXCSR_TARBALL)))
TXCSR_SOURCE = $(notdir $(TXCSR_TARBALL))
TXCSR_SITE_METHOD = file
else
ifeq ($(BR2_PACKAGE_TXCSR_GIT),y)
TXCSR_SITE = https://github.com/Marvell-Lab/octeon-txcsr.git
TXCSR_SITE_METHOD = git
else
TXCSR_SITE = $(TOPDIR)/../base-sources-$(TXCSR_VERSION)/txcsr
TXCSR_SITE_METHOD = file
TXCSR_SOURCE = sources-txcsr-$(TXCSR_VERSION).tar.bz2
endif
endif
endif

BR_NO_CHECK_HASH_FOR += $(TXCSR_SOURCE)

define TXCSR_BUILD_CMDS
	$(TARGET_MAKE_ENV) CROSS_COMPILE=$(TARGET_CROSS) $(MAKE) -C $(@D)
endef

define TXCSR_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/txcsr $(TARGET_DIR)/usr/bin/txcsr
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/share/txcsr
	$(INSTALL) -D -m 0644 $(@D)/ebf/csr.db $(TARGET_DIR)/usr/share/txcsr/csr.db
	$(INSTALL) -D -m 0644 $(@D)/ebf/csr-cn10k.db $(TARGET_DIR)/usr/share/txcsr/csr-cn10k.db
	$(INSTALL) -D -m 0644 $(@D)/ebf/csr-c2.db $(TARGET_DIR)/usr/share/txcsr/csr-c2.db
	$(INSTALL) -D -m 0644 $(@D)/ebf/csr-c3.db $(TARGET_DIR)/usr/share/txcsr/csr-c3.db
endef

$(eval $(generic-package))
