#!/usr/bin/env bash

set -xe

for vmid in $(seq 1 6); do 
  ./vmsetup.sh $vmid
done

# sudo ./create-tap.sh

# sudo ./vmlaunchall.sh kubenet-qemu