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
reportFileName="ct_performance_results-$(date +%Y-%m-%d)"
reportFile="/root/CloudTech/$reportFileName"
apiUser="tstein@mediatemple.net"
apiKey="52cd8a6a19f1890b5590dcce2946c96e"
cwd=$(pwd)
testMonth=$(date | awk '{ print $2 }')
lastMonth=$(date -d"1 month ago" | awk '{ print $2 }')
testYear=$(date | awk '{ print $6 }')
scriptName="ctanalysis.sh"
sqlConnect="mysql -A -t -u admin -p`cat /etc/psa/.psa.shadow` psa -e"
mysqlBin=$(which mysql)
mysqlSyntax=$($mysqlbin --help --verbose 2>&1 >/dev/null | grep -i 'error')

# cleanup function in case of premature termination
function finish {
     rm -f ctanalysis.sh
}

trap finish EXIT

#See If Otto Directory Exists. If so, move in there, if not, create it
if [ ! -d "/root/CloudTech" ]; then
    mkdir /root/CloudTech
    touch /root/CloudTech/$reportFileName
fi

#BEGIN MAIN SCRIPT
clear
echo -e "${RedF}${BoldOn}Welcome To The Otto Performance Analysis Tool! Boo-ya-kasha!${Reset}"
echo ""
echo -n "Enter The Domain Name (or N if you do not want a GTMetrix Report): "
read domainName
echo ""
echo -n "Test Performed on " >> $reportFile
date >> $reportFile
echo "" >> $reportFile

#Get Version Info
echo -e "${CyanF}${BoldOn}SOFTWARE VERSIONS:${Reset}" | tee -a $reportFile
echo "" | tee -a $reportFile
echo "Plesk: $(cat /usr/local/psa/version)" | tee -a $reportFile
echo "" | tee -a $reportFile
echo "PHP: $(php -v)" | tee -a $reportFile
echo "" | tee -a $reportFile
echo "MySQL: $(mysql -V)" | tee -a $reportFile
echo "" | tee -a $reportFile

#Websites On The Server
echo "-------------------------------------------------------------" | tee -a $reportFile
echo "" | tee -a $reportFile
echo -e "${CyanF}${BoldOn}LIST OF DOMAINS:${Reset}" | tee -a $reportFile
echo "" | tee -a $reportFile
echo -e "${RedF}DOMAINS:${Reset}" | tee -a $reportFile
    echo "" | tee -a $reportFile
    $sqlConnect 'select domains.id,domains.name,domains.htype,hosting.www_root,hosting.php_handler_type,sys_users.login,webspace_id from domains join hosting on hosting.dom_id=domains.id join sys_users on sys_users.id=hosting.sys_user_id' | tee -a $reportFile
    echo "" | tee -a $reportFile
    echo -e "${RedF}DOMAIN ALIASES:${Reset}" | tee -a $reportFile
    echo "" | tee -a $reportFile
    $sqlConnect 'select domainaliases.name,domains.name,domainaliases.status,domainaliases.dns,domainaliases.mail,domainaliases.web,domainaliases.tomcat from domainaliases join domains on domainaliases.dom_id=domains.id' | tee -a $reportFile
    echo "" | tee -a $reportFile
echo "-------------------------------------------------------------" | tee -a $reportFile
echo ""

#Do MySQL Analysis
echo -e "${RedF}${BoldOn}Analyzing MySQL...${Reset}" | tee -a $reportFile
echo "" | tee -a $reportFile
#mysqltuner
echo -e "${CyanF}${BoldOn}MySQLTuner Results:${Reset}" | tee -a $reportFile
echo "-------------------------------------------------------------" | tee -a $reportFile
echo "" | tee -a $reportFile
echo "" | tee -a $reportFile
wget --quiet --no-check-certificate http://mysqltuner.pl/mysqltuner.pl 
perl mysqltuner.pl | tee -a $reportFile
rm -f mysqltuner.pl
echo "" | tee -a $reportFile
#mysqlreport
echo -e "${CyanF}${BoldOn}MySQL Report Results:${Reset}${BoldOff}" | tee -a $reportFile
echo "-------------------------------------------------------------" | tee -a $reportFile
echo "" | tee -a $reportFile
echo "" | tee -a $reportFile
wget --quiet --no-check-certificate https://raw.github.com/mediatemplecs/mt-cs-scripts/master/mysqlreport.pl 
chmod +x mysqlreport.pl 
perl mysqlreport.pl --user admin --password `cat /etc/psa/.psa.shadow` | tee -a /dev/tty $reportFile
rm -f mysqlreport.pl
echo "" | tee -a $reportFile

