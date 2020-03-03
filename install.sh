#!/bin/bash
#
# ubnt自愈能力安装脚本 FISH
#
# 说明：
#   * ubnt路由器在升级固件后会删除所有配置和数据，除了/config目录,导致每次升级后都需要大量人工操作。
#   * 执行此脚本后，自动设置好所有配置。
#   * 此脚本是安装程序，即安装后使ubnt具备自愈能力，故安装此脚本时需ubnt正常运转且已连接互联网。
#   * 请切换到root用户执行此脚本。sudo su -

if [ ! -d /etc/ubnt ]; then
    echo "This script is designed for running on UBNT/Unifi Routers"
    exit
fi

# 1. 定义系统目录
# UBNT开头的变量是EdgeOS默认自动执行或读取的目录
# 根目录是/config，升级固件后数据不会丢失

# 在执行firstboot.d脚本前，自动安装目录*.deb
UBNT_FIRSTBOOT_PKGS_DIR=/config/data/firstboot/install-packages

# 三个启动时按顺序自动执行的脚本目录:
#   /config/scripts/firstboot.d   升级完固件只执行一次
#   /config/scripts/pre-config.d  每次重启后在加载config.boot之前执行
#   /config/scripts/post-config.d 每次重启后在加载config.boot之后执行
UBNT_FIRSTBOOT_DIR=/config/scripts/firstboot.d
UBNT_PRECONFIG_DIR=/config/scripts/pre-config.d
UBNT_POSTCONFIG_DIR=/config/scripts/post-config.d


# 2. 定义安装目录
# FISH开头的变量是安装目录
# 根目录是/user-data/fish

# 存放自动生成的配置和用户本地配置
# 与/etc对应，会生成link文件到/etc
# 如果用户有自定义配置，自行放置到此目录
# 比如，/user-data/fish/etc/dnsmasq.d/local_domain.conf
FISH_ETC_DIR=/user-data/fish/etc

# 安装包目录
# 比如，/user-data/fish/packages/wireguard-v2.0-e300-0.0.20191219-2.deb
FISH_PACKAGES_DIR=/user-data/fish/packages

# 脚本目录
# 安装程序生成的脚本都存放于此
# 如果用户有自定义脚本，自行放置到此目录
# 比如，/user-data/fish/scripts/local_crontab
FISH_SCRIPTS_DIR=/user-data/fish/scripts

# 数据目录
# 比如，/user-data/fish/data/domain.list
# /user-data/fish/data/ip.list
FISH_DATA_DIR=/user-data/fish/data

# 3. 创建UBNT目录
echo "Create the UBNT directories"
mkdir -p $UBNT_FIRSTBOOT_PKGS_DIR
mkdir -p $UBNT_FIRSTBOOT_DIR
mkdir -p $UBNT_PRECONFIG_DIR
mkdir -p $UBNT_POSTCONFIG_DIR

# 4. 创建FISH目录
echo "Create the FISH directories"
mkdir -p $FISH_ETC_DIR
mkdir -p $FISH_PACKAGES_DIR
mkdir -p $FISH_SCRIPTS_DIR
mkdir -p $FISH_DATA_DIR

# 5. 下载packages
WIREGUARD_URL="https://github.com/Lochnair/vyatta-wireguard/releases/download/0.0.20191219-2/wireguard-v2.0-e300-0.0.20191219-2.deb"

# 6. 生成init脚本
FISH_INIT_FILE=$FISH_SCRIPTS_DIR/fish_init.sh
cat << EOF > $FISH_INIT_FILE
#!/bin/bash
#
# 初始化脚本
#
echo "init script form FISH" 

# timedatectl set-timezone Asia/Shanghai
EOF


# 7. 生成alias脚本


# 8. vim wget zip unzip dnsutils net-tools安装脚本
#    配置apt源 stretch.list
# deb http://mirrors.huaweicloud.com/debian/ stretch main contrib 
# deb http://mirrors.huaweicloud.com/debian/ stretch-updates main contrib 
# deb http://mirrors.huaweicloud.com/debian/ stretch-backports main contrib  
# deb http://mirrors.huaweicloud.com/debian-security/ stretch/updates main 

# 9. 生成dnsmasq配置、设置ipset 脚本
#    下载*.list

# 10. restart service脚本

# 11. link
#   packages link到UBNT_FIRSTBOOT_PKGS_DIR
#   生成link etc




echo "Install success"