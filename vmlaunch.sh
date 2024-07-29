#!/usr/bin/env bash
set -xe
dir=$(dirname "$0")

# Grab the helpers
source "$dir/helpers.sh"

# Parse the argument (VM ID)
vmid=$1
vmname=$(id_to_name "$vmid")
vmdir="$dir/$vmname"

# Grab the helpers
source "$dir/helpers.sh"

# Parse the argument (VM ID)
vmid=$1
vmname=$(id_to_name "$vmid")
vmdir="$dir/$vmname"

# Assign resources
case "$vmname" in
  gateway|control*)
    vcpus=2
    memory=2G
    ;;
  worker*)
    vcpus=4
    memory=4G
    ;;
esac

echo "$vmname will use $vcpus vcpus"

sudo qemu-system-aarch64 \
    -nographic \
    -machine virt,accel=tcg,highmem=on \
    -cpu cortex-a57 \
    -smp $vcpus \
    -m $memory \
    -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
    -netdev tap,id=net0,ifname=tap${vmid},script=no,downscript=no \
    -device e1000,netdev=net0,mac=52:52:52:00:00:0${vmid} \
    -hda ${vmname}/disk.img \
    -drive file=${vmname}/cidata.iso,driver=raw,if=virtio