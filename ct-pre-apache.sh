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

# cleanup function in case of premature termination
function finish {
    rm -f ./ct-pre-apache.sh
}
trap finish EXIT

#Define Variables
ramCount=`awk 'match($0,/vmguar/) {print $4}' /proc/user_beancounters`
ramBase=-16 && for ((;ramCount>1;ramBase++)); do ramCount=$((ramCount/2)); done

#Otto Apache Pre-Tune Script
echo -e "${CyanF}${BoldOn}Backing Up Configuration Files...${Reset}"
echo ""
cp -vp /etc/httpd/conf/httpd.conf{,.$(date +%Y-%m-%d.ct)}
cp -vp /etc/php.ini{,.$(date +%Y-%m-%d.ct)}
cp -vp /etc/httpd/conf.d/fcgid.conf{,.$(date +%Y-%m-%d.ct)}
echo ""
echo -e "${CyanF}${BoldOn}Checking Apache Status${Reset}"
echo ""
apacheStatus=$(/etc/init.d/httpd status | grep 'running')  
if [ -z "$apacheStatus" ]
    then
        echo -e "${RedF}${BoldOn}Apache is not running!${Reset}"
        echo ""
        echo -n "Do You Want To Proceed? (y or n):"
        read proceedChoice
        if [ "$proceedChoice" == "n" ] || [ "$proceedChoice" == "N" ]
            then
                exit
        fi
else
   echo $apacheStatus
fi
echo ""
apacheTest=$(httpd -t 2>&1)
if [ "$apacheTest" == "Syntax OK" ]
    then
        echo "$apacheTest"
else
	echo -e "${RedF}${BoldOn}Apache Configuration File Has Invalid Syntax...${Reset}"
        echo ""
        echo "$apacheTest"
        echo ""
        echo -n "Do You Want To Proceed? (y or n):"
        read proceedChoice
        if [ "$proceedChoice" == "n" ] || [ "$proceedChoice" == "N" ]
            then
                exit
        fi
fi
echo ""
echo -e "${CyanF}${BoldOn}Current Prefork Settings:${Reset}"
echo "" 
export printIt="false"
while read i
        do
                if [ "$printIt" == "true" ]
                  then
                    echo $i
                fi
                if [ "$i" == "<IfModule prefork.c>" ]
                   then
                  export  printIt="true"
                elif [ "$i" == "</IfModule>" ]
                   then
                  export  printIt="false"
                fi
        done < /etc/httpd/conf/httpd.conf
echo ""
#Check For KeepAlive
echo -ne "${CyanF}${BoldOn}KeepAlive is " 
cat /etc/httpd/conf/httpd.conf | egrep '(KeepAlive On|KeepAlive Off)' | awk '{ print $2 }'
echo -e "${Reset}"
#See Which Modules Are Disabled
disabledMods=$(cat /etc/httpd/conf/httpd.conf | grep '#LoadModule' | awk '{ print $2 }')
if [ -n "$disabledMods" ]
   then
       echo -e "${CyanF}${BoldOn}The Following Apache Modules are Disabled:${Reset}"
       echo "" 
       echo "$disabledMods" 
fi
echo ""

echo -e "${CyanF}${BoldOn}Adjusting Current Apache Settings....${Reset}"
echo ""

perl -0 -p -i -e 's/(\<IfModule\sprefork\.c\>(\n|[^\n])*?StartServers\s*?)\s\d+/\1\ '"$ramBase"'/;' \
-e 's/(\<IfModule\sprefork\.c\>(\n|[^\n])*?MinSpareServers\s*?)\s\d+/\1\ '"$ramBase"'/;' \
-e 's/(\<IfModule\sprefork\.c\>(\n|[^\n])*?MaxSpareServers\s*?)\s\d+/\1\ '"$(($ramBase*2 + 1))"'/;' \
-e 's/(\<IfModule\sprefork\.c\>(\n|[^\n])*?ServerLimit\s*?)\s\d+/\1\ '"$(( 50 + (($ramBase**2)*10) + (($ramBase-2)*10) ))"'/;' \
-e 's/(\<IfModule\sprefork\.c\>(\n|[^\n])*?MaxClients\s*?)\s\d+/\1\ '"$(( 50 + (($ramBase**2)*10) + (($ramBase-2)*10) ))"'/;' \
-e 's/(\<IfModule\sprefork\.c\>(\n|[^\n])*?MaxRequestsPerChild\s*?)\s\d+/\1\ '"$(( 2048 + ($ramBase*256) ))"'/;' /etc/httpd/conf/httpd.conf 

echo ""
echo -e "${CyanF}${BoldOn}New Prefork Settings:${Reset}"
echo ""
export printIt="false"
while read i
        do
                if [ "$printIt" == "true" ]
                  then
                    echo $i
                fi
                if [ "$i" == "<IfModule prefork.c>" ]
                   then
                  export  printIt="true"
                elif [ "$i" == "</IfModule>" ]
                   then
                  export  printIt="false"
                fi
        done < /etc/httpd/conf/httpd.conf
echo ""

