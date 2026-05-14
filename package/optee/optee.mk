################################################################################
#
# optee
#
################################################################################

OPTEE_VERSION = $(call qstrip,$(BR2_PACKAGE_OPTEE_VERSION))

ifeq ($(BR2_PACKAGE_OPTEE_CUSTOM_GIT),y)
OPTEE_SITE = $(call qstrip,$(BR2_PACKAGE_OPTEE_CUSTOM_REPO_URL))
OPTEE_SITE_METHOD = git
else
ifeq ($(BR2_PACKAGE_OPTEE_CUSTOM_TARBALL),y)
OPTEE_TARBALL = $(call qstrip,$(BR2_PACKAGE_OPTEE_CUSTOM_TARBALL_LOCATION))
OPTEE_SITE = $(patsubst %/,%,$(dir $(OPTEE_TARBALL)))
OPTEE_SOURCE = $(notdir $(OPTEE_TARBALL))
OPTEE_SITE_METHOD = file
else
ifeq ($(BR2_PACKAGE_OPTEE_GIT),y)
OPTEE_SITE = https://github.com/Marvell-Lab/optee.git
OPTEE_SITE_METHOD = git
else
OPTEE_SITE = $(TOPDIR)/../base-sources-$(OPTEE_VERSION)/optee
OPTEE_SITE_METHOD = file
OPTEE_SOURCE = sources-optee-$(OPTEE_VERSION).tar.bz2
endif
endif
endif
OPTEE_DEPENDENCIES = host-openssl host-python3 host-python-cryptography host-python-pyelftools
BR_NO_CHECK_HASH_FOR += $(OPTEE_SOURCE)

ifneq ($(filter $(BR2_MARVELL_SOC_FAMILY),"CN10K" "CN20K"),)
OPTEE_PLATFORM_FW = marvell-
endif

ifeq ($(BR2_MARVELL_SOC_FAMILY), "OCTEONTX2")
OPTEE_PLATFORM_FW = marvell-otx2
endif

define OPTEE_BUILD_CMDS
endef

define OPTEE_INSTALL_TARGET_CMDS
endef



$(eval $(generic-package))

