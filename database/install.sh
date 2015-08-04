#!/bin/bash

set -x
#This is what is needed to be run on an Ubuntu 14.04 instance in order to turn it into a Moodle Database webserver;

# Setup system variables
MARIADBPASSWORD=letmein22
MOODLEUSERPASSWORD=letmein2

# Format extra space - this is unique to Eucalyptus because the instances launch with 60 GB but the / 
# partition is only 8 GB and leaves the remaining 52 GB unformated and unpartitioned
# So this script partitions that remaining space up and gives ownership of it to the database 
# because we are going to put the actual datafile of the mariadb on this partition not / (or traditionally
# /var.
# On eucalyptus the second device is always /dev/vdb

mkfs -t ext4 /dev/vdb
mkdir -p /mnt/vol-01/datadir
mount -t ext4 /dev/vdb /mnt/vol-01/datadir
# add line to /etc/fstab so this new partition auto mounts on reboot
echo "/dev/vdb    /mnt/vol-01/datadir ext4 defaults 0 1" >> /etc/fstab

# Install services time
# http://www.dev-metal.com/install-setup-php-5-6-ubuntu-14-04-lts/
# Here we are adding the pre-required files for downloading additional PPAs (Ubuntu Software Repositories)
sudo apt-get update
sudo apt-get install -y python-software-properties
sudo apt-get install -y software-properties-common

# Now we are adding the new repos for PHP 5.6--which is not standard in Ubuntu 14.04.2
# Also here I am adding some repositories for a newer version of rsyslog which is used for logging and has no effect on the moodle system or usage but helps us log
sudo add-apt-repository -y ppa:ondrej/php5-5.6
sudo add-apt-repository -y ppa:adiscon/v8-stable
sudo apt-get update


# Install the mariadb-server (client not needed) DEBCONF is how to proceed with an install without it asking for a password
# Configure and Install rsyslog and provide mariadb for logging
# http://dba.stackexchange.com/questions/35866/install-mariadb-without-password-prompt-in-ubuntu?newreg=426e4e37d5a2474795c8b1c911f0fb9f
# From <http://serverfault.com/questions/103412/how-to-change-my-mysql-root-password-back-to-empty/103423> 
echo "mariadb-server-5.5 mysql-server/root_password password $MARIADBPASSWORD" | sudo  debconf-set-selections
echo "mariadb-server-5.5 mysql-server/root_password_again password $MARIADBPASSWORD" | sudo debconf-set-selections

sudo DEBIAN_FRONTEND=noninteractive apt-get install -yy rsyslog 
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
sudo apt-get install -y git curl wget rsync vim

#inject the username and password for autologin later in a ~/.my.cnf file
# http://serverfault.com/questions/103412/how-to-change-my-mysql-root-password-back-to-empty/103423#103423

echo -e "[client] \n user = root \n password = $MARIADBPASSWORD" > ~/.my.cnf
echo -e "\n port = 3306 \n socket          = /var/run/mysqld/mysqld.sock" >> ~/.my.cnf

# Insert our custom mysql/mariadb config settings in the local my.cnf  -- that way the system will override values for us in a graceful way - no need to modify with sed.
# http://dev.mysql.com/doc/refman/5.1/en/option-files.html

#this line appends the rest of our custom my.cnf file to the end of the one we created on the previous lines
cat mariadb.cnf >> ~/.my.cnf



# Ubuntu local firewall (good idea to be thorough)
ufw enable
ufw allow from 192.168.0.0/16 to any port 3306
ufw allow ssh

# Now we are going to stop the mysql (mariadb is a drop in plugin so we still use the mysql tools) server
# to edit it
service mysql stop

# Now use sed command to insert new values in the /etc/mysql/my.cnf 
# or you can do this manually - the IP here is the private address of the database server - Unique to Eucalyptus systems 
PRIVATEIP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

sed -i "s/bind-address            = 127.0.0.1/bind-address            = $PRIVATEIP/" ~/.my.cnf
sed -i "s/datadir         = \/var\/lib\/mysql/datadir         = \/mnt\/vol-01\/datadir/" ~/.my.cnf

# This line copies the actual mysql database files over to the new location
cp -R /var/lib/mysql/* /mnt/vol-01/datadir
chown -R mysql:mysql /mnt/vol-01/datadir

service mysql start

# execute these commands to setup the moodle database and permissions
# see commands.sql
# type or cut and paste these lines into a file called commands.sql
#CREATE DATABASE moodle DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
#GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO moodleuser@'192.168.%.%' IDENTIFIED BY 'placeholder';
#GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER, CREAT USER ON moodle.* TO moodleuser@'localhost';
#flush privileges;


#auto run or source a script
# http://dev.mysql.com/doc/refman/5.0/en/batch-mode.html
# the stars are your root password
# no need to enter the password here because we have it safely stored in the ~/.my.cnf file
mysql -u root < commands.sql

# Create the moodleuser with a  placeholder password - the execute this line mysqladmin to overwrite the password based on what is set at the top of this script.
# http://www.cyberciti.biz/faq/mysql-change-root-password/
mysqladmin -u moodleuser -p'placeholder' password $MOODLEUSERPASSWORD

#install ganglia for monitoring
sudo apt-get -y install ganglia-monitor

# Add monitoring config here
