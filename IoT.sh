#!/bin/bash

##########################################
# IoT Script
# for building IoT  devices
##########################################

# Set these variables:

# You
USER=""
PASSWORD=""
EMAIL=""

# Your service account
SUSER=""
SPASSWORD=""
SEMAIL=""

# System Details
SYSNAME=""

#####################################################################################
############# Dont edit beneath here unless you know what you are doing #############
#####################################################################################

hostname $SYSTNAME

# Update the system to latest patch revision
apt update && apt upgrade -y
  
# Add the maintenance user
adduser $SUSER --gecos "$SUSER,home,127.0.0.1,127.0.0.1" --disabled-password
echo "$SUSER:$SPASSWORD" | sudo chpasswd
usermod -a -G admin $SUSER
usermod -a -G sudo $SUSER
  
# Add your user
adduser $USER --gecos "$USER,home,127.0.0.1,127.0.0.1" --disabled-password
echo "$USER:$PASSWORD" | sudo chpasswd
usermod -a -G admin $USER
usermod -a -G sudo $USER

# Fuck up the root account
RPASS = `openssl rand -base64 32`
echo "root:$RPASS" | sudo chpasswd
  
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

# Install protection ion tools
apt install -y net-tools fail2ban rkhunter

# Lets blackhole all the portscans etc
apt install psad
sed -i "s/root@localhost/$SEMAIL/g" /etc/psad/psad.conf
sed -i "s/_CHANGE_ME_/$HOSTNAME/g" /etc/psad/psad.conf
service psad restart
