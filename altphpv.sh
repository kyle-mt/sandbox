# Automation of "How to install and use two versions of PHP on the same Plesk
# for Linux server"
# Parallels Article: http://kb.parallels.com/en/114753

# Text color variables
txtund=$(tput sgr 0 1)          # Underline
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldblu=${txtbld}$(tput setaf 4) #  blue
bldwht=${txtbld}$(tput setaf 7) #  white
txtrst=$(tput sgr0)             # Reset
info=${bldwht}*${txtrst}        # Feedback
pass=${bldblu}*${txtrst}
warn=${bldred}*${txtrst}
ques=${bldblu}?${txtrst}

echo "========================================================================="
echo "Welcome! This script will allow you to install an alternate version of
      PHP on your server"
echo "Keep in mind! For this to work, you must have PHP running as fastcgi!"
echo "========================================================================="

# Prompt for user to choose which version of PHP they want installed!

echo "We first need to install Developer tools, are you down? yes or no?"

read DOWN

if [  $DOWN = "yes" ];

    then

        yum update

        yum groupinstall "Development Tools"

else

echo "Cool story, bro!"

#exit

fi

echo "We will need to install the following to resolve dependency issues:

libxml2.x86_64
bzip2-devel.x86_64
libcurl-devel.x86_64
libjpeg-turbo-devel.x86_64
openldap-devel.x86_64
libc-client-devel.x86_64
gmp-devel.x86_64
freetype-devel.x86_64
libpng-devel.x86_64
libpng-devel.x86_64
unixODBC-devel
postgresql-devel
php-pspell.x86_64
aspell-devel.x86_64
net-snmp-devel.x86_64
libxslt-devel.x86_64
libicu-devel.x86_64

As well as adding the EPEL Repo to install: libmcrypt-devel.x86_64

Is that cool? yes or no?
"

read COOL

    if [  $COOL = "yes" ];

then
        
yum -y install libxml2.x86_64 bzip2-devel.x86_64 libcurl-devel.x86_64  libjpeg-turbo-devel.x86_64 openldap-devel.x86_64 libc-client-devel.x86_64 gmp-devel.x86_64 freetype-devel.x86_64 libpng-devel.x86_64 libpng-devel.x86_64 unixODBC-devel postgresql-devel php-pspell.x86_64 aspell-devel.x86_64 net-snmp-devel.x86_64 libxslt-devel.x86_64 libicu-devel.x86_64

wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm sudo rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm

rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm

yum -y install libmcrypt-devel.x86_64

else

echo "Fine, we gotta end this"

#exit

fi

echo "Which version of PHP do you want to install?: "

    echo    "1) PHP 5.3.5"
    echo    "2) PHP 5.2.6 - DOES NOT WORK ATM"
    echo    "3) None"

    read PHP

case $PHP in

        [1] )
                
            echo "Great! We will grab 5.3"
            
            PHPVERSION="php535"

TARGETDIR="/usr/local/src/php53"

    mkdir -p $TARGETDIR

    cd $TARGETDIR

wget http://museum.php.net/php5/php-5.3.5.tar.gz

    tar -xzvf php-5.3.5.tar.gz
    
    chown -R root.root $TARGETDIR

    cd php-5.3.5

./configure '--with-libdir=lib64' '--cache-file=../config.cache' '--prefix=/usr/local/php535-cgi' '--with-config-file-path=/usr/local/php535-cgi/etc' '--disable-debug' '--with-pic' '--disable-rpath' '--enable-cgi' '--with-bz2' '--with-curl' '--with-freetype-dir=/usr/local/php535-cgi' '--with-png-dir=/usr/local/php535-cgi' '--enable-gd-native-ttf' '--without-gdbm' '--with-gettext' '--with-gmp' '--with-iconv' '--with-jpeg-dir=/usr/local/php535-cgi' '--with-openssl' '--with-pspell' '--with-pcre-regex' '--with-zlib' '--enable-exif' '--enable-ftp' '--enable-sockets' '--enable-sysvsem' '--enable-sysvshm' '--enable-sysvmsg' '--enable-wddx' '--with-kerberos' '--with-unixODBC=/usr' '--enable-shmop' '--enable-calendar' '--without-sqlite3' '--with-libxml-dir=/usr/local/php535-cgi' '--enable-pcntl' '--with-imap' '--with-imap-ssl' '--enable-mbstring' '--enable-mbregex' '--with-gd' '--enable-bcmath' '--with-xmlrpc' '--with-ldap' '--with-ldap-sasl' '--with-mysql=/usr' '--with-mysqli' '--with-snmp' '--enable-soap' '--with-xsl' '--enable-xmlreader' '--enable-xmlwriter' '--enable-pdo' '--with-pdo-mysql' '--with-pdo-pgsql' '--with-pear=/usr/local/php535-cgi/pear' '--with-mcrypt' '--enable-intl' '--without-pdo-sqlite' '--with-config-file-scan-dir=/usr/local/php535-cgi/php.d'
;;
         [2] )
                echo "OK, lets do 5.2.6";
                
                PHPVERSION="php525"
                
TARGETDIR="/usr/local/src/php52"

    mkdir -p $TARGETDIR

    cd $TARGETDIR

wget http://museum.php.net/php5/php-5.2.6.tar.gz
    
    tar -xzvf php-5.2.6.tar.gz
    
    chown -R root.root $TARGETDIR

    cd php-5.2.6

