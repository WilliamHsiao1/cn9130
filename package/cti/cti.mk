################################################################################
#
# cti
#
################################################################################

CTI_VERSION = $(call qstrip,$(BR2_PACKAGE_CTI_VERSION))

ifeq ($(BR2_PACKAGE_CTI_CUSTOM_GIT),y)

CTI_SITE = $(call qstrip,$(BR2_PACKAGE_CTI_CUSTOM_REPO_URL))
CTI_SITE_METHOD = git

else

# Release builds, use archive file
CTI_RELEASE = $(call qstrip,$(BR2_MARVELL_RELEASE_ID))
CTI_SITE_METHOD = file
CTI_ARCHIVE = $(call qstrip,$(BR2_PACKAGE_CTI_CUSTOM_ARCHIVE_LOCATION))
CTI_SITE = $(patsubst %/,%,$(dir $(CTI_ARCHIVE)))
CTI_SOURCE = $(notdir $(CTI_ARCHIVE))

endif

# Not from the mainline sources
BR_NO_CHECK_HASH_FOR += $(CTI_SOURCE)

CTI_LICENSE = Marvell Proprietary

CTI_DEPENDENCIES += host-dpdk dpdk

define CTI_BUILD_CMDS
	$(TARGET_MAKE_ENV) CROSS_COMPILE=$(TARGET_CROSS) $(MAKE) -C $(@D) TARGET_DPDK_DIR=$(STAGING_DIR) l1-eth-app
	$(HOST_MAKE_ENV) $(MAKE) -C $(@D) HOST_DPDK_DIR=$(HOST_DIR) CTI_L2_ARCH=x86 l2-app
	$(TARGET_MAKE_ENV) CROSS_COMPILE=$(TARGET_CROSS) $(MAKE) -C $(@D) HOST_DPDK_DIR=$(STAGING_DIR) CTI_L2_ARCH=aarch64 l2-app
endef

define CTI_INSTALL_TARGET_CMDS
	mkdir -p $(BINARIES_DIR)/host/usr/bin
	mkdir -p $(BINARIES_DIR)/host/usr/lib

	$(INSTALL) -D -m 0755 $(@D)/bin/l1/eth/l1-eth-app $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0644 $(@D)/bin/l1/eth/libcti-l1.a $(TARGET_DIR)/usr/lib/libcti-l1.a
	$(INSTALL) -D -m 0644 $(@D)/bin/l1/eth/libcti-l1.so $(TARGET_DIR)/usr/lib/libcti-l1.so
	$(INSTALL) -D -m 0755 $(@D)/l1/eth/app/cti-l1-eth-app-start-sdp.sh $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/l1/eth/app/cti-l1-eth-app-start.sh $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/bin/l2/aarch64/l2-app $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0644 $(@D)/bin/l2/aarch64/libcti-l2.a $(TARGET_DIR)/usr/lib/
	$(INSTALL) -D -m 0644 $(@D)/bin/l2/aarch64/libcti-l2.so $(TARGET_DIR)/usr/lib/
	$(INSTALL) -D -m 0755 $(@D)/l2/apps/cti-test/cti-l2-app-start.sh $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/l2/apps/cti-test/cti-l2-app-start-sdp.sh $(TARGET_DIR)/usr/bin/

	$(INSTALL) -D -m 0755 $(@D)/bin/l2/x86/l2-app $(BINARIES_DIR)/host/usr/bin/
	$(INSTALL) -D -m 0644 $(@D)/bin/l2/x86/libcti-l2.a $(BINARIES_DIR)/host/usr/lib/
	$(INSTALL) -D -m 0644 $(@D)/bin/l2/x86/libcti-l2.so $(BINARIES_DIR)/host/usr/lib/
	$(INSTALL) -D -m 0755 $(@D)/l2/apps/cti-test/cti-l2-app-start.sh $(BINARIES_DIR)/host/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/l2/apps/cti-test/cti-l2-app-start-sdp.sh $(BINARIES_DIR)/host/usr/bin/

endef

$(eval $(generic-package))
