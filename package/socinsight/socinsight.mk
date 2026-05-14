################################################################################
#
# SOCINSIGHT
#
################################################################################

SOCINSIGHT_VERSION = $(call qstrip,$(BR2_PACKAGE_SOCINSIGHT_VERSION))

ifeq ($(BR2_PACKAGE_SOCINSIGHT_CUSTOM_GIT),y)
SOCINSIGHT_SITE = $(call qstrip,$(BR2_PACKAGE_SOCINSIGHT_CUSTOM_REPO_URL))
SOCINSIGHT_SITE_METHOD = git
else

# Release builds, use archive file
SOCINSIGHT_RELEASE = $(call qstrip,$(BR2_MARVELL_RELEASE_ID))
SOCINSIGHT_SITE_METHOD = file
SOCINSIGHT_ARCHIVE = $(call qstrip,$(BR2_PACKAGE_SOCINSIGHT_CUSTOM_ARCHIVE_LOCATION))
SOCINSIGHT_SITE = $(patsubst %/,%,$(dir $(SOCINSIGHT_ARCHIVE)))
SOCINSIGHT_SOURCE = $(notdir $(SOCINSIGHT_ARCHIVE))

endif # BR2_PACKAGE_SOCINSIGHT_CUSTOM_GIT

SOCINSIGHT_DEPENDENCIES = libunwind libcurl zlib cunit libmicrohttpd jansson host-doxygen

ifeq ($(BR2_PACKAGE_SOCINSIGHT_PLATFORM_CN10K),y)
SOCINSIGHT_CONF_OPTS += --cross $(@D)/config/arm64_linux_gcc
endif

ifeq ($(BR2_PACKAGE_SOCINSIGHT_PLATFORM_CN9K),y)
SOCINSIGHT_CONF_OPTS += --cross $(@D)/config/arm64_cn9k_linux_gcc
endif

$(eval $(meson-package))

