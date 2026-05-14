################################################################################
#
# cpt-microcode
#
################################################################################

CPT_MICROCODE_VERSION = $(call qstrip,$(BR2_PACKAGE_CPT_MICROCODE_VERSION))

ifeq ($(BR2_PACKAGE_CPT_MICROCODE_CUSTOM_GIT),y)
CPT_MICROCODE_SITE = $(call qstrip,$(BR2_PACKAGE_CPT_MICROCODE_CUSTOM_REPO_URL))
CPT_MICROCODE_SITE_METHOD = git
else
ifeq ($(BR2_PACKAGE_CPT_MICROCODE_CUSTOM_TARBALL),y)
CPT_MICROCODE_TARBALL = $(call qstrip,$(BR2_PACKAGE_CPT_MICROCODE_CUSTOM_TARBALL_LOCATION))
CPT_MICROCODE_SITE = $(patsubst %/,%,$(dir $(CPT_MICROCODE_TARBALL)))
CPT_MICROCODE_SOURCE = $(notdir $(CPT_MICROCODE_TARBALL))
CPT_MICROCODE_SITE_METHOD = file
else
ifeq ($(BR2_PACKAGE_CPT_MICROCODE_GIT),y)
CPT_MICROCODE_SITE = https://github.com/Marvell-Lab/cpt-ucode.git
CPT_MICROCODE_SITE_METHOD = git
else
CPT_MICROCODE_SITE = $(TOPDIR)/../base-sources-$(CPT_MICROCODE_VERSION)/cpt-microcode
CPT_MICROCODE_SITE_METHOD = file
CPT_MICROCODE_SOURCE = sources-cpt-microcode-$(CPT_MICROCODE_VERSION).tar.bz2
endif
endif
endif

BR_NO_CHECK_HASH_FOR += $(CPT_MICROCODE_SOURCE)

CPT_MICROCODE_INSTALL_STAGING = NO

define CPT_MICROCODE_INSTALL_TARGET_CMDS
	if ! [ -d "$(TARGET_DIR)/lib/firmware" ]; then \
		mkdir $(TARGET_DIR)/lib/firmware; \
	fi
	$(INSTALL) -D -m 0644 $(@D)/cpt*-mc.tar $(TARGET_DIR)/lib/firmware/
	if [ -d "$(@D)/mrvl" ];then   \
		$(INSTALL) -D -m 0644 $(@D)/mrvl/cpt01/* -t $(TARGET_DIR)/lib/firmware/mrvl/cpt01; \
		$(INSTALL) -D -m 0644 $(@D)/mrvl/cpt02/* -t $(TARGET_DIR)/lib/firmware/mrvl/cpt02; \
		$(INSTALL) -D -m 0644 $(@D)/mrvl/cpt03/* -t $(TARGET_DIR)/lib/firmware/mrvl/cpt03; \
		$(INSTALL) -D -m 0644 $(@D)/mrvl/cpt04/* -t $(TARGET_DIR)/lib/firmware/mrvl/cpt04; \
		$(INSTALL) -D -m 0644 $(@D)/mrvl/cpt05/* -t $(TARGET_DIR)/lib/firmware/mrvl/cpt05; \
		$(INSTALL) -D -m 0644 $(@D)/mrvl/cpt06/* -t $(TARGET_DIR)/lib/firmware/mrvl/cpt06; \
	fi
endef

$(eval $(generic-package))
