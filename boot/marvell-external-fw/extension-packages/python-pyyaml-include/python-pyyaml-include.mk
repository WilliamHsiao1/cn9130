################################################################################
#
# python-pyyaml-include
#
################################################################################

PYTHON_PYYAML_INCLUDE_VERSION = 1.3.1
PYTHON_PYYAML_INCLUDE_SOURCE = pyyaml-include-$(PYTHON_PYYAML_INCLUDE_VERSION).tar.gz
PYTHON_PYYAML_INCLUDE_SITE = https://files.pythonhosted.org/packages/45/ec/f730b826e22e4fad5f86f9130362b053ef970ac391baed22293e279128be
PYTHON_PYYAML_INCLUDE_SETUP_TYPE = setuptools
PYTHON_PYYAML_INCLUDE_LICENSE = MIT-2.0

$(eval $(python-package))
$(eval $(host-python-package))

