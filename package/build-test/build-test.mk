################################################################################
#
# build-test
#
################################################################################

# For now, use SDK GIT with this package.
# TODO: use dedicated GIT for the package
ifeq ($(BR2_PACKAGE_BUILD_TEST_GIT),y)
BUILD_TEST_SITE = https://github.com/Marvell-Lab/octeon-sdk.git
BUILD_TEST_VERSION = sdk-devel
BUILD_TEST_SITE_METHOD = git
else
BUILD_TEST_VERSION = $(call qstrip,$(BR2_MARVELL_RELEASE_ID))
BUILD_TEST_SITE = $(TOPDIR)/../base-sources-$(BUILD_TEST_VERSION)/sdk
BUILD_TEST_SITE_METHOD = file
BUILD_TEST_SOURCE = sources-sdk-$(BUILD_TEST_VERSION).tar.bz2
endif

BUILD_TEST_FOLDER = linux/cavium-rootfs/source/build-test

define BUILD_TEST_BUILD_CMDS
	$(TARGET_MAKE_ENV) CROSS=$(TARGET_CROSS) $(MAKE) -C $(@D)/$(BUILD_TEST_FOLDER) host
	$(TARGET_MAKE_ENV) CROSS=$(TARGET_CROSS) $(MAKE) -C $(@D)/$(BUILD_TEST_FOLDER) clean
endef

define BUILD_TEST_INSTALL_TARGET_CMDS
	@echo "BUILD_TEST_INSTALL_TARGET_CMDS"
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/share/build-test
	$(INSTALL) -m 0644 $(@D)/$(BUILD_TEST_FOLDER)/* -t $(TARGET_DIR)/usr/share/build-test
endef

$(eval $(generic-package))
