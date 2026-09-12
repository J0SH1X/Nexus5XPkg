#!/bin/bash
# Travis CI builder
#
# Copyright 2018, Bingxing Wang. <uefi-oss-projects@imbushuo.net>
# Copyright 2026 Aljoshua Hell <aljoshua.hell@gmail.com>
# All rights reserved.
#

#Cleanup if needed
if [ -e "Nexus5XPkg/ImageResources/H815/uefi_h815.img" ]; then
    rm -f "Nexus5XPkg/ImageResources/H815/uefi_h815.img"
fi

# Start build
echo "Start build..."
. Nexus5XPkg/Tools/runbuild.sh --device h815 --development

# Check if we have both FD ready
if [ ! -f Build/LGG4-AARCH64/DEBUG_GCC5/FV/MSM8994_EFI.fd ]; then
    echo "Unable to find build artifacts."
    exit 1
fi

# Nexus 6P
./Nexus5XPkg/Tools/CI/Builder/build_boot_shim.sh
cat ./Nexus5XPkg/BootShim/BootShim.bin ./Build/LGG4-AARCH64/DEBUG_GCC5/FV/MSM8994_EFI.fd > ./Build/LGG4-AARCH64/DEBUG_GCC5/FV/BootShimMSM8994_EFI.fd

gzip -c < ./Build/LGG4-AARCH64/DEBUG_GCC5/FV/BootShimMSM8994_EFI.fd >./Build/LGG4-AARCH64/DEBUG_GCC5/FV/BootShimMSM8994_EFI.fd.gz

# lge needs --dt support in mkbootimg.py
python ./Nexus5XPkg/ImageResources/LGE/mkbootimg/mkbootimg.py --kernel ./Build/LGG4-AARCH64/DEBUG_GCC5/FV/Image.gz-dtb --dt ./Nexus5XPkg/ImageResources/H815/msm8992-lge-h815-dt.img --ramdisk ./Nexus5XPkg/ImageResources/ramdisk-null --base 0x00000000 --pagesize 4096 --ramdisk_offset 0x02000000 --tags_offset 0x01e00000 -o ./Nexus5XPkg/ImageResources/H815/uefi_h815.img

