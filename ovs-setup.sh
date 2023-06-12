#!/bin/bash

# Define the primary network interface connected to the router
primary_iface="enp1s0"

# Read the list of additional interfaces from the user
echo "Enter the additional interface names (separated by spaces):"
read -r additional_ifaces

# Prompt for DHCP configuration for the primary interface
echo "Configure $primary_iface for DHCP? (y/n)"
read -r dhcp_primary

# Configure the primary interface for DHCP if selected
if [[ $dhcp_primary =~ ^[Yy]$ ]]; then
    echo -e "auto $primary_iface\niface $primary_iface inet dhcp\n" >> /etc/network/interfaces
else
    echo -e "auto $primary_iface\niface $primary_iface inet manual\n" >> /etc/network/interfaces
    echo "up ip link set dev \$IFACE up" >> /etc/network/interfaces
fi

# Configure additional interfaces
for iface in $additional_ifaces; do
    echo -e "auto $iface\niface $iface inet manual\nup ip link set dev \$IFACE up\n" >> /etc/network/interfaces
done

# Restart networking service
systemctl restart networking

# Set up Open vSwitch
ovs-vsctl add-br br0
ovs-vsctl add-port br0 $primary_iface

# Add additional interfaces to the bridge
for iface in $additional_ifaces; do
    ovs-vsctl add-port br0 $iface
done

# Restart networking service to apply Open vSwitch changes
systemctl restart networking
