#!/bin/bash

set -x
set -e

# Format extra space
mkfs -t ext4 /dev/vdb
mkdir -p /mnt/vol-01
mount -t ext4 /dev/vdb /mnt/vol-01
chown -R www-data:www-data /mnt/vol-01/
#add line to /etc/fstab 
echo "/dev/vdb    /mnt/vol-01 ext4 defaults 0 1" >> /etc/fstab

#http://www.dev-metal.com/install-setup-php-5-6-ubuntu-14-04-lts/
sudo apt-get update
sudo apt-get -y install python-software-properties
sudo apt-get -y install software-properties-common

sudo add-apt-repository -y ppa:ondrej/php5-5.6
sudo add-apt-repository -y ppa:adiscon/v8-stable

sudo apt-get update

# Client
# git client and some other tools
sudo apt-get -y install git curl wget rsync vim

# Applications needed for installing moodle with dependencies
sudo apt-get -y install apache2 php5 graphviz aspell php5-pspell php5-curl php5-gd php5-intl php5-mysql php5-xmlrpc php5-ldap mariadb-client

# pull source from Git
# https://docs.moodle.org/29/en/Git_for_Administrators
VERSION=28
NAME=MOODLE_
TYPE=_STABLE
FULL=$NAME$VERSION$TYPE

git clone git://git.moodle.org/moodle.git                       
cd moodle
git branch -a                                                   
git branch --track $FULL origin/$FULL
git checkout $FULL   

#install ganglia for monitoring
sudo apt-get install ganglia-monitor

#modify location
mkdir -p /mnt/vol-01/moodle
mkdir -p /mnt/vol-01/moodledata

cp -R ~/moodle-self-install/webserver/moodle/* /mnt/vol-01/moodle
mkdir -p /mnt/vol-01/moodledata

chown -R www-data /mnt/vol-01/moodledata
chown -R www-data /mnt/vol-01/moodle

chmod -R 777 /mnt/vol-01/moodledata
chmod -R 0755 /mnt/vol-01/moodle

# Pull down the new apache conf.d to serve out of /mnt/vol-01/moodle or else nothing happens...:
service apache2 stop
cp ~/moodle-self-install/webserver/apache2.conf /etc/apache2/apache2.conf
cp ~/moodle-self-install/webserver/000-default.conf /etc/apache2/sites-available/000-default.conf
# restart service to re-read the changes
service apache2 start


# now automate the site install 
PUBLICURL=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
 HTTP="http://"
# IP of remote database server - you need to retrieve this from the database install
REMOTEURL="192.168.224.189"

 sudo -u www-data /usr/bin/php admin/cli/install.php --chmod=2770 --lang=en --wwwroot=$HTTP$PUBLICURL --dataroot=/mnt/vol-01/moodledata --dbtype=mariadb --dbhost=$REMOTEURL --dbuser=moodleuser --dbpass=Letmein --fullname="Greatest Site Ever" --shortname="Da Site" --adminuser=adminjrh --adminpass=Letmein1! --non-interactive --agree-license
 
 #install ganglia for monitoring
sudo apt-get install -y ganglia-monitor

# Add monitoring config here
# Install Ganglia as a client to the central server
# the host value is the private IP of the central ganlia server IP
# sudo sed -i '/mcast_join = 239.2.11.71/i \ host = 192.168.224.188' /etc/ganglia/gmond.conf
# sudo sed -i 's/name = "unspecified"/#name = "hadoop-cluster"/g' /etc/ganglia/gmond.conf
# sudo sed -i 's/mcast_join = 239.2.11.71/ #mcast_join = 239.2.11.71/g' /etc/ganglia/gmond.conf
# sudo sed -i 's/bind = 239.2.11.71/#bind = 239.2.11.71/g' /etc/ganglia/gmond.conf
# sudo sed -i 's/port = 8649/#port = 8649/g' /etc/ganglia/gmond.conf
# sudo sed -i 's/bind = 239.2.11.71/#bind = 239.2.11.71/g' /etc/ganglia/gmond.conf

cp ./gmond.conf /etc/ganglia/gmond.conf

sudo service ganglia-monitor restart

# Install rsyslog
# Again assuming that the IP here is the private cloud IP of the Central Rsyslog server
sudo sed -i "$ a *.* @192.168.224.188:514" /etc/rsyslog.conf 