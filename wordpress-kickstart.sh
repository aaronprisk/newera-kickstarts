#!/bin/bash
#wordpress kickstart
#Copyright 2016 Aaron Prisk 2016

if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi                     

clear
echo "		        @,        "
echo "		     @@@@@@@    @ "
echo "		    @@    ;@@     "
echo "		   @'   ;,  @@   #"
echo "		  @#  @@@@@ '@@  @"
echo "		  @  @@@@@@@ @@  @"
echo "		 :+  @@@@@@@@@@  @"
echo "		 #   @@@@@@@@@;  @"
echo "		 #   @@'@@@@@@  @;"
echo "		 '   @@ @@@@@   @ "
echo "		  .  @@@  ;,   @, "
echo "		  @   @@@    #@'  "
echo "		  .    @@@@@@@    "
echo "		   +     .@,      "
echo "                  "
echo "		NEW ERA WEB KICKSTART"
echo "		Wordpress Server V1.0"         
echo "---------------------------------------------------------"  
echo "This tool performs common post-deployment configurations" 
echo "for a production Wordpress server."
echo "---------------------------------------------------------"
read -s -n 1 -p "PRESS ANY KEY TO BEGIN SETUP..."
echo
echo "**FAIL2BAN SETUP**"
echo "* Installing fail2ban"
sudo apt install fail2ban -y

echo "USER INPUT NEEDED: Fail2ban has an ignoreip section for"
echo "trusted IP address. Please enter safe IPs in CIDR notation"
echo "(EX: 55.55.55.55/28 10.10.10.0/24):"
read safeip

echo "You entered: $safeip"
while true; do
    read -p "Does this look correct? (y|n)" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Please enter safe IPs in CIDR notation"
		echo "(EX: 55.55.55.55/28 10.10.10.0/24):"
		read safeip;;
        * ) echo "Please answer yes or no.";;
    esac
done


echo "* Creating local jail"
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i "s/ignoreip = 127.0.0.1/8/ignoreip = 127.0.0.1/8 $safeip/" /etc/fail2ban/jail.local

echo "* Installing wp-fail2ban filters"
cp wp-fail2ban/wordpress-hard.conf /etc/fail2ban/filter.d/

echo "* Adding filter to jail config"
cat <<EOT >> /etc/fail2ban/jail.local
[wordpress-hard]
enabled = true
filter = wordpress-hard
logpath = /var/log/auth.log
maxretry = 3
port = http,https
EOT

echo "**WORDPRESS SETUP**"
echo "* Enabling DO block-xmlrpc module"
sudo a2enconf block-xmlrpc

echo "* Installing Google Pagespeed"
wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb
sudo dpkg -i mod-pagespeed-*.deb

echo "USER INPUT NEEDED: The htaccess requires allowed IP(s) for"
echo "Wordpress login. Please enter safe IPs in NON-CIDR format"
echo "(EX: 55.55.55.55 10.10.10.0):"
read trustedip

echo "You entered: $trustedip"
while true; do
    read -p "Does this look correct? (y|n)" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Please enter safe IPs in NON-CIDR notation"
		echo "(EX: 55.55.55.55 10.10.10.10):"
		read trustedip;;
        * ) echo "Please answer yes or no.";;
    esac
done


echo "* Installing WP hardening .htaccess file"
sudo cp apache/htaccess /var/www/html/.htaccess
sed -i "s/TRUSTEDIP/$trustedip/g" /var/www/html/.htaccess

echo "Setting Owners and Permissions"
sudo chown -R www-data:www-data /var/www/html
sudo chmod 644 /var/www/html/.htaccess

echo "* Changing default SSH port"
sed -i "s/Port 22/Port 7777/g" /etc/ssh/sshd_config

echo "* Configuring UFW"
sudo ufw allow 80
sudo ufw allow 7777

echo "* Restarting services"
sudo service apache2 restart
sudo service fail2ban restart
sudo service ufw restart

echo "---------------------------------------------------------"
echo "Kickstart script has completed! 
read -s -n 1 -p "PRESS ANY KEY TO BEGIN EXIT..."
