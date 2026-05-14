################################################################################
#
# OVS: Open vSwitch
#
################################################################################

OVS_VERSION = $(call qstrip,$(BR2_PACKAGE_OVS_VERSION))

ifeq ($(BR2_PACKAGE_OVS_CUSTOM_GIT),y)
OVS_SITE = $(call qstrip,$(BR2_PACKAGE_OVS_CUSTOM_REPO_URL))
OVS_SITE_METHOD = git
else

# Release builds, use archive file
OVS_RELEASE = $(call qstrip,$(BR2_MARVELL_RELEASE_ID))
OVS_SITE_METHOD = file
OVS_ARCHIVE = $(call qstrip,$(BR2_PACKAGE_OVS_CUSTOM_ARCHIVE_LOCATION))
OVS_SITE = $(patsubst %/,%,$(dir $(OVS_ARCHIVE)))
OVS_SOURCE = $(notdir $(OVS_ARCHIVE))

endif # BR2_PACKAGE_OVS_CUSTOM_GIT

# OVS cross-compilation
OVS_CONF_OPTS += --host=$(BR2_TOOLCHAIN_EXTERNAL_PREFIX)
OVS_CONF_OPTS += --target=$(BR2_TOOLCHAIN_EXTERNAL_PREFIX)

# OVS with Linux Kernel Datapath Support
ifeq ($(BR2_LINUX_KERNEL),y)
# NOTE: Make sure this flag CONFIG_NET_IPGRE_DEMUX is enabled in linux config file

ifeq ($(BR2_ARCH),"aarch64")
OVS_CONF_OPTS += KARCH=arm64
endif # BR2_ARCH

OVS_CONF_OPTS += --with-linux=$(LINUX_DIR)
endif # BR2_LINUX_KERNEL

# OVS with OpenSSL Support
ifeq ($(BR2_PACKAGE_LIBOPENSS),y)
OVS_DEPENDENCIES += libopenssl
OVS_CONF_OPTS += --with-openssl=$(HOST_DIR)
else
OVS_CONF_OPTS += --disable-ssl
endif # BR2_PACKAGE_LIBOPENSSL

OVS_DEPENDENCIES += host-binutils
# If OVS is checked out form GIT repo then execute boot.sh before configure
OVS_PRE_BOOT_CMD="./boot.sh"

define OVS_CONFIGURE_CMDS
        (cd $(@D);$(OVS_PRE_BOOT_CMD);./configure $(OVS_CONF_OPTS) CC=$(TARGET_CROSS)gcc CXX=$(TARGET_CROSS)g++ ; )
endef

define OVS_BUILD_CMDS
        $(MAKE) -C $(@D) CROSS_COMPILE=$(TARGET_CROSS)
endef

define OVS_INSTALL_STAGING_CMDS
        $(MAKE) -C $(@D) install DESTDIR=$(STAGING_DIR) CROSS_COMPILE=$(TARGET_CROSS)
endef

define OVS_INSTALL_TARGET_CMDS
        $(MAKE) -C $(@D) install DESTDIR=$(TARGET_DIR)
endef

$(eval $(generic-package))
