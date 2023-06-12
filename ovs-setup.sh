#!/bin/bash

# Prompt for OVS setup
read -p "Do you want to install and configure Open vSwitch? (y/n): " install_ovs

if [[ $install_ovs == "y" ]]; then
  # Prompt for Ethernet ports
  echo -n "Enter the names of the Ethernet ports (space-separated): "
  read -r ethernet_ports

  # Prompt for bridge IP address
  echo -n "Enter the IP address for the bridge (e.g., 192.168.50.152/24): "
  read -r bridge_ip

  # Prompt for static route
  echo -n "Enter the network IP address and gateway for the static route (e.g., 192.168.50.0/24 192.168.50.1): "
  read -r network_route gateway_route

  # Install OVS
  apt-get update
  apt-get install -y openvswitch-switch

  # Create bridge
  ovs-vsctl add-br br0

  # Add Ethernet ports to the bridge
  for port in $ethernet_ports; do
    ovs-vsctl add-port br0 "$port"
  done

  # Disable IP configuration on the Ethernet ports
  for port in $ethernet_ports; do
    ip addr flush "$port"
  done

  # Enable the bridge
  ip link set br0 up

  # Configure IP address for the bridge
  ip addr add "$bridge_ip" dev br0

  # Enable IP forwarding
  sysctl net.ipv4.ip_forward=1

  # Configure static routes
  ip route add "$network_route" via "$gateway_route" dev br0

  # Update network configuration file
  echo "auto br0" >> /etc/network/interfaces
  echo "iface br0 inet static" >> /etc/network/interfaces
  echo "  address $(echo "$bridge_ip" | cut -d'/' -f1)" >> /etc/network/interfaces
  echo "  netmask $(echo "$bridge_ip" | cut -d'/' -f2)" >> /etc/network/interfaces
  echo "  gateway $gateway_route" >> /etc/network/interfaces

  # Restart networking services
  systemctl restart networking

  echo "Open vSwitch configuration completed."
else
  echo "Skipping Open vSwitch installation and configuration."
fi
