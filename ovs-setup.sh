#!/bin/bash

# Check if the script is run with administrative privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Please run with sudo or as the root user."
  exit 1
fi

# Set variables
interfaces_file="/etc/network/interfaces"

# Function to generate a random MAC address
generate_mac_address() {
  printf '%02x:%02x:%02x:%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

# Prompt user for the number of virtual interfaces
echo "How many virtual interfaces do you need?"
read num_virtual_interfaces

# Generate MAC addresses for virtual interfaces
virtual_interface_names=()
for ((i=0; i<num_virtual_interfaces; i++))
do
  virtual_interface_names+=("veth$i")
done

# Install OVS
apt install openvswitch-switch openvswitch-common

# Setup bridge and virtual ports for the host system
ovs-vsctl add-br br0

# Add virtual ports to bridge and generate cron job lines
cron_job_lines=""
for interface_name in "${virtual_interface_names[@]}"
do
  veth_interface_name="${interface_name}-br0"
  veth_mac_address=$(generate_mac_address)
  
  ip link add "$interface_name" address "$veth_mac_address" type veth peer name "$veth_interface_name"
  ip link set dev "$interface_name" up
  
  ovs-vsctl add-port br0 "$veth_interface_name"
  
  cron_job_lines+="ip link set dev $interface_name address $veth_mac_address up && systemctl restart networking"$'\n'
done

# Backup the original interfaces file
cp "$interfaces_file" "$interfaces_file.bak"

# Generate the new interfaces file content
new_interfaces_content=$(cat <<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug veth0
iface veth0 inet dhcp

allow-hotplug veth0-br0
iface veth0-br0 inet manual

# Virtual Ethernet interfaces
EOF
)

# Generate the interfaces content for each virtual interface
for interface_name in "${virtual_interface_names[@]}"
do
  new_interfaces_content+="allow-hotplug $interface_name
iface $interface_name inet manual
\n\n"
done

# Generate the bridge content
new_interfaces_content+="allow-ovs br0
iface br0 inet manual
    ovs-type OVSBridge"

# Write the new interfaces content to the file
echo "$new_interfaces_content" | tee "$interfaces_file" > /dev/null

# Restart the networking service
systemctl restart networking

# Get the current cron jobs for the root user
current_cron_jobs=$(crontab -l -u root)

# Check if there are existing cron jobs
if [[ -n "$current_cron_jobs" ]]; then
  # Append the new cron job lines to the existing ones
  new_cron_jobs="$current_cron_jobs"$'\n'"$cron_job_lines"
else
  # Set the new cron job lines as the only lines if there are no existing cron jobs
  new_cron_jobs="$cron_job_lines"
fi

# Echo the new cron jobs and pipe it to the crontab command to update the root user's cron jobs
echo "$new_cron_jobs" | crontab -u root -

echo "New virtual interfaces and cron job entries added successfully!"
