# Format extra space
mkfs -t ext4 /dev/vdb
mkdir -p /mnt/vol-01
mount -t ext4 /dev/vdb /mnt/vol-01
chown -R www-data:www-data /mnt/vol-01/
#add line to /etc/fstab 
echo "/dev/vdb    /mnt/vol-01 ext4 defaults 0 1" >> /etc/fstab

#http://www.dev-metal.com/install-setup-php-5-6-ubuntu-14-04-lts/
sudo apt-get update
sudo apt-get install python-software-properties
sudo apt-get install software-properties-common

sudo add-apt-repository -y ppa:ondrej/php5-5.6
sudo add-apt-repository -y ppa:adiscon/v8-stable

sudo apt-get update

# Client
# git client needs some other dependencies
sudo apt-get install  git curl wget rsync vim

sudo apt-get install apache2 php5 graphviz aspell php5-pspell php5-curl php5-gd php5-intl php5-mysql php5-xmlrpc php5-ldap mariadb-client

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
cp -R ~/moodle /mnt/vol-01/moodle
mkdir -p /mnt.vol-01/moodledata
chown -R www-data /mnt/vol-01/moodledata
chown -R www-data /mnt/vol-01/moodle
chmod -R 777 /mnt/vol-01/moodledata
chmod -R 0755 /mnt/vol-01/moodle

# Adjust the apache conf.d to serve out of /mnt/vol-01/moodle or else nothing happens...:
# to be done

# now automate the site install 
 VAR=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
 HTTP="http://"
# IP of remote database server
 REMOTEURL="192.168.119.75"

 sudo -u www-data /usr/bin/php admin/cli/install.php --chmod=2770 --lang=en --wwwroot=$HTTP$VAR --dataroot=/mnt/vol-01/moodledata --dbtype=mariadb --dbhost=$REMOTEURL --dbuser=moodleuser --dbpass=Letmein --fullname="Greatest Site Ever" --shortname="Da Site" --adminuser=adminjrh --adminpass=Letmein1! --non-interactive --agree-license