This file explains how to use FIT (Flattened Image Tree) support
in build process to properly establish the secure boot of
kernel and rootfs

A FIT file (extension .itb) is basically a container designed to hold one or
more binary objects such as Linux kernels, root filesystems, device trees and
more.  Unlike other containers like tar or zip it also contains information
about the various blobs inside of it as well as how they are to be used.
This allows FIT images to be booted directly without the user needing to
specify kernel addresses and ramdisk addresses since this information is
contained within the FIT file.  Additionally, FIT files can contain
information to verify the integrity of its contents as well as authenticate
the contents.

U-Boot contains a number of documents describing the FIT under the
doc/uImage.FIT directory.  Also see $OCTEONTX_ROOT/bootloader/u-boot/README
for FIT options.

A few excellent overviews about FIT and its benefits and uses can be found at:

http://www.denx.de/wiki/pub/U-Boot/Documentation/multi_image_booting_scenarios.pdf

http://elinux.org/images/f/f4/Elc2013_Fernandes.pdf

https://www.youtube.com/watch?v=cVSEfOfb6rs

In its simplest case, a FIT image contains only one file such as a Linux
kernel that already has its ramdisk linked to it or a root filesystem.
More complex FIT files are also possible that contain separate kernels and
ramdisks or even multiple kernels and ramdisks.

FIT files are defined by a .its file.  The .its file follows the same format
as a device tree .dts file and in fact uses the same compiler underneath.

A FIT file is created using the U-Boot mkimage tool.  While it is possible to
create a FIT .itb file directly using mkimage, it is often easier to create
a .its source file that defines all of the parameters rather than try to pass
along a lot of command line parameters.

The .its file format is well documented in
${$OCTEONTX_ROOT}/bootloader/u-boot/doc/uImage.FIT/source_file_format.txt.

The man page for mkimage can be found in ${$OCTEONTX_ROOT}/fit/mkimage or by
man -c ${$OCTEONTX_ROOT}/bootloader/u-boot/doc/mkimage.1

Two documents which describe signing images and verified booting are
${$OCTEONTX_ROOT}/bootloader/u-boot/doc/uImage.FIT/signature.txt and
${$OCTEONTX_ROOT}/bootloader/u-boot/doc/uImage.FIT/verified-boot.txt.

When building a signed image it is recommended to use sha256,rsa2048 although
an alternative could be sha256,rsa4096.  Other hash algorithms and smaller
RSA signatures may not provide adequate security although they will be faster.

For signed images there are two parts.  The FIT image itself contains
signatures covering the images inside and the configuration and the Linux
device tree which is passed to U-Boot contains the public key and some
pre-computed values to make verifying the signature easier.

The build process can automatically insert a public key into the device tree
as well as build a .itb FIT image.

In order to do this, a FIT_DIR parameter must be passed.  This option is
used both for building the secure-uboot-build target as well as for building
the FIT image.

The directory must contain only a single .its file as well as a "keys"
subdirectory which must contain a single private key.  A public key will
automatically be generated from the private key during the build process.

The .its file has a field named "key-name-hint".  The value of this field
must match the name of the .key file in the keys subdirectory, without
the .key extension.  For example, if the key file is named "my_org.key"
then the .its file must contain key-name-hint = "my_org";

Note that the key-name-hint field is present in all of the signature sections
for the kernel(s), ramdisk(s) and configuration(s).  In the fit/default
directory, the default.its file uses the name "dev" for a "development" key.

The actual build process contains two parts.  The first part inserts the
public key into the linux device tree files and must be performed during
the process of building the secure U-Boot image.  This does not require
that the objects which will be placed inside the itb file be present.

To build a secure U-Boot image with support for signed FIT images use the
following command:

make secure-uboot-build PLAT=[t81|t83] FIT_DIR=fit/[directory]

This will insert the public key into all of the Linux .dtb files.

To create the .itb FIT image, use the following command:

make secure-fit PLAT=[t81|t83] FIT_DIR=fit/[directory]

The FIT_DIR directory does not need to be placed under the fit subdirectory
but this has been created for convenience.

There are several template .its files under fit/templates.  The fit/templates
directory SHOULD NOT be used as a target directory.  Here is a description of
some of the provided templates:

kernel.its will create an un-signed .itb file containing the Linux kernel with
its linked-in filesystem using the file created by running "make linux-kernel"
in the ${$OCTEONTX_ROOT} directory.

