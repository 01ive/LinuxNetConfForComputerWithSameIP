#!/bin/bash

# $1 net namespace name
# $2 real IP
# $3 alias IP
# $4 router IP
# $5 alias addresses areas

# Define local route in net namespace netAlpine2 from 192.168.1.1 to 192.168.0.1
sudo ip netns exec $1 iptables -t nat -A OUTPUT -d $3 -j DNAT --to-destination $2
# Add a route through 192.168.0.11 for 192.168.1.X requests
sudo ip netns exec $1 ip route add $5 via $4
# Define nat route in net namespace netAlpine2 from 192.168.1.1 to 192.168.0.1
sudo ip netns exec $1 iptables -t nat -A PREROUTING -d $3 -j NETMAP --to $2
# Configure nat
sudo ip netns exec $1 iptables -t nat -A POSTROUTING -j MASQUERADE