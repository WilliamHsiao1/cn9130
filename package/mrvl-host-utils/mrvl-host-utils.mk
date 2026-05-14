################################################################################
#
# mrvl-host-utils
#
################################################################################

MRVL_HOST_UTILS_VERSION = $(call qstrip,$(BR2_PACKAGE_MRVL_HOST_UTILS_VERSION))

ifeq ($(BR2_PACKAGE_MRVL_HOST_UTILS_CUSTOM_GIT),y)
MRVL_HOST_UTILS_SITE = $(call qstrip,$(BR2_PACKAGE_MRVL_HOST_UTILS_CUSTOM_REPO_URL))
MRVL_HOST_UTILS_SITE_METHOD = git
else
ifeq ($(BR2_PACKAGE_MRVL_HOST_UTILS_CUSTOM_TARBALL),y)
MRVL_HOST_UTILS_TARBALL = $(call qstrip,$(BR2_PACKAGE_MRVL_HOST_UTILS_CUSTOM_TARBALL_LOCATION))
MRVL_HOST_UTILS_SITE = $(patsubst %/,%,$(dir $(BR2_PACKAGE_MRVL_HOST_UTILS_CUSTOM_TARBALL)))
MRVL_HOST_UTILS_SOURCE = $(notdir $(BR2_PACKAGE_MRVL_HOST_UTILS_CUSTOM_TARBALL))
MRVL_HOST_UTILS_SITE_METHOD = file
else
ifeq ($(BR2_PACKAGE_MRVL_HOST_UTILS_GIT),y)
MRVL_HOST_UTILS_SITE = https://github.com/Marvell-Lab/base-mrvl-host-utils.git
MRVL_HOST_UTILS_SITE_METHOD = git
else
MRVL_HOST_UTILS_SITE = $(TOPDIR)/../base-sources-$(MRVL_HOST_UTILS_VERSION)/mrvl-host-utils
MRVL_HOST_UTILS_SOURCE = sources-mrvl-host-utils-$(MRVL_HOST_UTILS_VERSION).tar.bz2
MRVL_HOST_UTILS_SITE_METHOD = file
# the version passed to the Make - only known when using a known 'site' (i.e., not custom git, etc.)
MRVL_HOST_UTILS_BUILD_VER = MRVL_HOST_UTILS_BUILD_VER=$(MRVL_HOST_UTILS_VERSION)
endif
endif
endif

BR_NO_CHECK_HASH_FOR += $(MRVL_HOST_UTILS_SOURCE)

ifeq ($(BR2_TARGET_MARVELL_EXTERNAL_FW),y)
HOST_MRVL_HOST_UTILS_DEPENDENCIES += marvell-external-fw
ifeq ($(BR2_PACKAGE_MRVL_HOST_UTILS_CN10K),y)
HOST_MRVL_HOST_UTILS_DEPENDENCIES_CSR_LOC = $(MARVELL_EXTERNAL_FW_DIR)/firmware/atf/include/plat/marvell/octeontx/cn10k/csr
MRVL_HOST_UTILS_MAKE_FLAGS += CN10K=1
else
HOST_MRVL_HOST_UTILS_DEPENDENCIES_CSR_LOC = $(MARVELL_EXTERNAL_FW_DIR)/firmware/atf/include/plat/marvell/octeontx/csr
endif
else
HOST_MRVL_HOST_UTILS_DEPENDENCIES += arm-trusted-firmware
HOST_MRVL_HOST_UTILS_DEPENDENCIES_CSR_LOC = $(STAGING_DIR)/usr/include/arm-trusted-firmware/plat/marvell/octeontx/csr
endif

HOST_MRVL_HOST_UTILS_DEPENDENCIES += host-dtc host-ncurses

MRVL_HOST_UTILS_EXECS = \
	mrvl-remote-boot \
	mrvl-remote-csr \
	mrvl-remote-load \
	mrvl-remote-memory \
	mrvl-remote-reset \
	mrvl-remote-save \
	mrvl-remote-sso \
	mrvl-remote-bootcmd \
	mrvl-remote-console \
	update_tool_howto.txt \
	burn_image.sh \
	octep_fw_util.py

define HOST_MRVL_HOST_UTILS_BUILD_CMDS
	$(HOST_MAKE_ENV) CFLAGS=-I$(HOST_DIR)/usr/include LDLIBS=-L$(HOST_DIR)/lib $(MAKE) \
		$(MRVL_HOST_UTILS_MAKE_FLAGS) LDFLAGS=-Wl,-rpath=$(HOST_DIR)/lib \
		CSR_INC_PATH=$(HOST_MRVL_HOST_UTILS_DEPENDENCIES_CSR_LOC) \
		$(MRVL_HOST_UTILS_BUILD_VER) \
		-C $(@D)
endef

define HOST_MRVL_HOST_UTILS_INSTALL_CMDS
	mkdir -p $(BINARIES_DIR)/host/usr/bin
	$(foreach i,$(MRVL_HOST_UTILS_EXECS), \
		$(INSTALL) -D -m 0755 $(@D)/$(i) $(HOST_DIR)/bin/$(i) ; \
		$(INSTALL) -D -m 0755 $(@D)/$(i) $(BINARIES_DIR)/host/usr/bin/$(i) ; \
	)
	mkdir -p $(TARGET_DIR)/etc/init.d/
	$(INSTALL) -D -m 0755 $(@D)/burn_image.sh $(TARGET_DIR)/etc/init.d/S90burn_image.sh ;
endef

$(eval $(host-generic-package))
