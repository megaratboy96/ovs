# ovs
Open vSwitch installation script

This script was made to install Open vSwitch on my 5 ethernet port mini PC. It asks how many interfaces you have, then you tell it which one uses DHCP, then it asks for the rest of the interfaces.
make sure you are running this script as root and DO NOT USE SSH! once Open vSwitch is set up, you will get kicked out of your SSH session and the script was open. You need a veth pair in order to connect the host PC to the OVS switch. I will upload a modified script later. This project isn't complete and will not give you a fully functional switch.
