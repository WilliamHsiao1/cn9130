#!/usr/bin/env bash

cp "${BR2_EXTERNAL_MARVELL_SDK_PATH}/board/marvell/uEnv.txt" "${BINARIES_DIR}/uEnv.txt"

# Generate fit image
if [[ "${FW_CREATE_FIT}" == "y" ]] ; then
    echo "FIT option is enabled in buildroot. Start FIT image process"
    FW_FIT_DIR=$(echo "$FW_FIT_DIR" | tr -d '"')
    echo $FW_FIT_DIR
    echo $FW_CREATE_FIT
    KEY_NAME=$(find "$FW_FIT_DIR/default/keys" -name '*.key')
    KEY_BASENAME=$(basename "$KEY_NAME" .key)
    CERT_NAME="$FW_FIT_DIR/default/keys/$KEY_BASENAME.crt"

    echo "Generate FIT image only with Kernel"
    awk '{sub("dummy-dir","'$BINARIES_DIR'")}1' $FW_FIT_DIR/dummy/default.its > $FW_FIT_DIR/dummy/default-tmp.its
    cp $BINARIES_DIR/Image $FW_FIT_DIR/dummy/
    sed -i 's/"dummy.bin"/"Image"/g' $FW_FIT_DIR/dummy/default-tmp.its
    mkimage -k "$FW_FIT_DIR/default/keys" -f "$FW_FIT_DIR"/dummy/default-tmp.its "$BINARIES_DIR/fit-image-$KEY_BASENAME.itb"

#Generate fit image with kernel & busybox file system
    echo "FIT Image with minimal file system"
    awk '{sub("dummy-dir","'$BINARIES_DIR'")}1' $FW_FIT_DIR/dummy/default-rfs.its > $FW_FIT_DIR/dummy/default-rfs-tmp.its
    sed -i 's/"dummy.bin"/"Image"/g' $FW_FIT_DIR/dummy/default-rfs-tmp.its
    sed -i 's/"dummy.rootfs.cpio.gz"/"rootfs.cpio.gz"/g' $FW_FIT_DIR/dummy/default-rfs-tmp.its
    mkimage -k "$FW_FIT_DIR/default/keys" -f "$FW_FIT_DIR"/dummy/default-rfs-tmp.its "$BINARIES_DIR/fit-image-rfs.itb"

    rm -f $FW_FIT_DIR/default/default-tmp.its
    rm -f $FW_FIT_DIR/default/default-rfs-tmp.its
    rm -f $FW_FIT_DIR/dummy/Image
    echo "Generated FIT image successfully"
fi

GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
MARVELL_SOC_FAMILY="${2}"
echo "${MARVELL_SOC_FAMILY}"
rm -rf "${GENIMAGE_TMP}"

if [[ ( "${MARVELL_SOC_FAMILY}" == "CN10K" ) || ( "${MARVELL_SOC_FAMILY}" == "CN20K" ) ]] ; then
    GENIMAGE_CFG="${BR2_EXTERNAL_MARVELL_SDK_PATH}/board/marvell/genimage.cfg"
    echo "**Config ${GENIMAGE_CFG} ${MARVELL_SOC_FAMILY}"
else
    GENIMAGE_CFG="${BR2_EXTERNAL_MARVELL_SDK_PATH}/board/marvell/genimage_no_fw.cfg"
    echo "**Config ${GENIMAGE_CFG} ${MARVELL_SOC_FAMILY}"
fi

# Increase size of boot.vfat if Image is larger than default size (50M)
IMAGE_SIZE="$(du -m ${BINARIES_DIR}/Image | awk '{print $1}')"
if [[ "${IMAGE_SIZE}" -ge "50" ]]; then
    GENIMAGE_CFG_BIG="${GENIMAGE_CFG}.big"
    cp ${GENIMAGE_CFG} ${GENIMAGE_CFG_BIG}
    sed -i "s/50M/$((IMAGE_SIZE+10))M/g" ${GENIMAGE_CFG_BIG}
    GENIMAGE_CFG="${GENIMAGE_CFG_BIG}"
fi

genimage \
  --rootpath "${TARGET_DIR}" \
  --tmppath "${GENIMAGE_TMP}" \
  --inputpath "${BINARIES_DIR}" \
  --outputpath "${BINARIES_DIR}" \
  --config "${GENIMAGE_CFG}"

if [ $? -ne 0 ] ; then
    echo "post-image.sh: genimage error"
    exit ${RET}
fi

# Remove ext2 images, as they can be generated from rootfs.tar file.
# The script below will be generated in the board/marvell/binaries
# directory so ext2 image can be generated automatically if needed.
rm -f ${BINARIES_DIR}/*.ext*
cat <<-EOF! > ${BINARIES_DIR}/gen_ext_image.sh
    #!/bin/bash
    #The scripts accept the rootfs tar name as a parameter. If not provided
    #it will use rootfs.tar by default.

    if [ "\$EUID" -ne 0 ] ; then
        echo "This script must run as sudo \$(id)"
        exit 0
    fi
    rm -f *.ext*
    IMAGE_FILE=rootfs.ext2
    fallocate -l 2G /tmp/\$IMAGE_FILE
    mkfs.ext4 /tmp/\$IMAGE_FILE
    mkdir -p tmp/
    mount -o loop /tmp/\$IMAGE_FILE tmp
    tar -xf \${1:-rootfs.tar} -C tmp
    umount tmp
    mv /tmp/\$IMAGE_FILE .
    rm -rf tmp
    file \$IMAGE_FILE
EOF!

