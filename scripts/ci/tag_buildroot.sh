#!/bin/bash
# SPDX-License-Identifier:           BSD-3-Clause
# https://spdx.org/licenses
# Copyright (c) 2020 Marvell.
#
###############################################################################
## This is the compile script setting correct Buildroot base-version
## Called by TAG fragment with 1 explicit parameter %1 = 18 or 19 or 20
## Global exported parameters are br2_sdk_dir, br2_dir
###############################################################################

curr_dir=$PWD
bldr_bz2_18="$br2_sdk_dir/../buildrootS/sources-buildroot-2018.11.x-*.tar.bz2"
bldr_bz2_19="$br2_sdk_dir/../buildrootS/sources-buildroot-2019.11.x-*.tar.bz2"
bldr_bz2_20="$br2_sdk_dir/../buildrootS/sources-buildroot-2020.02.3-*.tar.bz2"
bldr_bz2_22="$br2_sdk_dir/../buildrootS/sources-buildroot-2022.02.3-*.tar.bz2"
bldr_bz2_24="$br2_sdk_dir/../buildrootS/sources-buildroot-2024.02.9-*.tar.bz2"
bldr_bz2=
ver_name18="_Buildroot-2018.11.x"
ver_name19="_Buildroot-2019.11.x"
ver_name20="_Buildroot-2020.02.3"
ver_name22="_Buildroot-2022.08.2"
ver_name24="_Buildroot-2024.02.9"
ver_req=
ver_curr=

if [[ "$1" != "18" && "$1" != "19" && "$1" !=  "20" && "$1" !=  "22" && "$1" !=  "24" ]]; then
  echo " Unknown Buildroot TAG <${1}>. Use either one of"
  echo "    18, 19 or 20     -- for buildroot-2018.11 or 2019.11 or 2020.11"
  exit 1
fi
ver_req=$1

if [[ ! -d ${br2_dir} ]]; then
  echo " No <${br2_dir}> directory found."
  echo " Please fix up and restart"
  exit 1
fi

cd $br2_dir
[[ -f $ver_name18 ]] && ver_curr="18"
[[ -f $ver_name19 ]] && ver_curr="19"
[[ -f $ver_name20 ]] && ver_curr="20"
[[ -f $ver_name22 ]] && ver_curr="22"
[[ -f $ver_name24 ]] && ver_curr="24"
if [[ ! $ver_curr ]]; then
  echo " $ver_curr   Cannot stat current buildroot version"; exit 1
fi

#------------------------------------------------------------------------------
cd $br2_sdk_dir/../

if [ $ver_curr == $ver_req ]; then
  echo " Buildroot already set as required" > /dev/null
else
# --- HANDLING -----
if [ -L $br2_dir ]; then
  # In IS_DEVEL: suppose buildroot points to existing buildroot18 or buildroot19
  rm $br2_dir
  if [ ! -d ${br2_dir}${ver_req} ]; then
    echo " Cannot find buildroot${ver_req} to swap to"
	exit 1
  fi
  ln -s buildroot${ver_req} buildroot
else
  # In either IS_RELEASE or IS_DEVEL
  rm -rf ${br2_dir}${ver_curr}
  mv ${br2_dir} ${br2_dir}${ver_curr}

  if [ -d ${br2_dir}${ver_req} ]; then
    cp -ra ${br2_dir}${ver_req} ${br2_dir}
  else
    #--- Untar from .bz2 creates <buildroot>
	ret=1
    [[ "$ver_req" == "18" ]] && bldr_bz2=$(ls -1 $bldr_bz2_18 2>/dev/null)
    [[ "$ver_req" == "19" ]] && bldr_bz2=$(ls -1 $bldr_bz2_19 2>/dev/null)
    [[ "$ver_req" == "20" ]] && bldr_bz2=$(ls -1 $bldr_bz2_20 2>/dev/null)
    if [[ ! $bldr_bz2 ]]; then
      echo " Cannot find buildroot-20${ver_req}*.tar.bz2"
      mv ${br2_dir}${ver_curr} ${br2_dir}
      exit 1
    fi
    tar xf $bldr_bz2
	ret=$?
    if [ "$ret" != "0" ]; then
	  echo "Untar $bldr_bz2 failed"; exit $ret
    fi
	#---
  fi
fi
fi ;# --- HANDLING -----

cd $curr_dir