kernel-signed.its is the same as kernel.its except it contains one signature
for authenticating the kernel.

one-kernel-one-rootfs.its will create a signed FIT image containing one
kernel image and one compressed CPIO ramdisk image and one configuration.

one-kernel-two-rootfs.its will create a signed FIT image that contains one
kernel image and two compressed CPIO ramdisk images and two configurations.
This file must be edited in order to use two separate ramdisks so that it
points to two separate files.  Currently both ramdisks point to the same image.

one-rootfs.its only contains a root filesystem and no kernel.

Note that in the .its file there is a load and entry address.  For the kernel
this must be 0x40080000 for both entries.  The ramdisk load and entry addresses
must not overlap with where the kernel is loaded.  Typically an address is
chosen after the kernel load address which provides plenty of memory for the
kernel image.

============ U-Boot FIT commands ==============

Several commands are present in U-Boot in order to support FIT images.

BOARDNAME > iminfo [address]

This command will print out all of the information contained in a FIT image.
Additionally it will verfiy any hashes and signatures contained in the file.
If a hash succeeds, it will be followed by a +.  If it fails it will be
followed by a -.  The same goes for the signature.  If a signature passes a
+ will be appended after it.  If it fails it will have a - appended to it.

Here is the output from the iminfo command performed on the
fit/default/default.its itb file which was loaded at address 0x28000000:

BOARDNAME > iminfo 0x28000000

## Checking Image at 28000000 ...
   FIT image found
   FIT description: Image for Cavium OcteonTX with Linux Kernel and ramdisk
   Created:         2017-08-02   2:32:54 UTC
    Image 0 (kernel@1)
     Description:  Cavium OcteonTX/Thunder Linux Kernel
     Created:      2017-08-02   2:32:54 UTC
     Type:         Kernel Image
     Compression:  uncompressed
     Data Start:   0x28000100
     Data Size:    35670528 Bytes = 34 MiB
     Architecture: AArch64
     OS:           Linux
     Load Address: 0x40080000
     Entry Point:  0x40080000
     Hash algo:    sha256
     Hash value:   632008ef43afda507a814031384ae698ce7564474093703d894143c058877de0
     Sign algo:    sha256,rsa2048:dev
     Sign value:   3371210a8f27a6fbb215111021dd3a5d376765e87b0addc7287b2a542046a49838456227003f99762049a769f11cb5eb002db168b6
a49703f8ee8a2733931288675498640c69d4e87f56707728d9d23418cb35362d3f4f1345e1feb5e6220f502d157432f4bd5a2bb6f944d1a6cbb7207d6502a
fb7faabf8b6c9b1a7864fe0c4fd41e88f20c7317de52641908029179a98a42a4dc8382684e606dba2acd92f6e7db9e24c5076c936db8d82e7113299068837
bd622e28385500307c91072924cc9737576b000b08bcde3cecc4d37212e250f81dd799e7f7b59a4d36a16df8820724788e2f1b90352255740b7d40b4177cf
f283fe5e13521ea0c74de66f8bcbef3
     Timestamp:    2017-08-02   2:32:55 UTC
    Image 1 (ramdisk@1)
     Description:  Cavium OcteonTX/Thunder Linux ramdisk
     Created:      2017-08-02   2:32:54 UTC
     Type:         RAMDisk Image
     Compression:  gzip compressed
     Data Start:   0x2a204db0
     Data Size:    41212722 Bytes = 39.3 MiB
     Architecture: AArch64
     OS:           Linux
     Load Address: 0x48080000
     Entry Point:  0x48080000
     Hash algo:    sha256
     Hash value:   61dc3615a206bf31af7055a7a109163959792f1c4e29827bab73a4af9b65e73a
     Sign algo:    sha256,rsa2048:dev
     Sign value:   74f18fe32fe947d2b2f40777583a3e000c86f18f1059f7f803357b51dcf4d0d2bb37dc312220a6dc9f5bb640d3d7df7554e4ad9fc7
