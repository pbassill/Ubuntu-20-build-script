#!/bin/bash

# Set these variables:

# You
USER=""
PASSWORD=""
EMAIL=""

# Your service account
SUSER=""
SPASSWORD=""

# Update the system to latest patch revision
apt update && apt upgrade -y
  
# Add the maintenance user
adduser $SUSER --gecos "$SUSER,home,127.0.0.1,127.0.0.1" --disabled-password
echo "$SUSER:$SPASSWORD" | sudo chpasswd
usermod -a -G admin redqueen
usermod -a -G sudo redqueen
  
# Add your user
adduser $USER --gecos "$USER,home,127.0.0.1,127.0.0.1" --disabled-password
echo "$USER:$PASSWORD" | sudo chpasswd
usermod -a -G admin peter
usermod -a -G sudo peter
  
# Add in the monitoring
echo "#!/bin/bash" > /etc/cron.daily/monitoring
echo "/usr/sbin/monitor 2>&1 | tee /tmp/$HOSTNAME.txt | mail -s \"Monitoring script for: $HOSTNAME\" $EMAIL" >> /etc/cron.daily/monitoring
chmod +x /etc/cron.daily/monitoring
cp conf/monitor /usr/sbin/monitor
chmod +x /usr/sbin/monitor
  
# Effectively remove the root user from circulation
cp conf/chgrt /etc/cron.daily
chmod +x /etc/cron.daily/chgrt
  
# Enable network level firewall
cp conf/ufw /etc/default/ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable
  
# Hardened SSH service
cp conf/sshd_config /etc/ssh/sshd_config
service ssh restart

# Install postfix mail server to send emails
apt install postfix
cp conf/main.cf /etc/postfix/main.cf
service postfix restart

# Install apache2 webserver
apt install -y apache2 libapache2-mod-security2 libapache2-mod-evasive 
apt install -y mcrypt php php-mysql php-mbstring php-curl php-gd php-tokenizer php-json php-xml php-zip php-imagick php-fpdf php-tcpdf
cp conf/apache2.conf /etc/apache2

## Enable WAF in Apache2 using mod_security
cp conf/modsecurity.conf /etc/modsecurity/modsecurity.conf 
mv /usr/share/modsecurity-crs /usr/share/modsecurity-crs.bk
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /usr/share/modsecurity-crs
cp conf/crs-setup.conf /usr/share/modsecurity-crs/crs-setup.conf

## Enable DDoS Protection in Apache2
mkdir /var/log/mod_evasive 
chown -R www-data:www-data /var/log/mod_evasive
cp conf/security.conf /etc/apache2/conf-available/security.conf
cp conf/evasive.conf /etc/apache2/conf-available/evasive.conf

## Enable source IP logging
cp conf/remoteip.conf /etc/apache2/conf-available/remoteip.conf

## Only permit HTTPS from CloudFlare at a network level
cp conf/cloudflare /etc/cron.daily
chmod +x /etc/cron.daily/cloudflare  

a2enmod ssl
a2enmod headers
a2enmod rewrite
a2enmod remoteip
service apache2 restart

# Hardened MySQL Database
apt install mysql-server
mysql_secure_installation

# Now we have Ubuntu 20.04 LTS with Apache, PHP and MYSQL. The web service is locked to Cloudflare only
# so you can use cloudflare your primary WAF and tune mod_security for fine grain protection. 
# Next we look at proactive protection.

apt install -y net-tools fail2ban rkhunter

# Lets blackhole all the portscans etc
apt install psad
sed -i "s/root@localhost/$EMAIL/g" /etc/psad/psad.conf
sed -i "s/_CHANGE_ME_/$HOSTNAME/g" /etc/psad/psad.conf
service psad restart


	
