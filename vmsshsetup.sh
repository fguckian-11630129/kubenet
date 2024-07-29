#!/usr/bin/env bash

set -xe
dir=$(dirname "$0")

# Grab the helpers
source "$dir/helpers.sh"

# Parse the argument (VM ID)
vmid=$1
vmname=$(id_to_name "$vmid")

# Wait until the VM is ready to accept SSH connections
until nc -zw 10 "$vmname" 22; do sleep 1; done

# Remove any stale entries for this VM from known_hosts
if [[ -f ~/.ssh/known_hosts ]]; then
  sed -i "/^$vmname/d" ~/.ssh/known_hosts
fi

# Add new entries for this VM to known_hosts
ssh-keyscan "$vmname" 2> /dev/null >> ~/.ssh/known_hosts

# Wait until the system boots up and starts accepting unprivileged SSH connections
# Loop until SSH connection is successful
until ssh -o ConnectTimeout=2 "ubuntu@$vmname" exit; do
  echo "Waiting for $vmname to become available..."
  sleep 1
done

echo "$vmname is now reachable via SSH."

# SSH into the VM manually
ssh "ubuntu@$vmname"