./configure '--with-libdir=lib64' '--cache-file=../config.cache' '--prefix=/usr/local/php526-cgi' '--with-config-file-path=/usr/local/php526-cgi/etc' '--disable-debug' '--with-pic' '--disable-rpath' '--enable-fastcgi' '--with-bz2' '--with-curl' '--with-freetype-dir=/usr/local/php526-cgi' '--with-png-dir=/usr/local/php526-cgi' '--enable-gd-native-ttf' '--without-gdbm' '--with-gettext' '--with-gmp' '--with-iconv' '--with-jpeg-dir=/usr/local/php526-cgi' '--with-pspell' '--with-pcre-regex' '--with-zlib' '--enable-exif' '--enable-ftp' '--enable-sockets' '--enable-sysvsem' '--enable-sysvshm' '--enable-sysvmsg' '--enable-wddx' '--with-kerberos' '--with-unixODBC=/usr' '--enable-shmop' '--enable-calendar' '--without-sqlite3' '--with-libxml-dir=/usr/local/php526-cgi' '--enable-pcntl' '--with-imap' '--with-imap-ssl' '--enable-mbstring' '--enable-mbregex' '--with-gd' '--enable-bcmath' '--with-xmlrpc' '--with-ldap' '--with-ldap-sasl' '--with-mysql=/usr' '--with-mysqli' '--with-snmp' '--enable-soap' '--with-xsl' '--enable-xmlreader' '--enable-xmlwriter''--enable-pdo' '--with-pdo-mysql' '--with-pdo-pgsql' '--with-pear=/usr/local/php526-cgi/pear' '--with-mcrypt' '--enable-intl' '--without-pdo-sqlite' '--with-config-file-scan-dir=/usr/local/php526-cgi/php.d'
                
                ;;
        
        *) echo "Cool, I'm out!"
                
                ;;

esac

# Checkpoint - compile and install PHP version chosen

echo "Now we need to compile and install this version of PHP, do you want to proceed?"

    read ANSWER2

        if [  $ANSWER2 = "yes" ];

        then

            make

                #wait

                    make install

fi

# 4. Create a PHP wrapper. For example, let's say you have a customer, domain.com, that uses some newer PHP functions that don't exist in the default PHP 5.1. Let's call that customer domain.com. We will tell Apache to use our new PHP version (5.4.0) for him:

echo "Awesome bud! Looks like this was successful! Do you want to configure this PHP version for a domain name?"

    read ANSWER3

        if [  $ANSWER3 = "yes" ];

        then

echo "Which domain name?"

    read DOMAIN

        cd /var/www/vhosts/$DOMAIN/cgi-bin

        mkdir -p .cgi_wrapper
    
    cd .cgi_wrapper

echo "#!/bin/sh
PHPRC=/var/www/vhosts/$DOMAIN/etc/
PHP_FCGI_CHILDREN=4
PHP_FCGI_MAX_REQUESTS=1000
exec /usr/local/$PHPVERSION-cgi/bin/php-cgi" >> .phpwrapper

#Setting proper ownerships

chgrp psaserv /var/www/vhosts/$DOMAIN/cgi-bin
cd /var/www/vhosts/$DOMAIN/cgi-bin
chmod 101 .cgi_wrapper
chmod 500 .cgi_wrapper/.phpwrapper

#Get FTP user and 

#FTPUSER=$(my psa -e "select sys_users.login from domains join hosting on hosting.dom_id=domains.id join sys_users on sys_users.id=hosting.sys_user_id where name = '$DOMAIN';" >> test.txt | xargs awk 'NR==2' test.txt)

 #   chown $FTPUSER:psacln .cgi_wrapper -R
    
    chown --reference=/var/www/vhosts/$DOMAIN/httpdocs/index.html .cgi_wrapper -R
    
    chattr -R +i .cgi_wrapper

    else

    echo "Sure, no problem!"

    exit

fi

# Make Apache aware of our new PHP wrapper. PP offers an option to change the 
# httpd setup per host. We will use this option to tell Apache domain.com needs 
# to use our new PHP wrapper instead of the one provided by PP:

cd /var/www/vhosts/$DOMAIN/conf

echo "<Directory /var/www/vhosts/$DOMAIN/httpdocs>
RemoveHandler fcgid-script
<IfModule mod_fcgid.c>
    AddHandler fcgid-script .php
    <Files ~ (\.php)>
        SetHandler fcgid-script
        FCGIWrapper /var/www/vhosts/$DOMAIN/cgi-bin/.cgi_wrapper/.phpwrapper .php
        Options +ExecCGI
        allow from all
    </Files>
</IfModule>
</Directory>" >> vhost.conf

# Create phpinfo.php file

echo "<?php  // Show all information, defaults to INFO_ALL
phpinfo();  // Show just the module information. // phpinfo(8) yields identical results.
phpinfo(INFO_MODULES);
?>" > /var/www/vhosts/$DOMAIN/httpdocs/phpinfo.php
 
#chown $FTPUSER.psacln /var/www/vhosts/$DOMAIN/httpdocs/phpinfo.php

chown --reference=/var/www/vhosts/$DOMAIN/httpdocs/index.html /var/www/vhosts/$DOMAIN/httpdocs/phpinfo.php


# Running "web" and restarting webserver

echo "Ready to restart Apache?"

    read ANSWERLAST

    if [  $ANSWERLAST = "yes" ];

    then

/usr/local/psa/admin/sbin/httpdmng --reconfigure-domain $DOMAIN

/etc/init.d/httpd restart

echo "Web server restarted!"

    else

        echo "Okay! Just remember to restart your web server!"

exit

fi