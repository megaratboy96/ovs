#!/bin/bash

# Prompt for the WiFi interface name
read -p "Enter the name of the WiFi interface: " wifi_interface

# Prompt for the WiFi standards
read -p "Enter the WiFi standards (e.g., bgn/ac): " wifi_standards

# Prompt for the WiFi channel
read -p "Enter the WiFi channel: " wifi_channel

# Prompt for the WiFi SSID
read -p "Enter the WiFi SSID: " wifi_ssid

# Prompt for the WiFi password
read -p "Enter the WiFi password: " wifi_password

# Install hostapd
apt-get update
apt-get install hostapd -y

# Create hostapd configuration
cat > /etc/hostapd/hostapd.conf << EOL
interface=$wifi_interface
driver=nl80211
ssid=$wifi_ssid
hw_mode=a
channel=$wifi_channel
ieee80211n=1
wmm_enabled=1
ht_capab=[HT40+][SHORT-GI-20][DSSS_CCK-40]
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$wifi_password
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOL

# Update hostapd configuration file
sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd

# Restart hostapd service
systemctl restart hostapd

echo "hostapd configuration completed for $wifi_interface."
