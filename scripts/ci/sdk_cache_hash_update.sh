#!/bin/bash
# SPDX-License-Identifier:           BSD-3-Clause
# https://spdx.org/licenses
# Copyright (c) 2018 Marvell.
#
###############################################################################
#
# This script generates the hash to be used for sdk-cache <ID> in cache name.
#
# An old sdk-cache may be used instead of new cache building if "cache-package"
# But the cache must be re-new/re-build if either from below condition present:
#  - A "buildroot" change applied directly in the buildroot directory
#  - A "buildroot" change applied over patch present in any MV-SDK directory
#  - Mainline package list (f_pkg_mainline) is changed in defconfig
# To fix this constraint the sdk-cache file-name is mangled with hash-code
# generated as CRC of defconfig.
# This covers automatically the f_pkg_mainlie change but not other 2 cases.
# Addding an additional hash into the defconfig would fix.
#
# This script should be re-triggered *MANUALLY* by a developer every time
# the <./buildroot> TOP hash changed.
# The resulting <sdk_cache_hash> file to be saved on git.
#

WRK_DIR=`dirname $0`
cd $WRK_DIR/../.. > /dev/null
    WRK_DIR=${PWD}
cd - > /dev/null
ROOT_DIR=${WRK_DIR}/..
br2_main_dir=${br2_main_dir:-"${ROOT_DIR}/buildroot"}

HASH="# <./buildroot> TOP HASH: "
cd $br2_main_dir > /dev/null
HASH+=$(git log --pretty=format:%h -n1)
cd - > /dev/null
HASH+=" "
HASH+=$(date)

echo $HASH > $(dirname $0)/sdk_cache_hash
echo $(dirname $0)/sdk_cache_hash updated with
echo "   $(cat $(dirname $0)/sdk_cache_hash)"
