#!/bin/bash
# SPDX-License-Identifier:           BSD-3-Clause
# https://spdx.org/licenses
# Copyright (c) 2018 Marvell.
#
###############################################################################
## Clean-up all Marvell packages in buildroot/dl (DownLoad) and in
##  output/build    if called without parameter or
##      $1/build

CURR_DIR=${PWD}
WRK_DIR=`dirname $0`
cd $WRK_DIR/../../..
    ROOT_DIR=${PWD}
cd -
br2_main_dir=${br2_main_dir:-"${ROOT_DIR}/buildroot"}

if [ "$1" == "" ]; then
  if [ -e ${ROOT_DIR}/output ]; then
    br2_out_dir=${ROOT_DIR}/output
  else
    echo "   Clean-Error: path to *output directory should be given"
    echo "   Only clean for buildroot/dl will be done"
  fi
else
  br2_out_dir=$1
fi
if [ ! -e ${br2_out_dir} ]; then
  echo "   Clean-Error: output directory not found <${br2_out_dir}>"
  echo "   Only clean for buildroot/dl will be done"
fi

cd ${ROOT_DIR}/buildroot/dl/
rm -rf      dpdk*      odp*      net*agent* nwa*      pcie*      mv*      marv*      mrvl*      musdk*      txcsr*      spdk*      libtmc*
rm -rf      *octeon*      *otx*
rm -rf uboot* arm-trust* opte* binaries-marvell* marvell*
rm -rf linux
rm -rf pport*
rm -rf umsd* cpss*
rm -rf *6wind* ipfp
rm -rf cpt-microcode
rm -rf mux_lag

cd ${br2_out_dir}/build/
rm -rf host-dpdk* host-odp* host-net*agent*      host-pcie* host-mv* host-marv* host-mrvl* host-musdk* host-txcsr*
rm -rf      dpdk*      odp*      net*agent* nwa*      pcie*      mv*      marv*      mrvl*      musdk*      txcsr*      spdk*      libtmc*
rm -rf host-*octeon* host-*otx*
rm -rf      *octeon*      *otx*
rm -rf uboot* arm-trust* opte* binaries-marvell* marvell*
rm -rf linux-linux*
rm -rf pport* host-pport*
rm -rf umsd* cpss*
rm -rf *6win* ipfp*
rm -rf openssl* host-openssl*
rm -rf cpt-microcode*
rm -rf mux_lag*

cd ${br2_out_dir}/target/
find -name marvell | xargs rm -rf
cd ${br2_out_dir}/staging/
find -name marvell | xargs rm -rf

rm -rf cd ${br2_out_dir}/images
