# EDK2 UEFI Implementation for Lumia 950 and Lumia 950 XL

## What's this?

This package demonstrates an AArch64 UEFI implementation for Bootloader unlocked Nexus 6P and Nexus 5X. Currently it is able to boot Windows 10 ARM64 as well as various Linux distros. See notes below for more details. Please be aware that MSM8992 devices have limited support.


## Support Status
Applicable to all supported targets unless noted.

- Low-speed I/O: I2C, SPI, GPIO, SPMI and Pinmux (TLMM).
- Power Management: PMIC and Resource Power Manager (RPM).
- High-speed I/O for firmware and HLOS: eMMC (SDR50 in firmware, HS200/HS400 in OS) PCI Express (Firmware-configured, HLOS Only, x2 Lane)
- Peripherals: Touchscreen (QUP I2C), side-band buttons (TLMM GPIO and PMIC GPIO) and Lattice UC120 (iCE5LP2K) FPGA configuration
- Display FrameBuffer depends on stock Qualcomm UEFI for boostrapping, MDP is not fully implemented.


## Build

cd edk2

./Nexus5XPkg/Tools/CI/Bootstrapper/Stage0.sh
./Nexus5XPkg/Tools/CI/Bootstrapper/Stage1.sh

./Nexus5XPkg/Tools/CI/Builder/Build.sh for all targets
./Nexus5XPkg/Tools/CI/Builder/BuildAngler.sh for Nexus 6P
./Nexus5XPkg/Tools/CI/Builder/BuildBullhead.sh for Nexus 5X

For Production Builds you want to invoke the runbuild script manually

./Nexus5XPkg/Tools/runbuild.sh --device Angler --production for Nexus 6P
./Nexus5XPkg/Tools/runbuild.sh --device Bullhead --production for Nexus 5X

## Run

fastboot boot uefi_angler.img for Nexus 6P
fastboot boot uefi_bullhead.img for Nexus 5X

## TZ Implementation Notes

Qualcomm Snapdragon MSM8992/MSM8994 implements a subset of [PSCI interface](http://infocenter.arm.com/help//topic/com.arm.doc.den0022d/Power_State_Coordination_Interface_PDD_v1_1_DEN0022D.pdf) for multi-processor startup. However, required
commands like `PSCI_SYSTEM_OFF` and `PSCI_SYSTEM_RESET` are not implemented. Hence we use PMIC to shutdown
platform (there's a bug in RT that will be fixed) instead of PSCI. Additionally, 8992/8994 uses HVC call for
PSCI commands instead of SMC call.

## Linux Notes

The ACPI tables are copied from stock Windows Phone FFU, hence these device IDs are likely not be recognized by Linux.

To get started, starts with the device tree of Qualcomm MSM8994 MTP. The repository `devicetree-rebasing` with 
DT content from Android Linux Kernel is sufficient for DT development. To boot with device tree, add it in your
GRUB configuration:
	
	devicetree /lumia-950-xl.dtb
	linux /vmlinuz ..... acpi=no

PSCI partially works in EL1. If you want to use PSCI for multi-processor startup, add the following code to your DT:

	psci {
		compatible	= "arm,psci-0.2";
		method		= "hvc";
	};

And use `psci` for core-enable method. If you are using EL2 startup, use `spin-table` with `per_cpu_mailbox_addr + 0x8` as the release address.

For MSM8994, PCI Express Root Port 1 is **firmware-initialized**. Similarly, MSM8992 have PCI Express Root Port 0 initialized. Hence it is not necessary to supply `qcom,pcie` in device tree. Instead, supply a firmware-initialized PCI bus device `pci-host-ecam-generic`. ACPI MCFG table is supplied for your reference.

Note: interrupt is not configured in the example below (therefore ath10k will crash the system if loaded.)

	pci@f8800000 {
		compatible = "pci-host-ecam-generic";
		device_type = "pci";
		#address-cells = <0x3>;
		#size-cells = <0x2>;
		bus-range = <0x0 0x1>;
		#interrupt-cells = <0x1>;

		reg = <0xf8800000 0x200000>;
		ranges = <0x02000000 0x0 0xf8a00000 0xf8a00000 0x0 0x600000>;

		status = "okay";
	};

## Acknowledgements

- [EFIDroid Project](http://efidroid.org)
- Andrei Warkentin and his [RaspberryPiPkg](https://github.com/andreiw/RaspberryPiPkg)
- Sarah Purohit
- [Googulator](https://github.com/Googulator/)

## License

All code except drivers in `GPLDriver` directory are licensed under BSD 2-Clause. 
GPL Drivers are licensed under GPLv2 license.
