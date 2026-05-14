################################################################################
#
# dpdk
#
################################################################################

DPDK_VERSION = $(call qstrip,$(BR2_PACKAGE_DPDK_VERSION))

ifneq ($(DPDK_OVERRIDE_SRCDIR),)
BR2_PACKAGE_DPDK_VERSION = custom
endif

ifeq ($(BR2_PACKAGE_DPDK_LATEST_VERSION),y)
DPDK_SITE = http://fast.dpdk.org/rel
DPDK_SOURCE = dpdk-$(DPDK_VERSION).tar.xz
else

ifeq ($(BR2_PACKAGE_DPDK_CUSTOM_GIT),y)
DPDK_SITE = $(call qstrip,$(BR2_PACKAGE_DPDK_CUSTOM_REPO_URL))
DPDK_SITE_METHOD = git
else

# Release builds, use archive file
DPDK_RELEASE = $(call qstrip,$(BR2_MARVELL_RELEASE_ID))
DPDK_SITE_METHOD = file
DPDK_ARCHIVE = $(call qstrip,$(BR2_PACKAGE_DPDK_CUSTOM_ARCHIVE_LOCATION))
DPDK_SITE = $(patsubst %/,%,$(dir $(DPDK_ARCHIVE)))
DPDK_SOURCE = $(notdir $(DPDK_ARCHIVE))

endif # BR2_PACKAGE_DPDK_CUSTOM_GIT

# Not from the mainline sources
BR_NO_CHECK_HASH_FOR += $(DPDK_SOURCE)
endif # BR2_PACKAGE_DPDK_LATEST_VERSION

DPDK_LICENSE = BSD-2-Clause (core), GPL-2.0+ (Linux drivers)
DPDK_INSTALL_STAGING = YES

DPDK_DEPENDENCIES += host-pkgconf linux python-pyelftools
ifeq ($(BR2_PACKAGE_DPDK_CRYPTO),y)
DPDK_DEPENDENCIES += dpdk-crypto
endif

ifeq ($(BR2_PACKAGE_LIBIPSEC_MB), y)
ifeq ($(BR2_MARVELL_SOC_FAMILY), "CN10K")
DPDK_DEPENDENCIES += libipsec-mb
endif

ifeq ($(BR2_MARVELL_SOC_FAMILY), "OCTEONTX2")
DPDK_DEPENDENCIES += libipsec-mb
endif
endif

define LINK_PYTHON_MODULE
	$(shell ln -s $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/site-packages/elftools/ $(HOST_DIR)/lib/python$(PYTHON3_VERSION_MAJOR)/site-packages/ )
endef

DPDK_POST_PATCH_HOOKS = LINK_PYTHON_MODULE

ifeq ($(BR2_PACKAGE_DPDK_DEBUG_BUILD),y)
DPDK_CONF_OPTS +=--buildtype=debug
endif

ifeq ($(BR2_PACKAGE_MUSDK_MARVELL),y)
DPDK_DEPENDENCIES += musdk-marvell
#DPDK_CONF_OPTS +=-Dlib_musdk_dir=$(STAGING_DIR)/usr
endif

ifeq ($(BR2_PACKAGE_TVMDP),y)
DPDK_DEPENDENCIES += libarchive jansson dlpack tvm tvmdp
endif

# Platform-specific target folder for the installation
DPDK_INSTALL_BASE = $(call qstrip,$(BR2_MARVELL_TARGET_INSTALL_BASE))
DPDK_PLAT_DIR = /$(call qstrip,$(BR2_MARVELL_SOC_FAMILY))
DPDK_KMOD_PATH = $(DPDK_INSTALL_BASE)$(DPDK_PLAT_DIR)

ifeq ($(DPDK_INSTALL_BASE),)
DPDK_INSTALL_BASE = /usr
DPDK_PLAT_DIR =
DPDK_KMOD_PATH =
endif


define SET_RTE_CONFIG
	if grep -nr "$1*" $(@D)/build/rte_build_config.h; then sed -e 's/$1.*/$2/g' -i $(@D)/build/rte_build_config.h;\
                else echo "#define $2" >>$(@D)/build/rte_build_config.h; fi
