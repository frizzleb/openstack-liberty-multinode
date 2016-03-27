#!/bin/bash -ex

source config.cfg

echo "Configuring hostname in CONTROLLER node"
sleep 3
echo "controller" > /etc/hostname
hostname -F /etc/hostname

echo "Configuring file /etc/hosts"
sleep 3
iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1   localhost controller
$LOCAL_IP   controller

EOF


# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
sysctl -p

#echo "##### Add Openstack Liberty Repo ##### "
#apt-get install software-properties-common -y
#add-apt-repository cloud-archive:liberty -y

sleep 5
echo "Update the system"
apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade


echo "########## Install and Config OpenvSwitch ##########"
apt-get install openvswitch-switch

echo "########## Setup external network bridge ##########"
sleep 5
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex eth0


echo "########## Configure br-ex in the interfaces file ##########"
ifaces=/etc/network/interfaces
test -f $ifaces.orig1 || cp $ifaces $ifaces.orig1
rm $ifaces
cat << EOF > $ifaces
# The loopback network interface
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address $PUBLIC_IP
netmask $PUBLIC_NETMASK
network $PUBLIC_NETWORK
broadcast $PUBLIC_BROADCAST
gateway $PUBLIC_GATEWAY
up ifconfig eth1 promisc up
down ifconfig eth1 promisc down

# The primary network interface
auto br-ex
iface br-ex inet static
address $PUBLIC_IP
hwaddress ether $PUBLIC_MAC
netmask $PUBLIC_NETMASK
dns-nameservers 8.8.8.8

auto eth1
iface eth1 inet static
address $PRIVATE_IP
netmask $PRIVATE_NETMAST
broadcast $PRIVATE_BROADCAST
EOF

sleep 5
echo "Rebooting Server"

#sleep 5
init 6
