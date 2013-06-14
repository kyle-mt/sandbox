#/bin/bash

###############Constants

# Define Text Colors
Escape="\033";
BlackF="${Escape}[30m"
RedB="${Escape}[41m"
RedF="${Escape}[31m"
CyanF="${Escape}[36m"
Reset="${Escape}[0m"
BoldOn="${Escape}[1m"
BoldOff="${Escape}[22m"

# Connect to PSA Database
sqlConnect="mysql -A -N -u admin -p`cat /etc/psa/.psa.shadow` psa -e"
servDef=""
divider="${RedF}*******************************************************************${Reset}"
q="/var/qmail/bin/qmail-qstat"

##Functions
function init {
echo -e "Welcome to (mt) Media Temple Security Audit tool."
echo -e "If two dividing bars are shown without results, no results were returned"
echo -e "$divider"

mta
service_check
}

function service_check {
if [ ! -d /var/www/vhosts ]
then 
##(gs) Grid-Service
servDef="gs"
site_id=`echo $PWD |awk -F/ '{ print $3 }'`
else
##(dv) Dedicated-Virtual Server
servDef="dv"
fi
}

function mta {
if [ ! -d /var/qmail/control ]
then
mta="postfix"
else
mta="qmail"
fi
}

function port_check {
if [ "$servDef" == "dv" ]
then
echo -e "${BoldOn}Below are a list of stange ports.${BoldOff}"
echo -e "$divider"
netstat -pln | grep -v "xfs\|Proto RefCnt Flags\|sw-engine\|Active UNIX\|Proto Recv-Q Send-Q Local Address\|Active Internet connections (only servers)\|:3306\|:7080\|:7081\|:10001\|:53\|:22\|:443\|:8443\|:21\|:953\|:993\|:995\|:8880\|:106\|:110\|:143\|:465\|:80\|:25\|master\|mysql.sock\|/tmp/spamd_full.sock\|php-cgi\|psa-pc-remote\|/var/run/dbus/system_bus_socket\|fail2ban.sock\|saslauthd/mux"
fi
}

function rootssh_accepted {
if [ "$servDef" == "dv" ]
then
echo -e "$divider"
echo -e "${BoldOn}Sucessful root logins${BoldOff}"
echo -e "$divider"
echo "Count IP"
cat /var/log/secure* | grep "root" | grep "Accepted" | egrep -v "72.10.62.1|192.168.20" | awk '{ print $11 }' | sort | uniq -c | sort -nr
echo -e "$divider"
fi
}

function mail_count {
if [ "$servDef" == "dv" ]
then
echo -e "$divider"
echo -e "${BoldOn}Mail Queue Check${BoldOff}"
if [ "$servDef" == "dv" ]
then
if [ "$mta" == "postfix" ]
then 
echo "This is Postfix"
echo -e "$divider"
pqueue_count=`postqueue -p | tail -n 1 | cut -d' ' -f5`
if [ -z "$pqueue_count" ]
then 
echo "Queue is empty"
echo -e "$divider"
else
echo "Mail in queue: $pqueue_count"
echo -e "$divider"
fi
fi
else
echo "This is qMail"
echo -e "$divider"
qqueue_count=`$q`
if [ "$qqueue_count" == "0" ]
then 
echo "Queue is empty"
echo -e "$divider"
else
echo "Mail in queue: $qqueue_count"
echo -e "$divider"
fi
fi
fi
}

