#!/usr/bin/env bash
set -xe

# Grab the helpers
source "$(dirname "$0")/helpers.sh"

# Parse the argument and set global variables
function parse_arguments() {
  export vmid=$1
  export vmname=$(id_to_name $vmid)
  vmdir="$(dirname "$0")/$vmname"
}

# Strip the number off VM name, leaving only VM "type"
function get_vmtype() {
  vmtype=${vmname%%[0-9]*}
  echo $vmtype
}

# Ensure the cloud-init and VM directories exist
function create_directories() {
  mkdir -p "$(dirname "$0")/cloud-init"
  mkdir -p "$vmdir"
}

# Create user-data files for each VM type if they do not already exist
function create_user_data_files() {
  for vmtype in gateway control worker; do
    userdata_file="$(dirname "$0")/cloud-init/user-data.$vmtype"
    cat <<EOF >"$userdata_file"
#cloud-config
ssh_authorized_keys:
  - $(<~/.ssh/id_rsa.pub)

packages:
  - curl
package_update: true
package_upgrade: true
package_reboot_if_required: false
EOF
  done
}

# Create the network-config files for each VM type
function create_network_config_files() {
  touch "$(dirname "$0")/cloud-init/network-config.{gateway,control,worker}"
}

# Format the disk
function format_disk() {
  qemu-img create -F qcow2 -b ../resources/jammy-server-cloudimg-arm64.img -f qcow2 "$vmdir/disk.img" 20G
}

# Prepare cloud-init config files only if they don't exist
function prepare_cloud_init_files() {
  cat <<EOF >"$vmdir/meta-data"
instance-id: $vmname
local-hostname: $vmname
EOF

  eval "cat << EOF
$(<"$(dirname "$0")/cloud-init/user-data.$vmtype")
EOF
" >"$vmdir/user-data"

  eval "cat << EOF
$(<"$(dirname "$0")/cloud-init/network-config.$vmtype")
EOF
" >"$vmdir/network-config"
}

# Build the cloud-init ISO
function build_cloud_init_iso() {
  mkisofs -output "$vmdir/cidata.iso" -volid cidata -joliet -rock "$vmdir"/{user-data,meta-data,network-config}
}

# Main function to run all steps
function main() {
  parse_arguments "$1"
  get_vmtypejoliet
  create_directories
  create_user_data_files
  create_network_config_files
  format_disk
  prepare_cloud_init_files
  build_cloud_init_iso
}

# Execute the main function with the provided arguments
main "$@"
