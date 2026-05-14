################################################################################
#
# mrvl-utils: A collection of utilities created by Marvell
#
################################################################################

MRVL_UTILS_VERSION = $(call qstrip,$(BR2_PACKAGE_MRVL_UTILS_VERSION))

MRVL_UTILS_LICENSE = BSD-3-Clause
MRVL_UTILS_LICENSE_FILES = license.txt

ifeq ($(BR2_PACKAGE_MRVL_UTILS_CUSTOM_GIT),y)
MRVL_UTILS_SITE = $(call qstrip,$(BR2_PACKAGE_MRVL_UTILS_CUSTOM_REPO_URL))
MRVL_UTILS_SITE_METHOD = git
else
ifeq ($(BR2_PACKAGE_MRVL_UTILS_CUSTOM_TARBALL),y)
MRVL_UTILS_TARBALL = $(call qstrip,$(BR2_PACKAGE_MRVL_UTILS_CUSTOM_TARBALL_LOCATION))
MRVL_UTILS_SITE = $(patsubst %/,%,$(dir $(BR2_PACKAGE_MRVL_UTILS_CUSTOM_TARBALL)))
MRVL_UTILS_SOURCE = $(notdir $(BR2_PACKAGE_MRVL_UTILS_CUSTOM_TARBALL))
MRVL_UTILS_SITE_METHOD = file
else
ifeq ($(BR2_PACKAGE_MRVL_UTILS_GIT),y)
MRVL_UTILS_SITE = https://github.com/Marvell-Lab/mrvl-utils.git
MRVL_UTILS_SITE_METHOD = git
else
MRVL_UTILS_SITE = $(TOPDIR)/../base-sources-$(MRVL_UTILS_VERSION)/mrvl-utils
MRVL_UTILS_SOURCE = sources-mrvl-utils-$(MRVL_UTILS_VERSION).tar.bz2
MRVL_UTILS_SITE_METHOD = file
endif
endif
endif

BR_NO_CHECK_HASH_FOR += $(MRVL_UTILS_SOURCE)

ifeq ($(BR2_PACKAGE_OPTEE),y)
MRVL_UTILS_DEPENDENCIES = optee-test openssl
endif

# Common arguments forwarded to the mrvl-utils top-level Makefile.
# The top-level Makefile selects which components to build based on
# SOC_FAMILY and OPTEE_ENABLED, so sdk-base no longer needs to know
# about individual component build recipes.
MRVL_UTILS_MAKE_ARGS = \
	CROSS_COMPILE=$(TARGET_CROSS) \
	SOC_FAMILY=$(call qstrip,$(BR2_MARVELL_SOC_FAMILY)) \
	OPTEE_ENABLED=$(if $(BR2_PACKAGE_OPTEE),y,) \
	TA_DEV_KIT_DIR=$(OPTEE_DIR)/out/arm-plat-marvell/export-ta_arm64/ \
	TEEC_EXPORT=$(OPTEE_CLIENT_DIR)/out/export \
	OPENSSL_EXPORT=$(STAGING_DIR)/usr

define MRVL_UTILS_BUILD_CMDS
	PATH=$(HOST_DIR)/usr/bin:$(PATH):$(@D)/tools/bin \
	$(MAKE) -C $(@D) all $(MRVL_UTILS_MAKE_ARGS)
endef

define MRVL_UTILS_INSTALL_TARGET_CMDS
	$(MAKE) -C $(@D) install $(MRVL_UTILS_MAKE_ARGS) \
		DESTDIR=$(TARGET_DIR) INSTALL=$(INSTALL)
endef

$(eval $(generic-package))
