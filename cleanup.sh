#!/usr/bin/env bash

set -x
dir=$(dirname "$0")

# Grab the helpers
source "$dir/helpers.sh"

for vmid in $(seq 0 6); do
    vmname=$(id_to_name $vmid)
    vmdir="$dir/$vmname"

    if [ -d "$(dirname "$0")/cloud-init" ]; then
        rm -fr "$(dirname "$0")/cloud-init"
    fi

    if [ -d $vmdir ]; then
        rm -fr "$vmdir"
    fi

done

sudo pkill qemu
sudo tmux kill-session -t kubenet-qemu