cedd8feb83bc63c66d52d15f6394239c2433a973538deb4e7e8b0019fdf961e810d840dcb6e16bf4c5be64d310a468b342dcab34dd99a4b008380f1c93293
7da8a6769d209e23e1f4157645cc3f258efa1fafb0599b6bcf4c4aee751008b44f077b9ae28cbaa5309476f7f60af7619e9923f978fbcf88dd24226043696
9298720895123b1e11e38981cc702d0b9a7aca2e152905a0e3b4b9ec43840227b825f69d633f4da81232588c1adb3e9d5715b919efb2ece06ee182e3ba128
18e3e44e55ae38a2c4d8c17a950f0b6
     Timestamp:    2017-08-02   2:32:55 UTC
    Default Configuration: 'config@1'
    Configuration 0 (config@1)
     Description:  OcteonTX/Thunder Linux configuration
     Kernel:       kernel@1
     Init Ramdisk: ramdisk@1
## Checking hash(es) for FIT Image at 28000000 ...
   Hash(es) for Image 0 (kernel@1): sha256+ sha256,rsa2048:dev+
   Hash(es) for Image 1 (ramdisk@1): sha256+ sha256,rsa2048:dev+

The imxtract command will extract an image from inside the .itb file.

For example, to extract the kernel from the file generated from default.its
(target/images/fit-image-dev.itb) to the kernel address the following
command would be used:

BOARDNAME > imxtract 0x28000000 kernel@1 $kernel_addr

To boot an image, the bootm command is used.  For the bootm command, it
is possible to specify which configuration will be used.  If no configuration
is specified then the default configuration will be used.

For example, to boot config@1 in fit-default-dev.itb with the image loaded
at address 0x28000000 the following command is used:

BOARDNAME > bootm 0x28000000#config@1 - $fdtcontroladdr

The bootm command can also be broken down into multiple steps by using
sub-commands.

In this case the following sequence of commands would be used:

BOARDNAME > bootm start 0x28000000#config@1 - $fdtcontroladdr
BOARDNAME > bootm loados
BOARDNAME > bootm ramdisk
BOARDNAME > bootm fdt
BOARDNAME > bootm prep
BOARDNAME > bootm go

Note that the "bootm cmdline" and "bootm bdt" sub-commands are not supported for
AARCH64.

FIT images are also supported by commands like usbboot, nandboot and other
boot commands.

Additionally, the fdt checksign command can check the fit signature.

A sequence of commands can also be stored in a FIT image for use with the
source command.

If the kernel and root filesystem are separate then the following bootm
command would be used:

BOARDNAME > tftpboot 0x28000000 one-kernel-one-rootfs.itb
BOARDNAME > tftpboot 0x30000000 one-rootfs.itb

BOARDNAME > bootm 0x28000000:kernel@1 0x30000000 $fdtcontroladdr

In the above command while the first itb image contains both a kernel and a
ramdisk we are telling bootm to only use the kernel part by using :kernel@1.
For the second parameter, the configuration is not needed since it will use
the default configuration.  The output of the command shows which sub-images
are actually used.  In this case, only the kernel from one-kernel-one-rootfs
is used and the ramdisk from one-rootfs is used.

============ Custom Verification Code ==============

For custom use of FIT images in U-Boot for booting or verification the
functions in common/image-fit.c are available.  To verify the integrity of
a signed FIT image the function fit_all_image_verify() will return if
the image is valid or not.  To reboot if the image is not valid, the following
code will work:

if (!fit_all_image_verify(fit_ptr))
	do_reset(NULL, 0, 0, NULL);

Note that FIT itb images must be located at an address other than the
kernel and/or ramdisk address so that they do not overlap.  With the
default kernel load address of 0x48080000 an address of 0x28000000 or
0x50000000 will work for loading the images.  Images can also be stored
in NOR flash and directly accessed.

To get a pointer to the image(s) contained inside a FIT image see
fit_image_print() for an example which uses fit_image_get_data().

To obtain the node offset within the FIT for a particular image the function
fit_image_get_node(const void *fit, const char *image_name) will return the
offset of the image matching image_name.

For example, to get a pointer to the image "ramdisk@1" inside a FIT .itb image:

const void *get_ramdisk_data(const char *image_name,
			     const void **data, size_t *data_size)
{
	int ret = -1;
	int node_offset;

	node_offset = fit_image_get_node(fit_ptr, image_name);
	if (node_offset < 0)
		printf("Image %s not found in FIT image.\n", image_name);
	else
		ret = fit_image_get_data(fit_ptr, node_offset, data, data_size);

	return ret;
}

ret = get_ramdisk_data("ramdisk@1", &data_ptr, &data_size);

At this point, data_ptr will point to the ramdisk image and data_size will
contain the size of the data.
