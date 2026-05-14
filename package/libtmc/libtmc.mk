################################################################################
#
# libtmc
#
################################################################################

LIBTMC_VERSION = v1.0.1
LIBTMC_SITE = https://github.com/abelits/libtmc/archive/refs/tags
LIBTMC_SOURCE = $(LIBTMC_VERSION).tar.gz


LIBTMC_INSTALL_STAGING = YES

LIBTMC_INSTALL_TARGET = YES

define BOOTSTRAP_HOOK
        @$(call MESSAGE,"Running bootstrap")
        $(Q)cd $(@D) && ./bootstrap
endef

LIBTMC_PRE_CONFIGURE_HOOKS += BOOTSTRAP_HOOK


LIBTMC_CONF_OPTS += --prefix=/usr


$(eval $(autotools-package))