endef


DPDK_TARGET_INSTALL_DIR = $(TARGET_DIR)$(DPDK_INSTALL_BASE)$(DPDK_PLAT_DIR)

ifeq ($(BR2_PACKAGE_DPDK_SHARED_LIB),y)
ifeq ($(BR2_SHARED_LIBS),y)

define DPDK_ENABLE_SHARED_LIBS
	$(call SET_RTE_CONFIG,RTE_LIBRTE_PMD_DPAA2_SEC,RTE_LIBRTE_PMD_DPAA2_SEC 0)
	$(call SET_RTE_CONFIG,RTE_LIBRTE_FSLMC_BUS,RTE_LIBRTE_FSLMC_BUS 0)
	$(call SET_RTE_CONFIG,RTE_LIBRTE_DPAA2_PMD,RTE_LIBRTE_DPAA2_PMD 0)
	$(call SET_RTE_CONFIG,RTE_LIBRTE_DPAA2_MEMPOOL,RTE_LIBRTE_DPAA2_MEMPOOL 0)
	$(call SET_RTE_CONFIG,RTE_LIBRTE_PMD_DPAA2_EVENTDEV,RTE_LIBRTE_PMD_DPAA2_EVENTDEV 0)
	$(call SET_RTE_CONFIG,RTE_LIBRTE_PMD_DPAA2_CMDIF_RAWDEV,RTE_LIBRTE_PMD_DPAA2_CMDIF_RAWDEV 0)
	$(call SET_RTE_CONFIG,RTE_LIBRTE_PMD_DPAA2_QDMA_RAWDEV,RTE_LIBRTE_PMD_DPAA2_QDMA_RAWDEV 0)
	$(call SET_RTE_CONFIG,RTE_BUILD_SHARED_LIB,RTE_BUILD_SHARED_LIB 1)
endef
DPDK_POST_CONFIGURE_HOOKS += DPDK_ENABLE_SHARED_LIBS
endif # BR2_SHARED_LIBS
else
DPDK_CONF_OPTS +=--default-library=static
ifeq ($(BR2_PACKAGE_DPDK_ENABLE_FPIC),y)
DPDK_CFLAGS= -fPIC
endif # BR2_PACKAGE_DPDK_ENABLE_FPIC
endif # BR2_PACKAGE_DPDK_SHARED_LIB


#Enable Crypto perf application
define DPDK_ENABLE_APP_CRYPTO_PERF
	$(call SET_RTE_CONFIG,RTE_APP_CRYPTO_PERF,RTE_APP_CRYPTO_PERF 1)

endef

DPDK_POST_CONFIGURE_HOOKS += DPDK_ENABLE_APP_CRYPTO_PERF

ifeq ($(BR2_PACKAGE_NUMACTL),y)
DPDK_DEPENDENCIES += numactl
else
define DPDK_DISABLE_NUMA_FEATURES
#	#(all KCONFIG_DISABLE_OPT,CONFIG_RTE_EAL_NUMA_AWARE_HUGEPAGES,\
#		$(@D)/build/rte_build_config.h)
#	all KCONFIG_DISABLE_OPT,CONFIG_RTE_LIBRTE_VHOST_NUMA,\
#		$(@D)/build/rte_build_config.h)
#
	#call SET_RTE_CONFIG,RTE_EAL_NUMA_AWARE_HUGEPAGES,RTE_EAL_NUMA_AWARE_HUGEPAGES 0)
	#call SET_RTE_CONFIG,RTE_LIBRTE_VHOST_NUMA,RTE_LIBRTE_VHOST_NUMA 0)
endef
DPDK_POST_CONFIGURE_HOOKS += DPDK_DISABLE_NUMA_FEATURES
endif

# -- LIB-PCAP usage RE-config for DPDK only --
ifeq ($(BR2_PACKAGE_LIBPCAP),y)
ifneq ($(BR2_PACKAGE_DPDK_NO_LIBPCAP),y)
DPDK_DEPENDENCIES += libpcap
define DPDK_ENABLE_PCAP
	$(call SET_RTE_CONFIG,RTE_LIBRTE_PCAP_PMD,RTE_LIBRTE_PCAP_PMD 0)
