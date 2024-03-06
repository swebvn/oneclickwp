#!/bin/bash

domain=$1
source_restore_url=$2

backup_file_name=`echo $source_restore_url | rev | awk -F / '{print $1}' | rev`
source_path="`find /home -name "$domain"`/public_html"
user=`find /home -name "$domain" | awk -F '/' '{print $3}'`

function install_wpcli() {
    echo "runing step install wp-cli ..."
    if [[ ! -e /usr/bin/wp ]]; then
        cd /tmp
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/bin/wp
    fi
    if [[ ! -e /usr/bin/php ]]; then
        ln -s /opt/php-*/bin/php /usr/bin/php
    fi
}

function copy_plugin() {
    echo "runing step copy plugin ... "
    unzip -o /tmp/all-in-one-wp-migration.*
    unzip -o /tmp/all-in-one-wp-migration-*
    mv -f all-in-one-wp-migration/ $source_path/wp-content/plugins/
    mv -f all-in-one-wp-migration-url-extension/ $source_path/wp-content/plugins/
    chown $user: -R $source_path
}

function active_update_plugin() {
    echo "runing step active and update plugin ... "
    wp core install --path=$source_path/ --allow-root --url=http://$domain --title=testphoi --admin_user=admin --admin_email=caotritran.14@gmail.com
    sudo -u $user -i -- wp plugin activate all-in-one-wp-migration --allow-root --path=$source_path
    sudo -u $user -i -- wp plugin activate all-in-one-wp-migration-url-extension --allow-root --path=$source_path
    #sudo -u $user -i -- wp plugin update all-in-one-wp-migration --allow-root --path=$source_path
    #sudo -u $user -i -- wp plugin update all-in-one-wp-migration-url-extension --allow-root --path=$source_path
    sudo chown $user: -R $source_path/wp-content/
}

function download_restore_backup() {
    echo "runing step restore template ... "
    mkdir $source_path/wp-content/ai1wm-backups/
    wget -O $source_path/wp-content/ai1wm-backups/$backup_file_name $source_restore_url 
    chown $user: -R $source_path/wp-content/ai1wm-backups/
    sudo -u $user -i -- wp ai1wm restore $backup_file_name --yes --path=$source_path
}

function change_owner() {
    sudo chown $user: -R $source_path/wp-content/uploads
}

install_wpcli
copy_plugin
active_update_plugin
download_restore_backup
change_owner
