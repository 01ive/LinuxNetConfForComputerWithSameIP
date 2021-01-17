#!/bin/bash

# $1 net namespace name
# $2 network adapter to use
# $3 network adapter Ip configuration

# Create named netNameSpace 'netAlpine2'
sudo ip netns add $1
# Link network adapter 'ens39'  to this netNameSpace 'netAlpine2'
sudo ip link set dev $2 netns $1
# Start network adapter 'ens39' in this netNameSpace 'netAlpine2'
sudo ip netns exec $1 ip link set dev $2 up
# Set network adapter 'ens39' static address 192.168.0.11
sudo ip netns exec $1 ip address add $3 dev $2