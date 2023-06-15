#!/bin/bash

# Prompt for the number of interfaces
read -p "Enter the number of interfaces to add to the bridge: " num_interfaces

# Prompt for the interface names and store them in an array
declare -a interfaces
for ((i=1; i<=num_interfaces; i++))
do
    read -p "Enter the name of interface $i: " interface_name
    interfaces+=("$interface_name")
done

# Prompt for the primary interface
read -p "Enter the name of the primary interface: " primary_interface

# Install OVS
apt-get install openvswitch-switch openvswitch-common -y

# Setup bridge
ovs-vsctl add-br br0

# Add physical ports to bridge
for interface in "${interfaces[@]}"
do
    ovs-vsctl add-port br0 $interface
done

# Flush primary interface, enable DHCP for bridge, and set bridge state to up
ip addr flush dev $primary_interface
dhclient br0
ip link set br0 up
