#!/usr/bin/env bash
 
# http://www.inanzzz.com/index.php/post/lpwy/accessing-vagrant-virtual-machine-from-the-browser-of-host-machine

# BEGIN ########################################################################
echo -e "-- ------------------ --\n"
echo -e "-- BEGIN BOOTSTRAPING --\n"
echo -e "-- ------------------ --\n"

# BOX ##########################################################################
echo -e "-- Updating packages list\n"
apt-get update -y -qq

######Install NFS Server#########
#sudo apt-get install nfs-kernel-server -y
#sudo systemctl restart nfs-server

# ADD VBoxGuestAdditions ########################################################################
#echo -e "-- Adding VirtualBox Guest Additions\n"
#apt-get install -y linux-headers-$(uname -r) build-essential dkms
#wget http://download.virtualbox.org/virtualbox/6.1.38/VBoxGuestAdditions_6.1.38.iso
#sudo mkdir /media/VBoxGuestAdditions
#sudo mount -o loop,ro VBoxGuestAdditions_6.1.38.iso /media/VBoxGuestAdditions
#sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
#rm VBoxGuestAdditions_6.1.38.iso
#sudo umount /media/VBoxGuestAdditions
#sudo rmdir /media/VBoxGuestAdditions
 
# NTP #########################################################################
echo -e "-- Installing Network Time protocol \n"
apt-get install -y ntp
apt-get -y upgrade 

# GIT and Curl #########################################################################
echo -e "-- Installing Curl and Git\n"
apt-get install -y curl git 

# PHP 8.1 #########################################################################
echo -e "-- Adding PHP8.1 repo to apt\n"
sudo apt-get -y install ca-certificates apt-transport-https
wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add - 
sudo echo "deb https://packages.sury.org/php/ buster main" | tee /etc/apt/sources.list.d/php8dot1.list
sudo apt-get update -y -qq

echo -e "-- Installing php8.1 \n"
sudo apt-get install -y php8.1
echo -e "-- Installing extensions for php8.1 \n"
sudo apt-get install -y php8.1-bcmath php8.1-common php8.1-ctype php8.1-curl php8.1-dom php8.1-gd php8.1-intl php8.1-json php8.1-mbstring php8.1-mysqli php8.1-opcache php8.1-soap php8.1-xdebug php8.1-xml php8.1-xsl php8.1-zip
echo -e "-- php8.1 installed \n"

echo "xdebug.profiler_enable_trigger=1" >> /etc/php/8.1/mods-available/xdebug.ini 
echo "xdebug.profiler_enable=0" >> /etc/php/8.1/mods-available/xdebug.ini 
echo "xdebug.remote_port=9000" >> /etc/php/8.1/mods-available/xdebug.ini 
echo "xdebug.remote_enable=1" >> /etc/php/8.1/mods-available/xdebug.ini 
# echo "xdebug.remote_host=\"x.x.x.x\"" >> /etc/php/8.1/mods-available/xdebug.ini 
echo -e "-- XDEBUG configured \n"


# Composer #########################################################################
echo -e "-- Installing Composer\n"
php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('/tmp/composer-setup.php'); } echo PHP_EOL;"
php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('/tmp/composer-setup.php');"

# VARIABLES ####################################################################
echo -e "-- Moving on to Apache\n"
echo -e "-- Setting global variables\n"
APACHE_CONFIG=/etc/apache2/apache2.conf
VIRTUAL_HOST=localhost
DOCUMENT_ROOT=/var/www/html
 
# APACHE #######################################################################
echo -e "-- Installing Apache web server\n"
apt-get install -y apache2

echo -e "-- Enabling rewrite\n"
a2enmod rewrite
echo -e "-- Adding ServerName to Apache config\n"
grep -q "ServerName ${VIRTUAL_HOST}" "${APACHE_CONFIG}" || echo "ServerName ${VIRTUAL_HOST}" >> "${APACHE_CONFIG}"
 
echo -e "-- Allowing Apache override to all\n"
sed -i "s/AllowOverride None/AllowOverride All/g" ${APACHE_CONFIG}
 
echo -e "-- Restarting Apache web server\n"
service apache2 restart

echo -e "-- Set open permissions for Apache web server's docroot\n"
chown -R www-data:www-data /var/www/

# Maria-DB Server #######################################################################
echo -e "-- Installing MariadB Server\n"
echo -e "-- Setting global variables\n"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
mysql -uroot -e "CREATE DATABASE m2clocal;"
mysql -uroot -e "GRANT ALL PRIVILEGES ON m2clocal.* TO m2cdba@localhost IDENTIFIED BY 'm2cLocalPW'"


# ElasticSearch #########################################################################
echo -e "-- Installing ElasticSearch 7.6 \n"
mkdir /usr/lib/jvm 
tar -C /usr/lib/jvm -zxvf /vagrant/jdk-8u341-linux-x64.tar.gz 

echo "JAVA_HOME=\"/usr/lib/jvm/jdk1.8.0_341\"" | tee /etc/environment 
update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk1.8.0_341/bin/java" 0
update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/jdk1.8.0_341/bin/javac" 0
update-alternatives --set java /usr/lib/jvm/jdk1.8.0_341/bin/java
update-alternatives --set javac /usr/lib/jvm/jdk1.8.0_341/bin/javac


wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
apt-get install -y apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt-get update
apt-get install elasticsearch=7.6.2
service elasticsearch start
/usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-phonetic
/usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu 
service elasticsearch restart 

# Magento File System Owner #######################################################################
echo -e "-- Creating the Magento file system owner\n"
adduser magento2_user --gecos "Magento Local,,," --disabled-password
echo "magento2_user:magento2PW" | sudo chpasswd 

echo -e "-- Adding the Magento file system owner to the web server group\n"
usermod -g www-data magento2_user
service apache2 restart

# END ##########################################################################
echo -e "-- ---------------- --"
echo -e "-- END BOOTSTRAPING --"
echo -e "-- ---------------- --"