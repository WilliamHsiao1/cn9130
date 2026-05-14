################################################################################
#
# zephyr
#
################################################################################

HOST_ZEPHYR_VERSION = 0.16.5

HOST_ZEPHYR_SOURCE = zephyr-sdk-$(HOST_ZEPHYR_VERSION)_linux-x86_64.tar.xz
HOST_ZEPHYR_SITE = https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v$(HOST_ZEPHYR_VERSION)

BR_NO_CHECK_HASH_FOR += $(HOST_ZEPHYR_SOURCE)


#'https://github.com/zephyrproject-rtos/sdk-ng/releases/download/0.16.5/zephyr-sdk-0.16.5_linux-x86_64.tar.xz'

HOST_ZEPHYR_DEPENDENCIES = host-python-west
HOST_ZEPHYR_INSTALL_STAGING = YES

define HOST_ZEPHYR_BUILD_CMDS
	unset ZEPHYR_BASE
	mkdir -p $(HOST_DIR)/bin/zephyr
	cp -r $(@D)/* $(HOST_DIR)/bin/zephyr
	$(TARGET_MAKE_ENV) cd $(HOST_DIR)/bin/zephyr && yes | ./setup.sh
endef


$(eval $(host-generic-package))