#Check For Python and Perl Scripts within doc root of domains. If not present, disable these Apache Mods.
echo -e "${CyanF}${BoldOn}Checking For Python Scripts${Reset}"
echo ""
pythonFiles=$(find /var/www/vhosts -type f -name "*.py" | grep -v 'test')
if [ -z "$pythonFiles" ]
   then
       echo "Disabling Python Modules"
       echo "" 
       fileChange=$((mv /etc/httpd/conf.d/python.conf /etc/httpd/conf.d/python.conf-disabled) 2>&1)
       if [ -n "$fileChange" ]
           then 
           echo "Python Module Was Disabled"
       else
           echo -e "${RedF}${BoldOn}Python Module Was Already Disabled${Reset}"
       fi
       echo ""
else
     echo ""
     echo -e "${RedF}${BoldOn}Python Scripts Were Found... module will not be disabled${Reset}"
     echo ""
fi
echo -e "${CyanF}${BoldOn}Checking For Perl Scripts${Reset}"
echo""
perlFiles=$(find /var/www/vhosts -type f -name "*.pl" | grep -v 'test')
if [ -z "$perlFiles" ]
    then
       echo -e "${CyanF}${BoldOn}Disabling Perl Module${Reset}"
       echo ""
       fileChange=$(mv /etc/httpd/conf.d/perl.conf /etc/httpd/conf.d/perl.conf-disabled 2>&1)
       if [ -n "$fileChange" ]
           then 
           echo "Perl Module Was Disabled"
       else
           echo -e "${RedF}${BoldOn}Perl Module Was Already Disabled${Reset}"
       fi
else
     echo ""
     echo -e "${RedF}${BoldOn}Perl Scripts Were Found... module will not be disabled${Reset}"
fi
echo ""

#Disable Other Modules
echo -e "${CyanF}${BoldOn}Disabling Additional Apache Modules...${Reset}"
echo ""
perl -0 -p -i \
-e 's/\#?(LoadModule\ authn_alias_module\ modules\/mod_authn_alias\.so)/#\1/;' \
-e 's/\#?(LoadModule\ authn_anon_module\ modules\/mod_authn_anon\.so)/#\1/;' \
-e 's/\#?(LoadModule\ authn_dbm_module\ modules\/mod_authn_dbm\.so)/#\1/;' \
-e 's/\#?(LoadModule\ authnz_ldap_module\ modules\/mod_authnz_ldap\.so)/#\1/;' \
-e 's/\#?(LoadModule\ authz_dbm_module\ modules\/mod_authz_dbm\.so)/#\1/;' \
-e 's/\#?(LoadModule\ authz_owner_module\ modules\/mod_authz_owner\.so)/#\1/;' \
-e 's/\#?(LoadModule\ cache_module\ modules\/mod_cache\.so)/#\1/;' \
-e 's/\#?(LoadModule\ dav_module\ modules\/mod_dav\.so)/#\1/;' \
-e 's/\#?(LoadModule\ dav_fs_module\ modules\/mod_dav_fs\.so)/#\1/;' \
-e 's/\#?(LoadModule\ disk_cache_module\ modules\/mod_disk_cache\.so)/#\1/;' \
-e 's/\#?(LoadModule\ ext_filter_module\ modules\/mod_ext_filter\.so)/#\1/;' \
-e 's/\#?(LoadModule\ file_cache_module\ modules\/mod_file_cache\.so)/#\1/;' \
-e 's/\#?(LoadModule\ info_module\ modules\/mod_info\.so)/#\1/;' \
-e 's/\#?(LoadModule\ ldap_module\ modules\/mod_ldap\.so)/#\1/;' \
-e 's/\#?(LoadModule\ mem_cache_module\ modules\/mod_mem_cache\.so)/#\1/;' \
-e 's/\#?(LoadModule\ status_module\ modules\/mod_status\.so)/#\1/;' \
-e 's/\#?(LoadModule\ speling_module\ modules\/mod_speling\.so)/#\1/;' \
-e 's/\#?(LoadModule\ usertrack_module\ modules\/mod_usertrack\.so)/#\1/;' \
-e 's/\#?(LoadModule\ version_module\ modules\/mod_version\.so)/#\1/;' /etc/httpd/conf/httpd.conf

echo -e "${CyanF}${BoldOn}Modules Now Disabled:${Reset}"
echo ""
disabledMods=$(cat /etc/httpd/conf/httpd.conf | grep '#LoadModule' | awk '{ print $2 }')
if [ -n "$disabledMods" ]
   then 
       echo "" 
       echo "$disabledMods" 
fi
echo ""

apacheTest=$(httpd -t 2>&1)

if [ "$apacheTest" == "Syntax OK" ]
    then
       echo -e "${CyanF}${BoldOn}Restarting Apache${Reset}"
       echo ""
       /etc/init.d/httpd restart
       echo ""
else
    echo ""
    echo -e "${RedF}${BoldOn}There is an Error in The Apache Config File... Not Restarting. Here's the error message:${Reset}"
    echo ""
    echo "$apacheTest"
    echo ""
fi
