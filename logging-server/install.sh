#!/bin/bash 
set -e
set -v

# Vaiable for the mariadb debconf password preset
MARIADBPASSWORD=letmein

apt-get update 
sudo apt-get install -y python-software-properties
sudo apt-get install -y software-properties-common
add-apt-repository -y ppa:adiscon/v8-stable
apt-get update 

# Install Ganglia
# How to overcome the auto-reboot prompt from Ganglia http://askubuntu.com/questions/146921/how-do-i-apt-get-y-dist-upgrade-without-a-grub-config-prompt
sudo DEBIAN_FRONTEND=noninteractive  apt-get install -y  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ganglia-monitor rrdtool gmetad ganglia-webfrontend 

sudo cp /etc/ganglia-webfrontend/apache.conf /etc/apache2/sites-enabled/ganglia.conf

#sudo sed -i 's/\"hadoop-cluster\" localhost 192.168.98.218' /etc/ganglia/gmetad.conf
sudo sed -i '/mcast_join = 239.2.11.71/i \ host = 192.168.224.188' /etc/ganglia/gmond.conf
sudo sed -i 's/name = "unspecified"/#name = "hadoop-cluster"/g' /etc/ganglia/gmond.conf
sudo sed -i 's/mcast_join = 239.2.11.71/#mcast_join = 239.2.11.71/g' /etc/ganglia/gmond.conf
sudo sed -i 's/bind = 239.2.11.71/#bind = 239.2.11.71/g' /etc/ganglia/gmond.conf

sudo sed -i 's/port = 8649/#port = 8649/g' /etc/ganglia/gmond.conf

sudo sed -i 's/bind = 239.2.11.71/#bind = 239.2.11.71/g' /etc/ganglia/gmond.conf

sudo service ganglia-monitor restart
sudo service gmetad restart
sudo service apache2 restart

# Configure and Install rsyslog and provide mariadb for logging
# http://dba.stackexchange.com/questions/35866/install-mariadb-without-password-prompt-in-ubuntu?newreg=426e4e37d5a2474795c8b1c911f0fb9f
echo "mariadb-server-5.5 mysql-server/root_password password $MARIADBPASSWORD" |sudo  debconf-set-selections
echo "mariadb-server-5.5 mysql-server/root_password_again password $MARIADBPASSWORD" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y rsyslog mariadb-server

sudo sed -i 's/#$ModLoad imudp/$ModLoad imudp/g' /etc/rsyslog.conf
sudo sed -i 's/#$UDPServerRun 514/$UDPServerRun 514/g' /etc/rsyslog.conf
sudo sed -i '$ a $template FILENAME,"/var/log/%fromhost-ip%/syslog.log"' /etc/rsyslog.conf
sudo sed -i '$ a *.* ?FILENAME' /etc/rsyslog.conf

sudo service rsyslog restart
