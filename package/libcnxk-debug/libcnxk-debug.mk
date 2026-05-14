################################################################################
#
# LIBCNXK_DEBUG
#
################################################################################

LIBCNXK_DEBUG_VERSION = $(call qstrip,$(BR2_PACKAGE_LIBCNXK_DEBUG_VERSION))

ifeq ($(BR2_PACKAGE_LIBCNXK_DEBUG_CUSTOM_GIT),y)
LIBCNXK_DEBUG_SITE = $(call qstrip,$(BR2_PACKAGE_LIBCNXK_DEBUG_CUSTOM_REPO_URL))
LIBCNXK_DEBUG_SITE_METHOD = git
else

# Release builds, use archive file
LIBCNXK_DEBUG_RELEASE = $(call qstrip,$(BR2_MARVELL_RELEASE_ID))
LIBCNXK_DEBUG_SITE_METHOD = file
LIBCNXK_DEBUG_ARCHIVE = $(call qstrip,$(BR2_PACKAGE_LIBCNXK_DEBUG_CUSTOM_ARCHIVE_LOCATION))
LIBCNXK_DEBUG_SITE = $(patsubst %/,%,$(dir $(LIBCNXK_DEBUG_ARCHIVE)))
LIBCNXK_DEBUG_SOURCE = $(notdir $(LIBCNXK_DEBUG_ARCHIVE))

endif # BR2_PACKAGE_LIBCNXK_DEBUG_CUSTOM_GIT

LIBCNXK_DEBUG_DEPENDENCIES = libunwind libcurl zlib cunit libmicrohttpd jansson host-doxygen

ifeq ($(BR2_PACKAGE_LIBCNXK_DEBUG_PLATFORM_CN10K),y)
LIBCNXK_DEBUG_CONF_OPTS += --cross $(@D)/config/arm64_cn10k_linux_gcc
endif

ifeq ($(BR2_PACKAGE_LIBCNXK_DEBUG_PLATFORM_CN9K),y)
LIBCNXK_DEBUG_CONF_OPTS += --cross $(@D)/config/arm64_cn9k_linux_gcc
endif

$(eval $(meson-package))

