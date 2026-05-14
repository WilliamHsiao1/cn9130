################################################################################
#
# spdk
#
################################################################################

#BR2_PACKAGE_SPDK_CUSTOM_GIT
ifeq ($(BR2_PACKAGE_SPDK_CUSTOM_GIT),y)
SPDK_SITE = $(call qstrip,$(BR2_PACKAGE_SPDK_CUSTOM_REPO_URL))
SPDK_VERSION = $(call qstrip,$(BR2_PACKAGE_SPDK_CUSTOM_REPO_VERSION))
SPDK_SITE_METHOD = git
SPDK_RELEASE=$(call qstrip,$(BR2_MARVELL_RELEASE_ID))
else
SPDK_RELEASE = $(call qstrip,$(BR2_MARVELL_RELEASE_ID))
SPDK_SITE_METHOD = file
SPDK_ARCHIVE = $(call qstrip,$(BR2_PACKAGE_SPDK_CUSTOM_ARCHIVE_LOCATION))
SPDK_SITE = $(patsubst %/,%,$(dir $(SPDK_ARCHIVE)))
SPDK_SOURCE = $(notdir $(SPDK_ARCHIVE))

endif

SPDK_DEPENDENCIES += dpdk
SPDK_DEPENDENCIES += libaio
SPDK_DEPENDENCIES += linux util-linux
SPDK_DEPENDENCIES += libopenssl
SPDK_DEPENDENCIES += cunit
SPDK_CROSS_DIR = $(dir $(TARGET_CROSS))

DPDK_PC?=$(DPDK_DIR)/build/meson-private

PKGCONF ?= PKG_CONFIG_PATH=$(DPDK_PC) PKG_CONFIG_SYSROOT_DIR=$(TARGET_DIR) pkg-config


#PC_FILE := $(shell $(PKGCONF) --path libdpdk 2>/dev/null)
PC_FILE := $(DPDK_DIR)/build/meson-private/libdpdk.pc

SPDK_CONFIG_WITH = --without-isal --without-iscsi-initiator
SPDK_CFLAGS = -march=armv8.2-a+crc+crypto+lse -O3

ifeq ($(BR2_PACKAGE_SPDK_WITH_RDMA),y)
SPDK_DEPENDENCIES += rdma-core
SPDK_CONFIG_WITH += --with-rdma
SPDK_CFLAGS += -I$(STAGING_DIR)/usr/include
SPDK_LDFLAGS = -L$(STAGING_DIR)/usr/lib
define SPDK_BUILDROOT_RDMA_CHECK_WA
	export BUILDROOT_RDMA_CHECK_WA=1;
endef
define SPDK_INSTALL_TARGET_RDMA
	mkdir -p $(TARGET_DIR)/usr/marvell/spdk
	cp -ra $(@D)/build/bin $(TARGET_DIR)/usr/marvell/spdk/
	cp -ra $(@D)/scripts $(TARGET_DIR)/usr/marvell/spdk/
	cp -ra $(@D)/include $(TARGET_DIR)/usr/marvell/spdk/
endef
endif

define SPDK_CONFIGURE_CMDS
	$(SPDK_BUILDROOT_RDMA_CHECK_WA) \
	export PATH=$(SPDK_CROSS_DIR):$(PATH); \
	export CFLAGS="$(SPDK_CFLAGS)"; export LDFLAGS="$(SPDK_LDFLAGS)"; \
	export CC=aarch64-marvell-linux-gnu-gcc; \
	$(@D)/configure --with-dpdk=$(DPDK_DIR)/build $(SPDK_CONFIG_WITH) \
	--prefix=$(STAGING_DIR)/usr --cross-prefix=aarch64-marvell-linux-gnu
endef

DPDK_APP_MAKE_OPTS = \
	RTE_SDK=$(@D)/../$(DPDK_DIRNAME) \
	RTE_TARGET=build \
	$(DPDK_MAKE_OPTS)

SPDK_MAKE_OPTS = \
	CC=aarch64-marvell-linux-gnu-gcc \
	CXX=aarch64-marvell-linux-gnu-c++ \
	CCAR=aarch64-marvell-linux-gnu-ar \
	CROSS=aarch64-marvell-linux-gnu-

define SPDK_BUILD_CMDS
	export PATH=$(SPDK_CROSS_DIR):$(PATH); \
	$(MAKE) -C $(@D) $(SPDK_MAKE_OPTS)
endef

define SPDK_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/build/lib/*.a $(TARGET_DIR)/usr/lib
	$(SPDK_INSTALL_TARGET_RDMA)
endef

$(eval $(generic-package))
