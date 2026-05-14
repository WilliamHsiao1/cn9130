################################################################################
#
# ASIM
#
################################################################################

define HOST_ASIM_INSTALL_CMDS
	$(INSTALL) -D -m 0755 $(HOST_ASIM_PKGDIR)/run-asim.sh $(BINARIES_DIR)/asim/run-asim.sh
	$(INSTALL) -D -m 0644 $(wildcard $(HOST_ASIM_PKGDIR)/*.asim) -t $(BINARIES_DIR)/asim/configs
endef

$(eval $(host-generic-package))
