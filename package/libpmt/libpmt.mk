################################################################################
#
# libpmt
#
################################################################################

LIBPMT_VERSION = $(call qstrip,$(BR2_PACKAGE_LIBPMT_VERSION))

ifeq ($(BR2_PACKAGE_LIBPMT_CUSTOM_GIT),y)
LIBPMT_SITE = $(call qstrip,$(BR2_PACKAGE_LIBPMT_CUSTOM_REPO_URL))
LIBPMT_SITE_METHOD = git
else
ifeq ($(BR2_PACKAGE_LIBPMT_CUSTOM_TARBALL),y)
LIBPMT_TARBALL = $(call qstrip,$(BR2_PACKAGE_LIBPMT_CUSTOM_TARBALL_LOCATION))
LIBPMT_SITE = $(patsubst %/,%,$(dir $(LIBPMT_VERSION)))
LIBPMT_SOURCE = $(notdir $(LIBPMT_VERSION))
LIBPMT_SITE_METHOD = file
else
ifeq ($(BR2_PACKAGE_LIBPMT_GIT),y)
LIBPMT_SITE = https://github.com/Marvell-Lab/accelerator-libpmt.git
LIBPMT_SITE_METHOD = git
else
LIBPMT_SITE = $(TOPDIR)/../base-sources-$(LIBPMT_VERSION)/libpmt
LIBPMT_SITE_METHOD = file
LIBPMT_SOURCE = sources-libpmt-$(LIBPMT_VERSION).tar.bz2
endif
endif
endif

BR_NO_CHECK_HASH_FOR += $(LIBPMT_SOURCE)

LIBPMT_INSTALL_STAGING = YES

# Build and install PMU tracing examples if LTTng is enabled
ifeq ($(BR2_PACKAGE_LTTNG_LIBUST),y)
ifeq ($(BR2_PACKAGE_LTTNG_TOOLS),y)
LIBPMT_DEPENDENCIES = lttng-libust lttng-tools
define LIBPMT_WITH_LTTNG_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/examples/pmu_tracepoint_perf CC=$(TARGET_CC) \
					LTTNG_PATH=$(STAGING_DIR)/usr
endef
define LIBPMT_WITH_LTTNG_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0755 $(@D)/examples/pmu_tracepoint_perf/pmu_tracepoint_perf \
				$(TARGET_DIR)/usr/bin/pmu_tracepoint_perf
	$(INSTALL) -D -m 0755 $(@D)/examples/pmu_tracepoint_perf/runtime/pmu_tracepoint_perf-lttng-setup.sh \
				$(TARGET_DIR)/usr/bin/pmu_tracepoint_perf-lttng-setup.sh
endef
endif
endif

define LIBPMT_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) CC=$(TARGET_CC) AR=$(TARGET_AR)
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/examples/pmu_l1_dmiss CC=$(TARGET_CC)
$(LIBPMT_WITH_LTTNG_BUILD_CMDS)
endef

define LIBPMT_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0644 $(@D)/lib/libpmt.a $(STAGING_DIR)/usr/lib/libpmt.a
	$(INSTALL) -D -m 0644 $(@D)/include/pmt.h $(STAGING_DIR)/usr/include/pmt.h
	$(INSTALL) -D -m 0644 $(@D)/include/pmt/api.h $(STAGING_DIR)/usr/include/pmt/api.h
	$(INSTALL) -D -m 0644 $(@D)/include/pmt/bits.h $(STAGING_DIR)/usr/include/pmt/bits.h
	$(INSTALL) -D -m 0644 $(@D)/include/pmu_api.h $(STAGING_DIR)/usr/include/pmu_api.h
	$(INSTALL) -D -m 0644 $(@D)/include/pmu/bits.h $(STAGING_DIR)/usr/include/pmu/bits.h
endef

define LIBPMT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/lib/libpmt.a $(TARGET_DIR)/usr/lib/libpmt.a
	$(INSTALL) -D -m 0644 $(@D)/include/pmt.h $(TARGET_DIR)/usr/include/pmt.h
	$(INSTALL) -D -m 0644 $(@D)/include/pmt/api.h $(TARGET_DIR)/usr/include/pmt/api.h
	$(INSTALL) -D -m 0644 $(@D)/include/pmt/bits.h $(TARGET_DIR)/usr/include/pmt/bits.h
	$(INSTALL) -D -m 0644 $(@D)/include/pmu_api.h $(TARGET_DIR)/usr/include/pmu_api.h
	$(INSTALL) -D -m 0644 $(@D)/include/pmu/bits.h $(TARGET_DIR)/usr/include/pmu/bits.h
	$(INSTALL) -D -m 0755 $(@D)/pmt_test $(TARGET_DIR)/usr/bin/pmt_test
	$(INSTALL) -D -m 0755 $(@D)/examples/pmu_l1_dmiss/pmu_l1_dmiss \
				$(TARGET_DIR)/usr/bin/pmu_l1_dmiss
$(LIBPMT_WITH_LTTNG_INSTALL_STAGING_CMDS)
endef

$(eval $(generic-package))
