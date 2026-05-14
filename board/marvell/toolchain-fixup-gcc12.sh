#!/bin/sh
STAGING_DIR=$1
TOOLCHAIN_EXTERNAL_PATH=$2
rm -rf ${STAGING_DIR}/usr/lib/ld-linux-aarch64.so.1
if [ -e ${HOST_DIR}/opt/ext-toolchain/aarch64-marvell-linux-gnu/sys-root/lib/ld-linux-aarch64.so.1 ]; then
cp -f ${HOST_DIR}/opt/ext-toolchain/aarch64-marvell-linux-gnu/sys-root/lib/ld-linux-aarch64.so.1 ${STAGING_DIR}/usr/lib/ld-linux-aarch64.so.1
fi


if [ -e ${TOOLCHAIN_EXTERNAL_PATH}/aarch64-marvell-linux-gnu/sys-root/lib/ld-linux-aarch64.so.1 ]; then
cp -f ${TOOLCHAIN_EXTERNAL_PATH}/aarch64-marvell-linux-gnu/sys-root/lib/ld-linux-aarch64.so.1 ${STAGING_DIR}/usr/lib/ld-linux-aarch64.so.1
fi

