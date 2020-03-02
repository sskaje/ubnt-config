#!/bin/bash

if [ ! -d /etc/ubnt ]; then
	echo "This script is designed for running on UBNT/Unifi Routers"
	exit
fi

# The root directory on the ubnt where the script is installed
ubnt_dir_config=/config

# The directory for the config
# $ubnt_dir_config/etc link to /etc on the ubnt
ubnt_dir_config_etc=${ubnt_dir_config}/etc

# The directory for the script, which contains three subdirectories:
# 	$ubnt_dir_config/scripts/firstboot.d   execute only once after firmware upgrade
# 	$ubnt_dir_config/scripts/pre-config.d  execute before loading the system configuration
# 	$ubnt_dir_config/scripts/post-config.d execute after loading the system configuration
ubnt_dir_config_scripts_firstboot=${ubnt_dir_config}/scripts/firstboot.d
ubnt_dir_config_scripts_preconfig=${ubnt_dir_config}/scripts/pre-config.d
ubnt_dir_config_scripts_postconfig=${ubnt_dir_config}/scripts/post-config.d

# The directory for the data:
# 	$ubnt_dir_config/user-data/packages  deb directory, such as wireguard * .deb
# 	$ubnt_dir_config/user-data/ipdata    IP or domain data that will be stored in ipset
ubnt_dir_config_userdata_packages=${ubnt_dir_config}/user-data/packages
ubnt_dir_config_userdata_ipdata=${ubnt_dir_config}/user-data/ipdata

echo "Init the ubnt directories"
mkdir -p $ubnt_dir_config_etc
mkdir -p $ubnt_dir_config_scripts_firstboot
mkdir -p $ubnt_dir_config_scripts_preconfig
mkdir -p $ubnt_dir_config_scripts_postconfig
mkdir -p $ubnt_dir_config_userdata_packages
mkdir -p $ubnt_dir_config_userdata_ipdata

echo "Install to the ubnt directories"
installsh_dir=$(cd "$(dirname "$0")";pwd)
test -d $installsh_dir/config/etc && cp -r $installsh_dir/config/etc $ubnt_dir_config_etc/
test -d $installsh_dir/config/scripts/firstboot.d && cp -r $installsh_dir/config/scripts/firstboot.d/* $ubnt_dir_config_scripts_firstboot/
cp -r $installsh_dir/config/scripts/pre-config.d/* $ubnt_dir_config_scripts_preconfig/
cp -r $installsh_dir/config/scripts/post-config.d/* $ubnt_dir_config_scripts_postconfig/
cp -r $installsh_dir/config/{dns,ipset,route}-list $ubnt_dir_config_userdata_ipdata/

echo "Download Debs"

echo "Install success"