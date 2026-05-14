#!/usr/bin/env bash

# Instal script updating Per-Platform kernel-modules and lib
# before starting the S40network
if [[ "$BR2_INIT_SYSTEMD" != "y" ]]; then
	install -D -m 0755 "${BR2_EXTERNAL_MARVELL_SDK_PATH}/board/marvell/platform.sh" \
		"${TARGET_DIR}/etc/init.d/S38platform"
fi