endef
DPDK_POST_CONFIGURE_HOOKS += DPDK_ENABLE_PCAP
endif
endif # BR2_PACKAGE_LIBPCAP
#
ifeq ($(BR2_PACKAGE_MUSDK_MARVELL),y)
ifeq ($(BR2_PACKAGE_MUSDK_MARVELL_GIU), y)
## Enable DPDK MVGIU ethdev
define DPDK_ENABLE_MVGIU
	$(call SET_RTE_CONFIG,RTE_LIBRTE_MVGIU_PMD,RTE_LIBRTE_MVGIU_PMD 1)
endef
DPDK_POST_CONFIGURE_HOOKS += DPDK_ENABLE_MVGIU
endif # BR2_PACKAGE_MUSDK_MARVELL_GIU
#
#

define DPDK_MUSDK_APPS_TARGET_CMDS
	for app in $(@D)/build/examples/dpdk-l3fwd-cn913x* ; do \
		if [[ -x $$app ]] ; then \
			app_name=$${app##*/} ; \
			$(INSTALL) -D -m 0755 $(@D)/build/examples/$$app_name $(DPDK_TARGET_INSTALL_DIR)/bin/$$app_name ; \
		fi \
	done

	$(INSTALL) -D -m 0755 $(@D)/examples/ipsec-secgw/ep0.cfg $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-ipsec-secgw-ep0.cfg
	$(INSTALL) -D -m 0755 $(@D)/examples/ipsec-secgw/ep1.cfg $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-ipsec-secgw-ep1.cfg
endef
DPDK_PRE_CONFIGURE_HOOKS += DPDK_MUSDK_APPS_BUILD_CMDS
DPDK_POST_INSTALL_TARGET_HOOKS += DPDK_MUSDK_APPS_TARGET_CMDS

endif # BR2_PACKAGE_MUSDK_MARVELL

DPDK_CONFIG = $(call qstrip,$(BR2_PACKAGE_DPDK_CONFIG))

DPDK_CONF_OPTS+=-Dexamples=all
DPDK_CONF_OPTS+=--cross-file=$(@D)/config/arm/$(DPDK_CONFIG)

ifneq ($(BR2_PACKAGE_DPDK_WITHOUT_EXAMPLES),y)
define DPDK_COPY_BINARIES
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-l2fwd $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-l2fwd
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-l3fwd $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-l3fwd
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-ipsec-secgw $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-ipsec-secgw
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-eventdev_pipeline $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-eventdev_pipeline
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-l2fwd-event $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-l2fwd-event
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-ip_fragmentation $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-ip_fragmentation
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-ip_reassembly $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-ip_reassembly
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-l2fwd-keepalive $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-l2fwd-keepalive
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-hotplug_mp $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-hotplug_mp
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-mp_server $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-mp_server
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-mp_client $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-mp_client
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-symmetric_mp $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-symmetric_mp
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-efd_node $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-efd_node
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-efd_server $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-efd_server
	$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-fips_validation $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-fips_validation
	$(INSTALL) -D -m 0755 $(@D)/build/app/dpdk-testpmd $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-testpmd
	if [[ -f $(@D)/build/examples/dpdk-ml_inference ]] ; then \
		$(INSTALL) -D -m 0755 $(@D)/build/examples/dpdk-ml_inference $(DPDK_TARGET_INSTALL_DIR)/bin/dpdk-ml_inference ; \
	fi
endef
endif


DPDK_POST_INSTALL_TARGET_HOOKS += DPDK_COPY_BINARIES

# buildroot/package/pkg-generic.mk uses hook check_host_rpath
# this hook function checks if binaries installed in $(HOST_DIR) have rpath
# pointing to $(HOST_DIR)/lib
# However dpdk installs some libraries in host/lib/pmds-<version>
# As a result check_host_rpath returns error.
# So override check_host_rpath until it starts allowing subdirectories
# in host/lib
#
define check_host_rpath
endef

$(eval $(meson-package))
$(eval $(host-meson-package))
