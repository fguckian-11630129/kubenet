#!/usr/bin/env bash

# Variables
TAP_IP="192.168.1.1/24"
USER=$(whoami)

# Function to create a TAP interface
create_tap_interface() {
    local tap_interface="$1"
    if ! ip link show "$tap_interface" > /dev/null 2>&1; then
        echo "Creating TAP interface $tap_interface..."
        sudo ip tuntap add dev "$tap_interface" mode tap user "$USER"
        echo "TAP interface $tap_interface created."
    else
        echo "TAP interface $tap_interface already exists."
    fi
}

# Function to create a bridge interface
create_bridge_interface() {
    local bridge_interface="$1"
    if ! ip link show "$bridge_interface" > /dev/null 2>&1; then
        echo "Creating bridge interface $bridge_interface..."
        sudo ip link add name "$bridge_interface" type bridge
        echo "Bridge interface $bridge_interface created."
    else
        echo "Bridge interface $bridge_interface already exists."
    fi
}

# Function to add TAP interface to the bridge
add_tap_to_bridge() {
    local tap_interface="$1"
    local bridge_interface="$2"
    if ! bridge link show | grep -q "$tap_interface"; then
        echo "Adding TAP interface $tap_interface to bridge $bridge_interface..."
        sudo ip link set "$tap_interface" master "$bridge_interface"
        echo "TAP interface $tap_interface added to bridge $bridge_interface."
    else
        echo "TAP interface $tap_interface is already part of bridge $bridge_interface."
    fi
}

# Function to bring up an interface
bring_up_interface() {
    local interface="$1"
    if ip link show "$interface" | grep -q "state DOWN"; then
        echo "Bringing up interface $interface..."
        sudo ip link set "$interface" up
        echo "Interface $interface is up."
    else
        echo "Interface $interface is already up."
    fi
}

# Function to assign an IP address to an interface
assign_ip_address() {
    local ip_address="$1"
    local interface="$2"
    if ! ip addr show "$interface" | grep -q "$ip_address"; then
        echo "Assigning IP address $ip_address to interface $interface..."
        sudo ip addr add "$ip_address" dev "$interface"
        echo "IP address $ip_address assigned to interface $interface."
    else
        echo "Interface $interface already has IP address $ip_address."
    fi
}

# Function to add DHCP configuration to /etc/dnsmasq.conf
function add_dhcp_configuration() {
    local config_file="/etc/dnsmasq.conf"

    # Configuration lines to add
    local config_lines=(
        "dhcp-range=192.168.1.2,192.168.1.20,12h"
        "dhcp-host=52:52:52:00:00:00,192.168.1.10"
        "dhcp-host=52:52:52:00:00:01,192.168.1.11"
        "dhcp-host=52:52:52:00:00:02,192.168.1.12"
        "dhcp-host=52:52:52:00:00:03,192.168.1.13"
        "dhcp-host=52:52:52:00:00:04,192.168.1.14"
        "dhcp-host=52:52:52:00:00:05,192.168.1.15"
        "dhcp-host=52:52:52:00:00:06,192.168.1.16"
        "dhcp-authoritative"
        "domain=kubenet"
        "expand-hosts"
    )

    # Backup the existing configuration file
    if [[ -f "$config_file" ]]; then
        sudo cp "$config_file" "$config_file.bak"
    fi

    # Add each configuration line if it doesn't already exist
    for line in "${config_lines[@]}"; do
        if ! grep -Fxq "$line" "$config_file"; then
            echo "$line" | sudo tee -a "$config_file" > /dev/null
        fi
    done

    echo "Configuration added to $config_file."
}

# Main script logic
BRIDGE_INTERFACE="br0"
TAP_PREFIX="tap"

# Create TAP interfaces tap0 to tap6
for i in $(seq 0 6); do
    TAP_INTERFACE="${TAP_PREFIX}${i}"
    create_tap_interface "$TAP_INTERFACE"
    add_tap_to_bridge "$TAP_INTERFACE" "$BRIDGE_INTERFACE"
    bring_up_interface "$TAP_INTERFACE"
done

# Create the bridge interface
create_bridge_interface "$BRIDGE_INTERFACE"

# Bring up the bridge interface
bring_up_interface "$BRIDGE_INTERFACE"

# Assign IP address to the bridge interface
assign_ip_address "$TAP_IP" "$BRIDGE_INTERFACE"

# Assign IP addresses to the mac addresses
add_dhcp_configuration

# Restart dnsmasq to re-lease the IP addresses
sudo systemctl restart dnsmasq

# Ensure that the bridge can access the internet using the host interface
sudo iptables -t nat -A POSTROUTING -o wlp0s20f3 -j MASQUERADE