#Check For Slow Queries
slowLogFile=$(cat /etc/my.cnf | grep 'log_slow_queries' | awk 'BEGIN { FS = "=" } ; { print $2 }' )
if [ "$slowLogFile" == "" ]
  then 
     echo "-------------------------------------------------------------" | tee -a $reportFile
     echo "" | tee -a $reportFile
     echo "Slow Query Logging Is Not Currently Enabled" | tee -a $reportFile
     echo "-------------------------------------------------------------" | tee -a $reportFile
     echo "" | tee -a $reportFile
else
    echo -e "${CyanF}${BoldOn}Printing The Slowest Queries In The Slow Query Log:${Reset}${BoldOff}" | tee -a $reportFile
    echo "-------------------------------------------------------------" | tee -a $reportFile
    echo "" | tee -a $reportFile
    echo "" | tee -a $reportFile
    mysqldumpslow -r -a /var/log/mysqld.slow.log | tail | tee -a /dev/tty $reportFile
fi
echo "" | tee -a $reportFile
echo "" | tee -a $reportFile

#BEGIN APACHE ANALYSIS
echo -e "${RedF}${BoldOn}Analyzing Apache...${Reset}" | tee -a $reportFile
echo "" | tee -a $reportFile
echo "" | tee -a $reportFile
echo -e "${RedF}${BoldOn}CONFIGURATION${Reset}" | tee -a $reportFile
echo "-------------------------------------------------------------" | tee -a $reportFile
echo "" | tee -a $reportFile
echo "" | tee -a $reportFile
echo -e "${CyanF}${BoldOn}PREFORK SETTINGS:${Reset}" | tee -a $reportFile
echo "" | tee -a $reportFile
export printIt="false"
while read i 
	do        
		if [ "$printIt" == "true" ]
                  then
                    echo $i | tee -a $reportFile
		fi
		if [ "$i" == "<IfModule prefork.c>" ]
                   then
                  export  printIt="true"
                elif [ "$i" == "</IfModule>" ]
                   then
		  export  printIt="false"
		fi
	done < /etc/httpd/conf/httpd.conf
echo "" | tee -a $reportFile
#Check For KeepAlive
echo -ne "${CyanF}${BoldOn}KeepAlive is " | tee -a $reportFile
cat /etc/httpd/conf/httpd.conf | egrep '(KeepAlive On|KeepAlive Off)' | awk '{ print $2 }' | tee -a $reportFile
echo -e "${Reset}" | tee -a $reportFile
#See Which Modules Are Disabled
disabledMods=$(cat /etc/httpd/conf/httpd.conf | grep '#LoadModule' | awk '{ print $2 }')
if [ "$disabledMods" != "" ]
   then
       echo -e "${CyanF}${BoldOn}The Following Apache Modules are Disabled:${Reset}" | tee -a $reportFile
       echo "" | tee -a $reportFile
       echo "$disabledMods" | tee -a $reportFile
fi     
echo "" | tee -a $reportFile

#Get General Performance Info
echo -e "${RedF}${BoldOn}PERFORMANCE${Reset}" | tee -a $reportFile
echo "-------------------------------------------------------------" | tee -a $reportFile
echo "" | tee -a $reportFile
echo "" | tee -a $reportFile
echo -e "${CyanF}${BoldOn}Current Number Of Connections On Port 80:${Reset}${BoldOff}" | tee -a $reportFile
echo "" | tee -a $reportFile
netstat -nt | egrep ':80' | gawk '{print $5}' | wc -l | tee -a $reportFile
echo "" | tee -a $reportFile
echo -e "${CyanF}${BoldOn}Here Is The Total Number Of Apache/php-cgi Processes With Average Process Size And Total Memory Usage:${Reset}${BoldOff}" | tee -a $reportFile
echo "" | tee -a $reportFile
ps awwwux | egrep 'httpd|php-cgi' | grep -v grep | awk '{mem = $6; tot = $6 + tot; total++} END{printf("Total procs: %d\nAvg Size: %d KB\nTotal Mem Used: %f GB\n", total, mem / total, tot / 1024 / 1024)}' | tee -a $reportFile
echo "" | tee -a $reportFile
echo "" | tee -a $reportFile
echo "" | tee -a $reportFile

