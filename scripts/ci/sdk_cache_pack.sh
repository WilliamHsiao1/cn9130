#!/bin/bash
# SPDX-License-Identifier:           BSD-3-Clause
# https://spdx.org/licenses
# Copyright (c) 2018 Marvell.
#
###############################################################################
# sdk_cache_pack.sh script creates "cache" tar of
#   <output> and <build/dl> directories created by build mv_sdk_*_defconfig
# without Kernel, Boot/Uboot and any Marvell package and used for further
# NOT requires any parameter but always works with default <output> directory.
#
# Most of Buildroot components/packages are not changed for build-variants
# but their Download & Build takes ~70% of whole build time.
# This process may be optimized by SDK-CACHE with CREATE and USE steps.
#
# CREATE cache:
# ------------
# Depending upon required SoC-family (gcc-mcpu) there are 3 caches:
# - BR2_cortex_a53 for _armada3k_
# - BR2_cortex_a72 for _armada_
# - BR2_thunderx   for octeonTX/TX2
# The SoC-family is set by build itself according to the Build-Variant
# and passed into this script for correct file-name creation over parameter $1
#
# It is built with only TOOLCHAIN and all non-marvell packages but without
#   boot/uboot/bdk/atf, Kernel and mv-packages.
# Buldroot uses Absolute-path. For sdk-cache reusing it is built into shared
#   directory with fixed/default name <output> (same as -d option).
# File (files) output/.build.bldVar_devel_defconfig (or **_release_defconfig)
#   are created to see which build or incrementally added builds are built into
#   <output> directory.
# For successful builds these files contain the start/end time.
#
# Finally, the cache-zip <sdk-base/../sdk_cache<-SoC-ID>.tar.gz> is
# created (by ci/sdk_cache_pack.sh) containing two directories:
#    output and build/dl
#
# USE:
#    cp  "path"/sdk_cache<-SoC-ID>.tar.gz  sdk-base/../
#    cd sdk-base/../
#    tar xf ./sdk_cache<-SoC-ID>.tar.gz
#
# NOTE:
#  Full Cache portability requires the shared <output> but also
#  the build in Mount-namespace (-mnt) environment.

#------------------------------------------------------
# sdk_cache_zip_used= "" or true is exported by caller
#------------------------------------------------------

WRK_DIR=`dirname $0`
cd $WRK_DIR/../..
    WRK_DIR=${PWD}
cd -
ROOT_DIR=${WRK_DIR}/..
br2_sdk_dir=${WRK_DIR}
br2_main_dir=${br2_main_dir:-"${ROOT_DIR}/buildroot"}
br2_out_dir=${br2_out_dir:-"${ROOT_DIR}/output"}

if [ ! -e ${br2_out_dir} ]; then
  echo "   No output directory found. Cannot pack SDK-CACHE"
  exit 1
fi
if [ ! -e ${br2_main_dir}/dl ]; then
  echo "   No buildroot/dl directory found. Cannot pack SDK-CACHE"
  exit 1
fi

# Strip files not needed for the cache
rm -f ${br2_out_dir}/images/rootfs*

# Must strip for proper make-menuconfig
find ${br2_out_dir}/build/buildroot-config/ -name "*.o" | xargs rm -rf

# Must strip to force re-compile on cache-using
rm -rf ${br2_out_dir}/build/openssl

#-- Build new cache-ID, delete old IDs -----------------------------------
if [ $sdk_cache_zip_used ]; then
  f_ext=".tar.gz"
else
  f_ext=".tar"
fi

soc_family=$1
config_fpath=$2
if [[ $soc_family == "" ]]; then
  file_name="sdk_cache"
else
  config_tmp=${br2_out_dir}/sdk_cache_config.tmp
  cp ${config_fpath} ${config_tmp}
  ${br2_sdk_dir}/scripts/config.sh --file ${config_tmp} --set-str MARVELL_RELEASE_ID "cache"
  config_id=$(crc32 ${config_tmp} 2>/dev/null)
  file_name="sdk_cache-"${soc_family}-${config_id}
  mv ${br2_out_dir}/images/cache_* ${br2_out_dir}/images/"sdk_cache-"${soc_family}-${config_id}_defconfig
fi
echo "   Packing <${file_name}> takes several minutes..."

rm -f ${br2_out_dir}/../sdk_cache-${soc_family}-*.tar*
if [ $sdk_cache_zip_used ]; then
  tar -zcf ${br2_out_dir}/../${file_name}.dl${f_ext}  ${br2_main_dir}/dl
  tar -zcf ${br2_out_dir}/../${file_name}.out${f_ext} ${br2_out_dir}
else
  tar -cf  ${br2_out_dir}/../${file_name}.dl${f_ext}  ${br2_main_dir}/dl
  tar -cf  ${br2_out_dir}/../${file_name}.out${f_ext} ${br2_out_dir}
fi

