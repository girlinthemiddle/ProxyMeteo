#!/bin/bash

echo " us have two chairs:"
echo "1) Customize new PoPToP VPN server or create new user"
echo "2) Create additional USERS (to an existing VPN)"
read x
if test $x -eq 1; then
    echo "input new name to create (client1 or john):"
    read u
    echo "input pass for the user:"
    read p
 
# get the VPS IP
ip=`ifconfig eth0 | grep 'inet addr' | awk {'print $2'} | sed s/.*://`
 
echo
echo "install and configuretion PoPToP"
apt-get update
apt-get install pptpd
 
echo
echo "Create configuare server"
cat > /etc/ppp/pptpd-options <<END
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
nodefaultroute
lock
nobsdcomp
END
 
# setting up pptpd.conf
echo "option /etc/ppp/pptpd-options" > /etc/pptpd.conf
echo "logwtmp" >> /etc/pptpd.conf
echo "localip $ip" >> /etc/pptpd.conf
echo "remoteip 10.1.0.1-100" >> /etc/pptpd.conf
 
# adding new user
echo "$u    *   $p  *" >> /etc/ppp/chap-secrets
 
echo
echo " Forwarding IPv4 and add this in autoload"
cat >> /etc/sysctl.conf <<END
net.ipv4.ip_forward=1
END
sysctl -p
 
echo
echo "Update IPtables Routing and add this in autoload"
iptables -t nat -A POSTROUTING -j SNAT --to $ip
# saves iptables routing rules and enables them on-boot
iptables-save > /etc/iptables.conf
 
cat > /etc/network/if-pre-up.d/iptables <<END
#!/bin/sh
iptables-restore < /etc/iptables.conf
END
 
chmod +x /etc/network/if-pre-up.d/iptables
cat >> /etc/ppp/ip-up <<END
ifconfig ppp0 mtu 1400
END
 
echo
echo "restart PoPToP"
/etc/init.d/pptpd restart
 
echo
echo "You up vpn network"
echo "U IP: $ip? login and password:"
echo "User name (login):$u ##### password: $p"
 
# runs this if option 2 is selected
elif test $x -eq 2; then
    echo "Input your username to create (eg. client1 or john):"
    read u
    echo "Input the password for the user to be created:"
    read p
 
# get the VPS IP
ip=`ifconfig venet0:0 | grep 'inet addr' | awk {'print $2'} | sed s/.*://`
 
# adding new user
echo "$u    *   $p  *" >> /etc/ppp/chap-secrets
 
echo
echo "Additional user created!"
echo "IP server: $ip, access data:"
echo "Name user (login):$u ##### password: $p"
 
else
echo "Wrong choice, down..."
exit
fi
