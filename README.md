# Linux network configuration to manage two computers using same IP address

```
                                                                Computer Server
 +----------+                                      +-------------------------------------+
| COMPUTER 1 |                                     |            Default network          |
|            | 192.168.0.1            192.168.0.10 | ens33                      toAlpine | 1.1.1.1
|            ---------------------------------------                                     ---------------+
|            |                                     |                                     |              |
|            |                                     |                                     |              |
 +----------+                                      |                                     |              |
                                                   |-------------------------------------+              | Vitual Network
 +----------+                                      |          netAlpine2 network         |              |
| COMPUTER 2 |                                     |                                     |              |
|            | 192.168.0.1            192.168.0.11 | ens39                      toNormal | 1.1.1.0      |
|            ---------------------------------------                                     ---------------+
|            |                                     |                                     |
|            |                                     |                                     |
 +----------+                                      +-------------------------------------+
```

## Network configuration

First of all you need to activate ip forward and allow multi Ethernet Interface on same network (192.168.0.0)

```bash
sudo vim /etc/sysctl.conf
 net.ipv4.ip_forward = 1
 net.ipv4.conf.all.arp_filter = 1
```

You can check your configuration using ```sudo sysctl -p``` command.

All network configuration used mask 255.255.255.0

# Configure two Ethernet card on same network address using net NameSpace

First of all we create a network namespace "netAlpine2" that will allows us to communicate with COMPUTER 2 and COMPUTER 1 using same ip address 192.168.0.1.

```bash
# Create named netNameSpace 'netAlpine2'
sudo ip netns add netAlpine2
# Link network adapter 'ens39'  to this netNameSpace 'netAlpine2'
sudo ip link set dev ens39 netns netAlpine2
# Start network adapter 'ens39' in this netNameSpace 'netAlpine2'
sudo ip netns exec netAlpine2 ip link set dev ens39 up
# Set network adapter 'ens39' static address 192.168.0.11/24
sudo ip netns exec netAlpine2 ip address add 192.168.0.11/24 dev ens39
```

Now you can communicate to COMPUTER 1 using 192.168.0.1 address. And you can communicate with COMPUTER 2 through net namespace 'netAlpine2'

Example SSH connection to COMPUTER 2 
```bash
# Connect in SSH
sudo ip netns exec netAlpine2 ssh root@192.168.0.1
```

If you need to use bash in net namespace 'netAlpine2' try the following command (Warning you will be logged as root).
```bash
# Run bash in netNameSpace Alpine2
sudo nsenter --net=/var/run/netns/netAlpine2
```

Using script ```./createNetNS.sh netAlpine2 ens39 192.168.0.11/24 ```

# Configure virtual Ethernet interface between both netNameSpace

We setup a virtual network between both network namespace in order to allow communication

```bash
# Create Virtual Ethernet Network using two interfaces 'toAlpine' and 'toNormal'
sudo ip link add toAlpine type veth peer name toNormal

## netAlpine2 configuration
# Link network adapter 'toNormal' to this netNameSpace 'netAlpine2'
sudo ip link set toNormal netns netAlpine2
# Set network adapter 'toNormal' static address 1.1.1.0 using netmask 255.255.255.254
sudo ip netns exec netAlpine2 ip a a 1.1.1.0/31 dev toNormal
# Start network adapter 'toNormal' in this netNameSpace 'netAlpine2'
sudo ip netns exec netAlpine2 ip l set toNormal up

# Create a default route through IP 1.1.1.1 (toAlpine)
sudo ip netns exec netAlpine2 ip r a default via 1.1.1.1


## Default network configuration
# Set network adapter 'toAlpine' static address 1.1.1.1 using netmask 255.255.255.254
sudo ip a a 1.1.1.1/31 dev toAlpine
# Start network adapter 'toAlpine' in this default netNameSpace
sudo ip l set toAlpine up

# Create route IP 192.168.1.X through 1.1.1.0 (toNormal)
sudo ip r a 192.168.1.0/24 via 1.1.1.0
```
# Routing rules

In order to easily access COMPUTER 2 we will define an alias to this computer using network address 192.168.1.1 (instead of 192.168.0.1).

## Create a network address alias to computer in netNameSpace netAlpine2

```bash
# Define local route in net namespace netAlpine2 from 192.168.1.1 to 192.168.0.1
sudo ip netns exec netAlpine2 iptables -t nat -A OUTPUT -d 192.168.1.1 -j DNAT --to-destination 192.168.0.1
# Add a route through 192.168.0.11 for 192.168.1.X requests
sudo ip netns exec netAlpine2 ip route add 192.168.1.0/24 via 192.168.0.11
```

## Configure a network address translation through virtual Ethernet interface

```bash
# Define nat route in net namespace netAlpine2 from 192.168.1.1 to 192.168.0.1
sudo ip netns exec netAlpine2 iptables -t nat -A PREROUTING -d 192.168.1.1 -j NETMAP --to 192.168.0.1
# Configure nat
sudo ip netns exec netAlpine2 iptables -t nat -A POSTROUTING -j MASQUERADE
```
# Helpfull commands

* View iptables rules  ```iptables -n -t nat -L -v```
* CLear iptables rules ```iptables -t nat -F```
* View network traffic ```tcpdump --interface any```

# Used configuration

* Ubuntu 16.04 LTS (Computer server)
* Alpine 3.13.0 (COMPUTER 1 & 2)
* All env virtualized in Windows 10 (VMWare Worksattion 16 Player)