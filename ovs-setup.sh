#!/bin/bash

# Prompt for the number of interfaces
read -p "Enter the number of interfaces on this device: " num_interfaces

# Prompt for the DHCP interface
read -p "Enter the name of the DHCP interface: " dhcp_interface

# Loop to gather interface names
interfaces=()
for ((i=1; i<=num_interfaces; i++))
do
    read -p "Enter the name of interface $i: " interface
    interfaces+=("$interface")
done

# Prompt for the path to the configuration file
read -p "Enter the path to the configuration file: " config_file

# Install Open vSwitch
apt-get update
apt-get install openvswitch-switch -y

# Create the bridge
ovs-vsctl add-br br0

# Add interfaces to the bridge
for interface in "${interfaces[@]}"
do
    ovs-vsctl add-port br0 "$interface"
done

# Enable spanning tree protocol (STP)
ovs-vsctl set bridge br0 stp_enable=true

# Modify /etc/network/interfaces
echo "# The primary network interface" > /etc/network/interfaces
echo "allow-hotplug $dhcp_interface" >> /etc/network/interfaces
echo "iface $dhcp_interface inet dhcp" >> /etc/network/interfaces
echo "" >> /etc/network/interfaces

for interface in "${interfaces[@]}"
do
    if [[ "$interface" != "$dhcp_interface" ]]; then
        echo "# Additional network interface" >> /etc/network/interfaces
        echo "auto $interface" >> /etc/network/interfaces
        echo "iface $interface inet manual" >> /etc/network/interfaces
        echo "  up ip link set dev \$IFACE up" >> /etc/network/interfaces
        echo "" >> /etc/network/interfaces
    fi
done

# Restart the network service
systemctl restart networking

# Print the current Open vSwitch configuration
echo "Open vSwitch configuration on this device:"
ovs-vsctl show
