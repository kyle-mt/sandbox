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
        O.mod_cfg_wp -g
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
    sed -i "s/\$weblog_title *= isset.*/\$weblog_title = 'CS4 Practice Test';/" /var/www/vhosts/cs4test.com/httpdocs/wp-admin/install.php
    sed -i "s/\$user_name *= isset.*/\$user_name = 'cs4_admin';/" /var/www/vhosts/cs4test.com/httpdocs/wp-admin/install.php
    sed -i "s/\$admin_password *= isset.*/\$admin_password = '$wp_pass';/" /var/www/vhosts/cs4test.com/httpdocs/wp-admin/install.php
    sed -i "s/\$admin_password_check *= isset.*/\$admin_password_check = '$wp_pass';/" /var/www/vhosts/cs4test.com/httpdocs/wp-admin/install.php
    sed -i "s/\$admin_email *= isset.*/\$admin_email = 'norepmt@gmail.com';/" /var/www/vhosts/cs4test.com/httpdocs/wp-admin/install.php
    sed -i "s/\$public *= isset.*/\$public = 0;/" /var/www/vhosts/cs4test.com/httpdocs/wp-admin/install.php

    # run WordPress installer
    curl -d "weblog_title='CS4 Practice Test'&user_name='cs4_admin'&admin_password=$wp_pass&admin_password2=$wp_pass&admin_email='norepmt@gmail.com'" http://"$wp_ip"/wp-admin/install.php?step=2 >/dev/null 2>&1
}

cs4_deploy
cs4_get_wordpress
cs4_install_wordpress