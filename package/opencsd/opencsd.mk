################################################################################
#
# OpenCSD
#
################################################################################

OPENCSD_SITE = https://github.com/Linaro/OpenCSD.git
OPENCSD_VERSION = v1.4.0
OPENCSD_SITE_METHOD = git
OPENCSD_INSTALL_STAGING = YES
# Note for OPENCSD_VERSION = master (README.md):
# From version 0.7.4, the required updates to CoreSight drivers and perf, that are not
# currently upstream in the linux kernel tree, are now contained in a separate
# repository to be found at:  https://github.com/Linaro/perf-opencsd

define OPENCSD_BUILD_CMDS
	echo $(PWD)
	$(TARGET_MAKE_ENV) CROSS_COMPILE=$(TARGET_CROSS) $(MAKE1) ARCH=arm64 -C $(@D)/decoder/build/linux/
endef

define OPENCSD_INSTALL_STAGING_CMDS
	$(MAKE1) ARCH=arm64 CROSS_COMPILE=$(TARGET_CROSS) PREFIX=$(STAGING_DIR)/usr install -C $(@D)/decoder/build/linux/
endef

define OPENCSD_INSTALL_TARGET_CMDS
	$(MAKE1) ARCH=arm64 CROSS_COMPILE=$(TARGET_CROSS) PREFIX=$(TARGET_DIR)/usr install -C $(@D)/decoder/build/linux/
	cp -d  $(@D)/decoder/lib/builddir/libopencsd.a $(TARGET_DIR)/usr/lib/libopencsd.a
	cp -d  $(@D)/decoder/lib/builddir/libopencsd_c_api.a $(TARGET_DIR)/usr/lib/libopencsd_c_api.a
	cp -d  $(@D)/decoder/tests/bin/builddir/c_api_pkt_print_test $(TARGET_DIR)/usr/bin/
	mkdir -p $(TARGET_DIR)/usr/share/opencsd
	cp -d  $(@D)/coresight-trace.py $(TARGET_DIR)/usr/share/opencsd/
	cp -d  $(@D)/coresight-sysfs.sh $(TARGET_DIR)/usr/bin/
	cp -d  $(@D)/coresight-cti-config.sh $(TARGET_DIR)/usr/bin/
	cp -d  $(@D)/README-coresight-sysfs.txt $(TARGET_DIR)/usr/share/opencsd/
	cp -d  $(@D)/arm-cs-trace-disasm.py $(TARGET_DIR)/usr/share/opencsd/
endef

$(eval $(generic-package))
