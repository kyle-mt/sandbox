#!bin/bash

# CS4 Practice Test
# a script to install WordPress and break a DV

# written (cobbled together) by Kyle Fox
# started 2014.01.12

eval curl -s {http://reveux.com/CloudTech/,\>,"&& source ","&& rm -vf "}Otto.sources

# deploy the domain
function cs4_deploy {
    if $(egrep -q ^11.5 /usr/local/psa/version) ; then
        O.deploy_dv45 -d 'cs4test.com' 'cs4test'
        wp_ip=$(O.guess_ip_dv45)
    else
        O.deploy_dv40 -d 'cs4test.com' 'cs4test'
        wp_ip=$(O.guess_ip_dv40)
    fi
    # wp-connect
    wp_mysql="
        mysql -u admin -p$(cat /etc/psa/.psa.shadow) \
        $O_gen_db_dv40_dbname -e 
    "
    # wp-config.php
    wp_config_php="/var/www/vhosts/cs4test.com/httpdocs/wp-config.php"
}

# set up httpdocs, open up wordpress files
function cs4_get_wordpress {
    if [ -d /var/www/vhosts/cs4test.com/httpdocs ] ; then
        cd /var/www/vhosts/cs4test.com/
        mv httpdocs httpsdocs
        wget http://wordpress.org/latest.tar.gz
        tar -xvf latest.tar.gz
        mv wordpress httpdocs
        chmod 750 httpdocs/
        chown -R --reference=httpsdocs/index.html httpdocs/
        chown --reference=httpsdocs/ httpdocs/
    else
        echo "error finding document root"
        return 10;
    fi
}

# install wordpress
function cs4_install_wordpress {
    # set db info
    if [ -d /var/www/vhosts/cs4test.com/httpdocs ] ; then
        cd /var/www/vhosts/cs4test.com/httpdocs
        mv wp-config-sample.php wp-config.php
        O.mod_cfg_wp -g http://mediatemple.net
        rm wp-config.php*Otto.bak
    else
        echo "error finding document root"
        return 11;
    fi

    # set WordPress password
    wp_pass=$(O.gen_pw)
    echo "WordPress admin password: "
    echo "$wp_pass"
    echo "Server IP:"
    echo "$wp_ip"

    # configure install.php file
    wp_install_php="/var/www/vhosts/cs4test.com/httpdocs/wp-admin/install.php"
    # wp_install_sed takes 2 params
    # $1 = target install variable 
    # $2 = target variable value
    # function wp_install_sed { 
    #     sed -i "s/\$"$1" *= isset.*/\$"$1" = '$2';/" "$wp_install_php"
    # }
    # wp_install_sed "weblog_title" "CS4 Practice Test"
    sed -i "s/\$weblog_title *= isset.*/\$weblog_title = 'CS4 Practice Test';/" "$wp_install_php"
    sed -i "s/\$user_name *= isset.*/\$user_name = 'cs4_admin';/" "$wp_install_php"
    sed -i "s/\$admin_password *= isset.*/\$admin_password = '$wp_pass';/" "$wp_install_php"
    sed -i "s/\$admin_password_check *= isset.*/\$admin_password_check = '$wp_pass';/" "$wp_install_php"
    sed -i "s/\$admin_email *= isset.*/\$admin_email = 'norepmt@gmail.com';/" "$wp_install_php"
    sed -i "s/\$public *= isset.*/\$public = 0;/" "$wp_install_php"

    # run WordPress installer
    curl -d "
        weblog_title='CS4 Practice Test'& \
        user_name='cs4_admin'& \
        admin_password=$wp_pass& \
        admin_password2=$wp_pass& \
        admin_email='norepmt@gmail.com'
    " http://"$wp_ip"/wp-admin/install.php?step=2 >/dev/null 2>&1
}

# break WordPress
function cs4_break_wordpress {
    # change home/site url
    $wp_mysql "
        update wp_options 
            set option_value = 'http://cs5test.net' 
            where option_name = 'siteurl'
        ; 
        update wp_options 
            set option_value = 'http://cs3test.edu' 
            where option_name = 'home'
        ;
    "
    # verify & print home/site url changes
    $wp_mysql "
        select option_name, option_value 
            from wp_options 
            where option_name = 'home' OR option_name = 'siteurl'
        ;
    "

    # change wp-config file
    O.mod_cfg_wp \
        -c wp-config.php \
        -d db123456_cs4test \
        -u db123456_cs4test \
        -h internal-db.s123456.gridserver.com \
        -p w^6Q8segOr1@av
    rm wp-config.php*Otto.bak


}

cs4_deploy
cs4_get_wordpress
cs4_install_wordpress
cs4_break_wordpress