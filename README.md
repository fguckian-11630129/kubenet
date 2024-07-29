# Get going now

Make sure you are starting clean
    ./cleanup.sh

Launch the VM's
    ./main.sh

# Manual configuration

Put the following in /etc/dnsmasq.conf

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

Append this to /etc/hosts

192.168.1.1   vmhost
192.168.1.10  gateway
192.168.1.11  control0
192.168.1.12  control1
192.168.1.13  control2
192.168.1.14  worker0
192.168.1.15  worker1
192.168.1.16  worker2
192.168.1.21  kubernetes