function user_check {
if [ "$servDef" == "dv" ]
then
#Build User List From PSA DB
user_list="("
for i in $($sqlConnect 'select login from sys_users')
        do 
        user_list="$user_list$i|"
        done

#get rid of last | and end the user list
user_list=$(sed 's/\(.*\)|/\1/' <<< $user_list)
user_list="$user_list)"

echo "Below are system users that have shell access"
echo -e "${BoldOn}${CyanF}Users that always have access, such as root are excluded.${Reset}"
echo -e "$divider"
echo -e "${BoldOn}The Following Users Were Not Created In Plesk, But Have Shell Access. They are potentially a ${RedF}HIGH${Reset}${BoldOn} security risk:${BoldOff}"
echo -e "$divider"
shell_user_high=`cat /etc/passwd | grep "/bin/bash" | grep -v "root:x:0:0\|mysql:x:27:27" | egrep -v $user_list`
echo -e "$shell_user_high"
echo -e "$divider"
echo -e "${BoldOn}The Following Users Have Shell Access, But Were Created Legitimately. They are a ${CyanF}LOW${Reset}${BoldOn} security risk:${BoldOff}"
echo -e "$divider"
shell_user_low=`cat /etc/passwd | grep "/bin/bash" | grep -v "root:x:0:0\|mysql:x:27:27" | egrep $user_list`
echo "$shell_user_low"
fi
}

function cms_check {
wp_version=`curl -s http://api.wordpress.org/core/version-check/1.4/ | grep "^[0-9]" | head -1`
joomla_version=`curl --silent http://www.joomla.org/download.html | grep -m 1 "newest version" | awk -F'Joomla' '{print $2}' | awk '{print $1}'`

if [ "$servDef" == "dv" ]
then
	docRoot="/var/www/vhosts/*/"
elif [ "$servDef" == "gs" ]
then
	docRoot="/home/$site_id/domains/*/"
else
	echo "An error occured. There is no service definition."
fi
echo "If script contines without listing version, this means no CMS's of that type were found"
echo -e $divider
echo -e  "Below are the ${RedF}OUT OF DATE${Reset} WordPress versions."
echo -e $divider
outdated_wp=`find $docRoot -name 'version.php' | xargs grep "wp_version =" | grep -v "$wp_version"`
echo "$outdated_wp"
echo -e $divider
echo -e "Below are the ${RedF}OUT OF DATE${Reset} Joomla versions."
echo -e $divider
outdated_joomla=`find $docRoot -name 'version.php' | xargs grep -F 'public $RELEASE' | grep -v "$joomla_version"`
echo "$outdated_joomla"
echo -e $divider
echo -e "Below are ${RedF}ALL${Reset} installed Drupal versions."
echo -e $divider
find $docRoot -name "bootstrap.inc" -type f -print -exec egrep "'VERSION'" '{}' \;
#echo "Durpal Checker is a work in progress... CHECK BACK LATER"
echo -e $divider
}

function perm_check {
if [ "$servDef" == "dv" ]
then
echo "The Following Directories Inside Of /var/www/ Have 777 Permissions:"
echo -e "$divider"
perm_dir=`find /var/www/ ! -path \*/anon_ftp\* -type d -perm 0777`
echo -e "$perm_dir"
echo -e "$divider"
echo "The Following Files Inside Of /var/www/ Have 777 Permissions:"
echo -e "$divider"
perm_file=`find /var/www/ ! -path \*/anon_ftp\* -type f -perm 0777`
echo -e "$perm_file"
echo -e "$divider"
else 
echo "The Following Directories Inside Of /var/www/ Have 777 Permissions:"
echo -e "$divider"
perm_dir=`find /home/$site_id/domains/ ! -path \*/anon_ftp\* -type d -perm 0777`
echo -e "$perm_dir"
echo -e "$divider"
echo "The Following Files Inside Of /var/www/ Have 777 Permissions:"
echo -e "$divider"
perm_file=`find /home/$site_id/domains/  ! -path \*/anon_ftp\* -type f -perm 0777`
echo -e "$perm_file"
echo -e "$divider"
fi
}

function hiddendir {
if [ "$servDef" == "dv" ]
then
echo -e "The following are a list of hidden directories in /root and /tmp that MAY be suspicious!"
echo -e "$divider"
find /root -type d -name ".*" | egrep -v "autoinstaller|ssh|pki"
find /tmp -type d -name ".*" | egrep -v "ICE-unix|font-unix"
echo -e "$divider"
fi
}

