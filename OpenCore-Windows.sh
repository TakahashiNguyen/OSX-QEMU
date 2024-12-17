#!/usr/bin/env bash

# Special thanks to:
# https://github.com/Leoyzen/KVM-Opencore
# https://github.com/thenickdude/KVM-Opencore/
# https://github.com/qemu/qemu/blob/master/docs/usb2.txt
#
# qemu-img create -f qcow2 mac_hdd_ng.img 128G
#
# echo 1 > /sys/module/kvm/parameters/ignore_msrs (this is required)

###############################################################################
# NOTE: Tweak the "MY_OPTIONS" line in case you are having booting problems!
###############################################################################
#
# Change `Penryn` to `Haswell-noTSX` in OpenCore-Boot.sh file for macOS Sonoma!
#
###############################################################################


MY_OPTIONS="+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check"

# This script works for Big Sur, Catalina, Mojave, and High Sierra. Tested with
# macOS 10.15.6, macOS 10.14.6, and macOS 10.13.6.

ALLOCATED_RAM="8192" # MiB

REPO_PATH="."
OVMF_DIR="."

# shellcheck disable=SC2054
args=(
  # -enable-kvm 
  # -accel whpx
  -machine q35
  -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,"$MY_OPTIONS"
  -m "$ALLOCATED_RAM" 
  -device qemu-xhci,id=xhci
  -device ich9-intel-hda -device hda-duplex
  -device ich9-ahci,id=sata
  -device usb-kbd,bus=xhci.0 -device usb-tablet,bus=xhci.0
  -device usb-ehci,id=ehci
  -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
  -drive if=pflash,format=raw,readonly=on,file="$REPO_PATH/$OVMF_DIR/OVMF_CODE.fd"
  -drive if=pflash,format=raw,file="$REPO_PATH/$OVMF_DIR/OVMF_VARS.fd"
  -smbios type=2
  -device ide-hd,bus=sata.2,drive=OpenCoreBoot
  -device ide-hd,bus=sata.3,drive=InstallMedia
  -device ide-hd,bus=sata.4,drive=MacHDD
  -drive id=OpenCoreBoot,if=none,snapshot=on,format=qcow2,file="$REPO_PATH/OpenCore/OpenCore.qcow2"
  -drive id=InstallMedia,if=none,file="$REPO_PATH/BaseSystem.img",format=raw
  -drive id=MacHDD,if=none,file="$REPO_PATH/mac_hdd_ng.img",format=qcow2
  -netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=net0,id=net0,mac=52:54:00:c9:18:27
  -monitor stdio
  -device vmware-svga
)

qemu-system-x86_64.exe "${args[@]}"