#Error Logging
echo -e "${RedF}${BoldOn}ERRORS${Reset}" | tee -a $reportFile
echo "-------------------------------------------------------------" | tee -a $reportFile
echo "" | tee -a $reportFile
echo "" | tee -a $reportFile

#Check For MaxClients Errors
recentMaxClients=$(grep MaxClients /var/log/httpd/error_log | wc -l)
logDate=$(stat /var/log/httpd/error_log | grep 'Access' | tail -n1 | awk '{ print $2 }')
allMaxClients=$(grep MaxClients /var/log/httpd/error_log* | wc -l)
echo -e "There were ${CyanF}$allMaxClients${Reset} MaxClients errors in the general Apache logs, ${CyanF}$recentMaxClients${Reset} of which have occurred since $logDate" | tee -a $reportFile
echo "" | tee -a $reportFile

#Check general Apache logs
echo -e "${CyanF}${BoldOn}These Are The Top 10 Errors In The Most Recent General Apache Error Log:${Reset}${BoldOff}" | tee -a $reportFile
echo "" | tee -a $reportFile
egrep 'warn|error' /var/log/httpd/error_log | egrep -v 'BasicConstraints|CommonName|indication|conflict|conjunction' | sed -e "s/\[.*$testYear\]//" | sed -e "s/\[client.*\]//" | sort | uniq -c | sort -nr | head | tee -a $reportFile
echo "" | tee -a $reportFile

#Check Error Logs For All Domains
echo -e "${CyanF}${BoldOn}These Are The Top 10 Errors Found In Domain Specific Error Logs:${Reset}${BoldOff}" | tee -a $reportFile
echo "" | tee -a $reportFile
for i in $(ls /var/www/vhosts/ | egrep -v 'chroot|fs|default')
  do
  echo "" | tee -a $reportFile
  echo -e "${CyanF}$i${Reset}" | tee -a $reportFile
  echo "-------------------------------------------------------------" | tee -a $reportFile
echo "" | tee -a $reportFile
  echo "" | tee -a $reportFile
  logFile="/var/www/vhosts/$i/statistics/logs/error_log"
  logSize=$(ls -la $logFile | awk '{print $5}')
  sizeLimit=104857600
  if [ $sizeLimit -lt $logSize ]
     then
        echo -n "This Error Log Is Larger Than 100MB. It Might Take a While. Do You Want To Proceed?(y or n): "
        read proceed
        if [ $proceed == "y" ] || [ $proceed == "Y" ]
            then
            egrep 'warn|error' /var/www/vhosts/$i/statistics/logs/error_log | egrep -v 'BasicConstraints|CommonName|indication|conflict|conjunction' | sed -e "s/\[.*$testYear\]//" | sed -e "s/\[client.*\]//" | sort | uniq -c | sort -nr | head | tee -a $reportFile
echo "" | tee -a $reportFile
       fi
  else
  egrep 'warn|error' /var/www/vhosts/$i/statistics/logs/error_log | egrep -v 'BasicConstraints|CommonName|indication|conflict|conjunction' | sed -e "s/\[.*$testYear\]//" | sed -e "s/\[client.*\]//" | sort | uniq -c | sort -nr | head | tee -a $reportFile
echo "" | tee -a $reportFile
fi
  done

#See If Apache Was Modified.... Fill In Later

