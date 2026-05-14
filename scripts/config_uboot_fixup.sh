#!/bin/bash

# Variables section
config_path=${2}
dts_name=${1}
script=`realpath -s $0`
script_path=`dirname ${script}`
export CONFIG_="CONFIG_"
config_script="${script_path}/config.sh --file ${config_path}"

# Update configuration of the boards using NAND as a boot source
if [[ ${dts_name} == "armada-7040-db-D" ||
      ${dts_name} == "armada-7020-amc" ||
      ${dts_name} == "armada-8040-db-D" ||
      ${dts_name} == "cn9130-db-B" ||
      ${dts_name} == "cn9131-db-B" ||
      ${dts_name} == "cn9132-db-B" ]]; then
	${config_script} -d ENV_IS_IN_SPI_FLASH
	${config_script} -e ENV_IS_IN_NAND
	${config_script} -d MVEBU_SPI_BOOT
	${config_script} -e MVEBU_NAND_BOOT
fi
