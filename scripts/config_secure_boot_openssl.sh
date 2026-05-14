#/bin/bash

tfw_nv_count=0
ntfw_nv_count=0

pin_value=userpin
token=Token-1
serial=b234ba7184138594

# uncomment one of these to encrypt image
# ssk=0123456789abcdef0123456789abcdef
# huk=0123456789abcdef0123456789abcdef

OPENSSL_HSM_DIR=/home/amakarov/marvell/softhsm
SSL_HSM_INSTALL_DIR=$OPENSSL_HSM_DIR/ssl
SOFTHSM2_CONF=$SSL_HSM_INSTALL_DIR/etc/softhsm2.conf
PKCS11_MODULE_PATH=$SSL_HSM_INSTALL_DIR/lib/softhsm/libsofthsm2.so

function make_key_reference() {
    local key=$1
    echo "pkcs11:serial=${serial};token=${token};object=${key};pin-value=${pin_value}"
}

# -------------------------------------------------

self_dir_path=$(dirname ${BASH_SOURCE[0]})
config_file=$(realpath "$self_dir_path/../../cn96xx-devel-output/.config")
config_script=$(realpath "$self_dir_path/config.sh")

# -------------------------------------------------

# debug
# echo "self_dir_path: $self_dir_path"
# echo "config_file: $config_file"
# echo "config_script: $config_script"
# set -x

# -------------------------------------------------

function config_enable() {
    local option_name=$1

    "$config_script" --file "$config_file" --enable $option_name
}

function config_append_string() {
    local option_name=$1
    local string_to_append=$2

    local string_orig=$("$config_script" --file "$config_file" --state $option_name)
    "$config_script" --file "$config_file" --set-str $option_name "$string_orig $string_to_append"
}

function config_set() {
    local option_name=$1
    local value_to_set=$2

    "$config_script" --file "$config_file" --set-val $option_name "$value_to_set"
}


function config_set_string() {
    local option_name=$1
    local string_to_set=$2

    "$config_script" --file "$config_file" --set-str $option_name "$string_to_set"
}

# -------------------------------------------------

config_enable        PACKAGE_MBEDTLS
config_enable        PACKAGE_MBEDTLS_CUSTOM_GIT
config_set_string    PACKAGE_MBEDTLS_CUSTOM_GIT_REPO_URL 'ssh://sj1git1.cavium.com:29418/IP/SW/boot/mbedtls'
config_set_string    PACKAGE_MBEDTLS_CUSTOM_GIT_REPO_VERSION 'mbedtls-devel'
config_enable        PACKAGE_MBEDTLS_INSTALL_SOURCES_STAGING
config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_ENVIRONMENT 'MBEDTLS_DIR=$(STAGING_DIR)/usr/share/mbedtls'
config_set_string    TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_DEPENDENCIES 'mbedtls'

config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_ENVIRONMENT "SSL_HSM_INSTALL_DIR=$SSL_HSM_INSTALL_DIR"
config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_ENVIRONMENT "SOFTHSM2_CONF=$SOFTHSM2_CONF"
config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_ENVIRONMENT "PKCS11_MODULE_PATH=$PKCS11_MODULE_PATH"

config_enable        TARGET_MARVELL_BDK_SECURE_BOOT
config_enable        TARGET_MARVELL_BDK_OPENSSL

config_set_string    TARGET_MARVELL_BDK_KEY_ROT   "$(make_key_reference rot)"
config_set_string    TARGET_MARVELL_BDK_KEY_BL31  "$(make_key_reference bl31_key)"
config_set_string    TARGET_MARVELL_BDK_KEY_TW    "$(make_key_reference tw)"
config_set_string    TARGET_MARVELL_BDK_KEY_NTW   "$(make_key_reference ntw)"
config_set_string    TARGET_MARVELL_BDK_KEY_UBOOT "$(make_key_reference uboot_key)"
config_set_string    TARGET_MARVELL_BDK_KEY_BDK   "$(make_key_reference bdk_key)"

config_set_string    TARGET_MARVELL_BDK_SSL_HSM_INSTALL_PATH "$SSL_HSM_INSTALL_DIR"
config_set_string    TARGET_MARVELL_BDK_SOFTHSM2_CONF_PATH "$SOFTHSM2_CONF"
config_set_string    TARGET_MARVELL_BDK_PKCS11_MODULE_PATH "$PKCS11_MODULE_PATH"

config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES 'TRUSTED_BOARD_BOOT=1 GENERATE_COT=1 ARM_ROTPK_LOCATION=regs'

config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES 'OPENSSL_ENGINE=pkcs11'
config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES 'CREATE_KEYS=0'

config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES "ROT_KEY=\'$(make_key_reference rot)\'"
config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES "BL31_KEY=\'$(make_key_reference bl31_key)\'"
config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES "TRUSTED_WORLD_KEY=\'$(make_key_reference tw)\'"
config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES "NON_TRUSTED_WORLD_KEY=\'$(make_key_reference ntw)\'"
config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES "BL33_KEY=\'$(make_key_reference uboot_key)\'"

config_enable        TARGET_ARM_TRUSTED_FIRMWARE_UBOOT_AS_BL33
config_set_string    TARGET_ARM_TRUSTED_FIRMWARE_UBOOT_IMAGE_NAME 'u-boot-nodtb.bin'

# -------------------------------------------------

config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES "TFW_NVCTR_VAL=$tfw_nv_count NTFW_NVCTR_VAL=$ntfw_nv_count"
config_set           TARGET_MARVELL_BDK_TFW_NV_COUNT $tfw_nv_count
config_set           TARGET_MARVELL_BDK_NTFW_NV_COUNT $ntfw_nv_count

# -------------------------------------------------

if [ ! -z "$ssk$huk" ] ; then

    config_append_string TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES 'CIPHER_TYPE=aes-128-cbc'
    config_enable        TARGET_ARM_TRUSTED_FIRMWARE_INSTALL_CERT_CREATE

    if [ ! -z "$ssk" ] ; then

        config_enable     TARGET_MARVELL_BDK_ENCRYPT_SSK
        config_set_string TARGET_MARVELL_BDK_SSK_KEY "$ssk"

    elif [ ! -z "$huk" ] ; then

        config_enable     TARGET_MARVELL_BDK_ENCRYPT_HUK
        config_set_string TARGET_MARVELL_BDK_HUK_KEY "$huk"
    fi

fi