#Public Facing Results. Requesting API key for webpagetest.org. In the meantime, will use GTMetrix.
if [ "$domainName" != "n" ] && [ "$domainName" != "N" ]
then
url4Report="http://$domainName"
echo -e "${RedF}${BoldOn}Generating GTMetrix Report${Reset}" | tee -a $reportFile
echo "" | tee -a $reportFile
test=$(curl --silent --user $apiUser:$apiKey --form url=$url4Report --form x-metrix-adblock=0 https://gtmetrix.com/api/0.1/test)
testResult=$(echo $test | awk -F '"' '{ print $2 }')
if [ "$testResult" == "test_id" ]
   then 
    echo "Please Wait, Processing GTMetrix report..." 
   testID=$(echo $test | awk -F '"' '{print $4 }')
   reportURL="https://gtmetrix.com/api/0.1/test/$testID"
   sleep 60
   fullReport=$(curl --silent --user $apiUser:$apiKey $reportURL)
   testStatus=$(echo $fullReport | awk -F ':' '{ print $NF }')   
   if [ "$testStatus" == '"error"}' ]
     then
     echo "An Error Occurred With the GTMetrix Report... sorry homes!" | tee -a $reportFile
   else     
   echo -e "${CyanF}GTMetrix Results:${Reset}" | tee -a $reportFile
   echo "" | tee -a $reportFile
    echo $fullReport | awk -F ',' '{ print $8 "\n" $9  "\n" $10 "\n" $11 "\n" $12 "\n" $13 "\n" $14}' | sed -e 's/"results":{//' | tee -a $reportFile
    #echo $fullReport | awk -F ',' '{ print $11 }' | tee -a $reportFile
   fi
else
    echo "Could Not Perform GTMetrix Report" | tee -a $reportFile
fi

## Check for WordPress Caching
echo ""
echo -e "${RedF}${BoldOn}Check for WordPress Caching${Reset}"
echo ""
for i in $(ls /var/www/vhosts/ | egrep -v 'chroot|fs|default')
do
 echo "" | tee -a $reportFile
  echo -e "${CyanF}$i${Reset}" | tee -a $reportFile
  echo "-------------------------------------------------------------" | tee -a $reportFile
echo "" | tee -a $reportFile
  echo "" | tee -a $reportFile
wp_count=`find /var/www/vhosts/$i -name 'version.php' |  wc -l`
if [ "$wp_count" -gt 0 ];
then
cache_check=`curl --silent -i -L "$i" | egrep "WP-Super-Cache|W3 Total Cache" | wc -l`
        if [ "$cache_check" -gt 0 ];
        then
	echo -e "WordPress is ${BoldOn}***CACHED***${Reset}" | tee -a $reportFile
        else
        echo -e "WordPress is ${RedF}${BoldOn}***NOT CACHED***${Reset}" | tee -a $reportFile
        fi
else
echo "WordPress is not installed" | tee -a $reportFile
fi
done

##End WordPress cache check
fi

#Backup Databases
#echo ""
#echo -e "${CyanF}${BoldOn}Backing Up All Databases on The Server....${Reset}"
#echo ""
#for i in $(mysql -A -u admin -p`cat /etc/psa/.psa.shadow` -Nse 'show databases' | grep -v '^information_schema$'); do mysqldump -uadmin -p$(</etc/psa/.psa.shadow) --add-drop-table --hex-blob "$i" > /root/db-backup.$i.sql; echo "$i"; done
#echo ""

#Backup Config Files
#echo -e "${CyanF}${BoldOn}Making backups of config files, and enabling MySQL Slow Query Logging${Reset}"
#echo ""
#cp -vp /etc/httpd/conf/httpd.conf{,.$(date +%Y-%m-%d.otto)}
#cp -vp /etc/php.ini{,.$(date +%Y-%m-%d.otto)}
#cp -vp /etc/httpd/conf.d/fcgid.conf{,.$(date +%Y-%m-%d.otto)}
#cp -vp /etc/my.cnf{,.$(date +%Y-%m-%d.otto)}

#Enable Slow Query Logging
echo ""
echo -e "${CyanF}${BoldOn}Enabling Slow Query Logging${Reset}"
echo ""
if [ "$slowLogFile" == "" ]
   then
       touch /var/log/mysqld.slow.log
       chown mysql:mysql /var/log/mysqld.slow.log
       #Add Entry To my.cnf file
       sed -i '/\[mysqld\]/ a\#Added by (mt)\nlog_slow_queries = /var/log/mysqld.slow.log\nlong_query_time = 1' /etc/my.cnf 
echo -e "${CyanF}${BoldOn}Restarting MySQL${Reset}"
echo ""
	if [ -n "$mysqlSyntax" ]
    	then
        	echo -e "${RedF}${BoldOn}MySQL is not being restarted because of the following errors:${Reset}"
        	echo ""
        	echo $mysqlSyntax
	else
	/etc/init.d/mysqld restart
	fi
else
    echo "MySQL Slow Query Logging Is Already Enabled"
    echo ""
fi


#TESTING CONCLUDED

echo ""
echo -e "${RedF}${BoldOn}Analysis Concluded!!!${Reset}"
echo ""
echo "The results of this analysis were logged to:"
echo ""
echo -e "${CyanF}${BoldOn}$reportFile ${Reset}${BoldOff}"
rm -f ctanalysis.sh
exit

