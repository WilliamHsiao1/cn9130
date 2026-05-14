################################################################################
#
# musdk-marvell
#
################################################################################

MUSDK_MARVELL_VERSION = $(call qstrip,$(BR2_PACKAGE_MUSDK_MARVELL_VERSION))

ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_CUSTOM_GIT),y)
MUSDK_MARVELL_SITE = $(call qstrip,$(BR2_PACKAGE_MUSDK_MARVELL_CUSTOM_REPO_URL))
MUSDK_MARVELL_SITE_METHOD = git
else
ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_CUSTOM_TARBALL),y)
MUSDK_MARVELL_TARBALL = $(call qstrip,$(BR2_PACKAGE_MUSDK_MARVELL_CUSTOM_TARBALL_LOCATION))
MUSDK_MARVELL_SITE = $(patsubst %/,%,$(dir $(MUSDK_MARVELL_TARBALL)))
MUSDK_MARVELL_SOURCE = $(notdir $(MUSDK_MARVELL_TARBALL))
MUSDK_MARVELL_SITE_METHOD = file
endif # BR2_PACKAGE_MUSDK_MARVELL_CUSTOM_TARBALL
endif # BR2_PACKAGE_MUSDK_MARVELL_CUSTOM_GIT

ifeq ($(BR2_INIT_SYSTEMD),y)
MUSDK_MARVELL_DEPENDECIES += systemd
endif

MUSDK_MARVELL_AUTORECONF = YES
MUSDK_MARVELL_INSTALL_STAGING = YES

define MUSDK_MARVELL_CREATE_M4_DIR
	mkdir -p $(@D)/m4
endef
MUSDK_MARVELL_POST_PATCH_HOOKS += MUSDK_MARVELL_CREATE_M4_DIR

MUSDK_MARVELL_MODULES += cma dmax2

ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_FORCE_STATIC_EXAMPLES),y)
MUSDK_MARVELL_CONF_OPTS += --disable-shared
MUSDK_MARVELL_CONF_OPTS += --enable-static
MUSDK_MARVELL_MAKE_OPTS += EXTRA_CFLAGS="-fPIC"
endif

ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_NMP),y)
MUSDK_MARVELL_CONF_OPTS += --enable-nmp
MUSDK_MARVELL_INSTALL_IMAGES = YES
define MUSDK_MARVELL_INSTALL_IMAGES_CMDS
	$(INSTALL) -D -m 0744 $(@D)/apps/examples/musdk_nmp_standalone $(BINARIES_DIR)/marvell/musdk_nmp_standalone
endef
endif

ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_GIU),y)
MUSDK_MARVELL_CONF_OPTS += --enable-giu
endif

ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_PP2),y)
MUSDK_MARVELL_CONF_OPTS += --enable-pp2
MUSDK_MARVELL_MODULES += pp2 netdev_control
else
MUSDK_MARVELL_CONF_OPTS += --disable-pp2
endif

ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_PP2_LOCK),y)
MUSDK_MARVELL_CONF_OPTS += --enable-pp2-lock
else
MUSDK_MARVELL_CONF_OPTS += --disable-pp2-lock
endif

ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_NETA),y)
MUSDK_MARVELL_CONF_OPTS += --enable-neta
MUSDK_MARVELL_MODULES += neta
else
MUSDK_MARVELL_CONF_OPTS += --disable-neta
endif

ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_SAM),y)
MUSDK_MARVELL_CONF_OPTS += --enable-sam
MUSDK_MARVELL_MODULES += sam
else
MUSDK_MARVELL_CONF_OPTS += --disable-sam
endif

ifeq ($(BR2_LINUX_KERNEL),y)
MUSDK_MARVELL_MODULE_SUBDIRS = $(addprefix modules/,$(MUSDK_MARVELL_MODULES))
$(eval $(kernel-module))
endif

ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_KERNEL_PATCHES_APPLY),y)

ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_KERNEL_PATCHES_LINUX),y)
MUSDK_MARVELL_KERNEL_PATCH_SERIES = linux
else ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_KERNEL_PATCHES_LINUX_4_14),y)
MUSDK_MARVELL_KERNEL_PATCH_SERIES = linux-4.14
endif

ifeq ($(BR2_INIT_SYSTEMD),y)
define MUSDK_MARVELL_INSTALL_FIXUP
	grep -qxF "options uio_pdrv_genirq of_id=\"generic-uio\"" \
		$(TARGET_DIR)/lib/modprobe.d/systemd.conf || \
		echo -e "\noptions uio_pdrv_genirq of_id=\"generic-uio\"\n" >> \
		$(TARGET_DIR)/lib/modprobe.d/systemd.conf
endef
MUSDK_MARVELL_POST_INSTALL_TARGET_HOOKS += MUSDK_MARVELL_INSTALL_FIXUP
endif

endif

$(eval $(autotools-package))
