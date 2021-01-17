#!/bin/bash

# $1 net namespace name
# $2 network interface name in namespace
# $3 IP address
# $4 network interface name in default namespace
# $5 IP address
# $6 IP route configuration


# Create Virtual Ethernet Network using two interfaces 'toAlpine' and 'toNormal'
sudo ip link add $4 type veth peer name $2

## netAlpine2 configuration
# Link network adapter 'toNormal' to this netNameSpace 'netAlpine2'
sudo ip link set $2 netns $1
# Set network adapter 'toNormal' static address 1.1.1.0 using netmask 255.255.255.254
sudo ip netns exec $1 ip a a $3/31 dev $2
# Start network adapter 'toNormal' in this netNameSpace 'netAlpine2'
sudo ip netns exec $1 ip l set $2 up

# Create a default route through IP 1.1.1.1 (toAlpine)
sudo ip netns exec $1 ip r a default via $5


## Default network configuration
# Set network adapter 'toAlpine' static address 1.1.1.1 using netmask 255.255.255.254
sudo ip a a $5/31 dev $4
# Start network adapter 'toAlpine' in this default netNameSpace
sudo ip l set $4 up

# Create route IP 192.168.1.X/24 through 1.1.1.0 (toNormal)
sudo ip r a $6 via $3