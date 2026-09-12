#!/bin/bash
# Travis CI builder
#
# Copyright 2018, Bingxing Wang. <uefi-oss-projects@imbushuo.net>
# All rights reserved.
#

#Cleanup if needed

if [ -e "Nexus5XPkg/ImageResources/Angler/uefi_angler.img" ]; then
    rm -f "Nexus5XPkg/ImageResources/Angler/uefi_angler.img"
fi

if [ -e "Nexus5XPkg/ImageResources/Bullhead/uefi_bullhead.img" ]; then
    rm -f "Nexus5XPkg/ImageResources/Bullhead/uefi_bullhead.img"
fi

echo "$(pwd)"

if [ -e "Nexus5XPkg/BootShim/BootShim.elf" ] || \
   [ -e "Nexus5XPkg/BootShim/BootShim.bin" ]; then
    echo "[Builder] Cleaning BootShim"
    make clean -C Nexus5XPkg/BootShim
fi



# Go to EDK2 workspace
cd ..
cd edk2

./Nexus5XPkg/Tools/CI/Builder/BuildAngler.sh
./Nexus5XPkg/Tools/CI/Builder/BuildBullhead.sh

# Check if we have both FD ready
if [ ! -f Build/Nexus5X-AARCH64/DEBUG_GCC5/FV/MSM8992_EFI.fd ]; then
    echo "Unable to find build artifacts."
    exit 1
fi
if [ ! -f Build/Nexus6P-AARCH64/DEBUG_GCC5/FV/MSM8994_EFI.fd ]; then
    echo "Unable to find build artifacts."
    exit 1
fi