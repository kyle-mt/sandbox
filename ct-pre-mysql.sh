#!/bin/bash

# Define Text Colors
Escape="\033";
BlackF="${Escape}[30m"
RedB="${Escape}[41m"
RedF="${Escape}[31m"
CyanF="${Escape}[36m"
Reset="${Escape}[0m"
BoldOn="${Escape}[1m"
BoldOff="${Escape}[22m"

#Define Variables
sqlConnect="mysql -A -u admin -p`cat /etc/psa/.psa.shadow`"
mysqlBin=$(which mysql)
mysqlSyntax=$($mysqlbin --help --verbose 2>&1 >/dev/null | grep -i 'error')

#Make It A Ninja Script
function finish {
    rm -f ./ct-pre-mysql.sh
}
trap finish EXIT

#Begin Script
echo -e "${CyanF}${boldOn}You should have already run the performance analysis. This script will restart MySQL, so MySQL Tuner needs to be run first." 
echo ""
echo -ne "Do You Want To Proceed? (y or n):${Reset} "
read choice1
if [ "$choice1" == "n" ] || [ "$choice1" == "N" ]
    then
        exit
fi
echo ""

#Check MySQL Syntax
if [ -n "$mysqlSyntax" ]
    then
        echo -e "${redF}${BoldOn}The MySQL configuration has the following errors:${Reset}"
        echo ""
        echo $mysqlSyntax
        echo ""
        echo -n "Do You Want To Proceed? (y or n): "
        read choice2
        echo ""
        if [ "$choice2" == "n" ] || [ "$choice2" == "N" ]
            then
                   exit
        fi
fi

#Backup config file
echo -e "${CyanF}${BoldOn}Backing Up MySQL Config File${Reset}"
echo ""
cp -vp /etc/my.cnf{,.$(date +%Y-%m-%d.otto)}
echo ""

#Backup Databases

#See If Otto Directory Exists. If so, move in there, if not, create it
if [ ! -d "/root/CloudTech" ]; then
    mkdir /root/CloudTech
fi

echo -e "${CyanF}${BoldOn}Backing Up All Databases To /root/CloudTech${Reset}"
echo ""
for i in $($sqlConnect -Nse 'show databases' | grep -v '^information_schema$'); do mysqldump -uadmin -p$(</etc/psa/.psa.shadow) --add-drop-table --hex-blob "$i" > /root/CloudTech/db-backup.$i.sql; echo "$i"; done

#Optimize Databases
echo -e "${CyanF}${BoldOn}Repairing And Optimizing Databases${Reset}"
echo ""
mysqlcheck -uadmin -p`cat /etc/psa/.psa.shadow` --auto-repair --optimize --all-databases