function ssh_port_check {
if [ "$servDef" == "dv" ]
then
ssh_port=`netstat -pln | egrep "ssh|sshd" | head -1 | awk '{print $4}' | awk -F: '{print $2}'`
	if [ "$ssh_port" == "22" ]
	then ssh_check="true"
	else
	ssh_check="false"
	fi 
fi
}

function fail2ban_checker {
	if [ "$servDef" == "dv" ]
then
fail2ban_socket=`netstat -pln | grep "fail2ban.sock"`
if [ ! -z "$fail2ban_socket" ]
then
fail2ban_check="true"
else
fail2ban_check="false"
fi
fi
}

function mysqld_ext_checker {
if [ "$servDef" == "dv" ]
then
mysqld_checker=`netstat -pln | grep "mysqld" | head -1 | awk '{print $4}'`
if [ "$mysqld_checker" == "0.0.0.0:3306" ]
        then mysqld_check="true"
        else
        mysqld_check="false"
        fi
fi
}

function support_request {
echo -e "Please copy the below support request responce"
echo -e "$divider"
echo -e "Thank you for ordering a (mt) Media Temple Security Audit. Security is our top priority and we believe the following infomation will result in a much more secure enviroment for your websites and server."
echo ""
if [ "$servDef" == "dv" ]
then
	if [ "$ssh_check" == "true" ]
	then
echo -e "+ If proper security measures are not followed the SSH service can result in a root level comprimse of your server. While the standard port for SSH is port number 22, it can greatly increase your security to change this port number to an alternative port number over '1000'. Currently, your SSH port number is $ssh_port. If you would like (mt) Media Temple to change your SSH port number, we can do so under the CloudTech Intrusion Prevention service." 
echo ""
	else
echo -e "+ If proper security measures are not followed the SSH service can result in a root level comprimse of your server. It appears someone has already changed your SSH port to a port other than port number 22. This step aligns with securtiy best practices."
echo ""
fi
fi
if [ "$servDef" == "dv" ]
then
if [ ! -z "$shell_user_low" ] || [ ! -z "$shell_user_high" ]
then 
echo "+ The following users have shell access to your server. If you do not reconigze the below usernames , you may want to ask a Linux Securtiy Profession to audit your server as this may be a sign of a root level comprimise. If any users should no longer have shell access, they should be removed."
echo ""
fi
if [ ! -z "$shell_user_low" ]
then
echo "Below are a list of the shell users that were created via Plesk. Generally these users have a low risk of being malicious; however, if you do not reconigze these users, as noted above, they should be investigated."
echo ""
echo "$shell_user_low"
echo ""
fi
if [ ! -z "$shell_user_high" ]
then
echo "[Action Recommended] Below are a list of shell users that were created outside of Plesk. Generally, these users have a higher risk of being malicious; however, if you do not reconigze these users, as noted above, they should be investigated."
echo ""
echo "$shell_user_high"
echo ""
fi
fi
if [ ! -z "$perm_dir" ] || [ ! -z "$perm_file" ]
then
echo "+ [Action Needed] Another major security concern are files and directories with weak persmissions. According to security best practices all directories should have 755 permissions and files should have 644 permissions. Below are a list of items we found that have very loose permissions and/or ownerships."
echo ""
if [ ! -z "$perm_dir" ]
then
echo "Below are a list of directories that have 777 permissions."
echo ""
echo -e "$perm_dir"
echo ""
fi
if [ ! -z "$perm_file" ]
then
echo "Below are a list of files that have 777 permissions."
echo ""
echo -e "$perm_file"
echo ""
fi
fi
echo "+ Outdated versions of web applications, such as WordPress or Joomla often cause websites to be comprimised. Generally speaking, anything other than the most current version of an application is vulnerable to some form of attack. We were able to run a scan for outdated versions of the above two web applications. If you are running any other applications, it is suggested that you ensure all installations are up-to-date."
echo ""
if [ ! -z "$outdated_wp" ] || [ ! -z "$outdated_joomla" ]
then
echo "[Action Needed] We were able to find one or more outdated versions of common web applications on your server. We suggest you update all of the below applications to their current version."
echo ""
if [ ! -z "$outdated_wp" ]
then
echo "The current version of WordPress is "$wp_version". We highly suggest you update all of the below WordPress versions, as they are out of date:"
echo ""
echo "$outdated_wp"
echo ""
fi
if [ ! -z "$outdated_joomla" ]
then
echo -e "The current version of Joomla is "$joomla_version". We highly suggest you update all of the below Joomla versions, as they are out of date:"
echo ""
echo "$outdated_joomla"
echo ""
fi
else 
echo "We were not able to find any outdated versions of WordPress or Joomla."
echo ""
fi
if [ "$servDef" == "dv" ]
then
echo "+ Many server side applications can increase the security of your server. Fail2Ban is an open-source, python based, piece of software which will monitor your server brute force attempts on passwords and even some type of DDoS attacks."
echo ""
if [ "$fail2ban_check" == "true" ]
then
echo "We have been able to confirm you do have Fail2Ban installed. This is a very important step and we commend you for taking a proactive approach to security."
echo ""
else
echo "[Action Needed] We have been able to confirm that it does not appear you are using Fail2Ban on your server. The addition of Fail2Ban will almost complete eliminate the changes of a brute force attack being sucessful, assuming your passwords are reasonably strong. We highly suggest that all customers utalize this application. Should you wish for (mt) Media Temple to configure Fail2Ban to block brute force attacks on the SSH, FTP and Mail services, we can do so for you. Details on the pricing of this service will be near the bottom of this support request."
echo ""
fi
fi
if [ "$servDef" == "dv" ]
then
echo "+ If you do not have the need to make remote connections to MySQL, it is suggested that the 'skip-networking' value be added to your '/etc/my.cnf' file."
echo ""
if [ "$mysqld_check" == "false" ]
then
echo "We have been able to confirm that MySQL is not listen externally, so no further action is needed."
echo ""
else
echo "[Action Needed] We have been able to confirm that MySQL is listening externally. If you need this to occur, it would be suggested that custom firewall rules be added to ensure only connections from a trusted IP are allowed. If you would like (mt) Media Temple can do this for you if you provide a list of allowed IP's. Keep in mind, if your IP address changes, you will not be able to access MySQL externally."
echo ""
fi
fi
if [ "$fail2ban_check" == "false" ] || [ "$mysqld_check" == "true" ]
then
echo "If you would like our professional assistance with resolution to these issues CloudTech On-Demand can provide the following services:"
echo ""
fi
if [ "$fail2ban_check" == "false" ]
then 
echo '* Intrusion Prevention for Fail2Ban Installation - $79'
echo ""
fi
if [ "$mysqld_check" == "true" ]
then
echo '* MySQL Optimization - $79 or Custom Firewall Rules - $79 for securing MySQL by either disabling external access or adding custom firewall rules. Keep in mind, under MySQL Optimization, we will also tune your MySQL installation for maximum performance.'
echo ""
fi
echo "If you require any further assistance, please do not hesitate to contact us by replying to this support request, or by calling us at 877-578-4000. We are here 24/7 to assist you. Thank you for continuing to use (mt) Media Temple for your hosting needs."
echo -e "$divider"
}
##End Functions

## Preflight ##
clear
init
user_check
rootssh_accepted
port_check
hiddendir
mail_count
ssh_port_check
##Audit
echo -e "Main Audit now starting. Please wait..."
echo ""
cms_check
perm_check
fail2ban_checker
mysqld_ext_checker
##Report
support_request
rm -rf ./s_audit.sh
