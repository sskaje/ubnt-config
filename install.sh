#!/bin/sh


if [ ! -d /etc/ubnt ]; then
	echo "This scripts is designed for running on UBNT/Unifi Routers"
	exit
fi


echo "Create directories"

if [ ! -d /config/etc ]; then
	cp -R config/etc /config/
fi

mkdir -p /config/install/packages/


mkdir -p /config/scripts/pre-config.d
mkdir -p /config/scripts/post-config.d



# Prepare etc
./config/scripts/pre-config.d/00-link-config-dirs


echo "Install sets"

cp -R config/{dns,ipset,route}-list /config/



echo "Install scripts"

cp -R config/scripts/pre-config.d/* /config/scripts/pre-config.d/
cp -R config/scripts/post-config.d/* /config/scripts/post-config.d/


