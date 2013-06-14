#!/bin/bash

# Written 2013-06-14 by Fox
# (gs) Secure Backup wrapper
# script to automate support request creation

# Create backup path
SITE=$(echo $HOME | awk -F/ '{ print $3 }') 
mkdir -p /home/$SITE/data/cloudtech/backup/ && cd $_
pwd

# Run backup script
wget http://s67019.gridserver.com/backsup.py 
python backsup.py

# Echo cron job
echo -e "Here's the cron job command:"
echo -e ""
echo -e "/usr/bin/python /home/$SITE/data/cloudtech/backup/backsup.py"
echo -e ""

# Echo support request
echo -e "*** Customer Support Request***"
echo -e ""
echo -e "Thanks for your CloudTech order. The Secure Local Backup service has been configured. Backups will run every night at midnight and will be stored in the following location:"
echo -e ""
echo -e "/home/$SITE/data/cloudtech/backup"
echo -e ""

if grep -q "domain" /home/$SITE/data/cloudtech/backup/.infos 
  then
    echo -e "You will find a complete backup of the domain directory for the following websites:"
    echo -e ""
    grep -A1 "domain" /home/$SITE/data/cloudtech/backup/.infos | awk '/name/ {print $3}'
    echo -e ""
fi

if grep -q "db" /home/$SITE/data/cloudtech/backup/.infos 
  then
    echo -e "You will also find backups of the following databases:" 
    echo -e ""
    grep -A2 "db" /home/$SITE/data/cloudtech/backup/.infos | awk '/name/ {print $3}'
    echo -e ""
    echo -e "Please be aware we have configured the backup script to use the following database user credentials – if password is changed, database backups will not function properly:"
    echo -e ""
    grep -A2 "db" /home/$SITE/data/cloudtech/backup/.infos | awk '/user/ {print $3}'
    echo -e ""
fi

echo -e "Let us know if you have any further questions or concerns."
