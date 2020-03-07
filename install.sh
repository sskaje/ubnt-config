#!/bin/bash
#
# ubnt自愈能力安装脚本 FISH
#
# 说明：
#   * ubnt路由器在升级固件后会删除所有配置和数据，除了/config目录,导致每次升级后都需要大量人工操作。
#   * 执行此脚本后，自动设置好所有配置。
#   * 此脚本是安装程序，即安装后使ubnt具备自愈能力，故安装此脚本时需ubnt正常运转且已连接互联网。
#   * 请切换到root用户执行此脚本。sudo su -
echo "$(date +%Y-%m-%d\ %H:%M:%S) - Starting install.sh..."
if [ ! -d /etc/ubnt ]; then
    echo "This script is designed for running on UBNT/Unifi Routers"
    exit
fi

# 定义系统目录
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


# 定义安装目录
# FISH开头的变量是安装目录
# 根目录是/config/user-data/fish

# 存放自动生成的配置和用户本地配置
# 与/etc对应，会生成link文件到/etc
# 如果用户有自定义配置，自行放置到此目录
# 比如，/config/user-data/fish/etc/dnsmasq.d/local_domain.conf
FISH_ETC_DIR=/config/user-data/fish/etc

# 安装包目录
# 比如，/user-data/fish/packages/wireguard-v2.0-e300-0.0.20191219-2.deb
FISH_PACKAGES_DIR=/config/user-data/fish/packages

# 脚本目录
# 安装程序生成的脚本都存放于此
# 如果用户有自定义脚本，自行放置到此目录
# 比如，/config/user-data/fish/scripts/local_crontab
FISH_SCRIPTS_DIR=/config/user-data/fish/scripts

# 数据目录
# 比如，/config/user-data/fish/data/domain.list
# /config/user-data/fish/data/ip.list
FISH_DATA_DIR=/config/user-data/fish/data

# 创建UBNT目录
echo "$(date +%Y-%m-%d\ %H:%M:%S) - Creating the UBNT directories..."
mkdir -p $UBNT_FIRSTBOOT_PKGS_DIR
mkdir -p $UBNT_FIRSTBOOT_DIR
mkdir -p $UBNT_PRECONFIG_DIR
mkdir -p $UBNT_POSTCONFIG_DIR

# 创建FISH目录
echo "$(date +%Y-%m-%d\ %H:%M:%S) - Creating the FISH directories..."
mkdir -p $FISH_ETC_DIR
mkdir -p $FISH_PACKAGES_DIR
mkdir -p $FISH_SCRIPTS_DIR
mkdir -p $FISH_DATA_DIR

# 下载packages
FISH_WIREGUARD_DEB=${FISH_PACKAGES_DIR}/wireguard/wireguard.deb
echo "$(date +%Y-%m-%d\ %H:%M:%S) - downloading ${FISH_WIREGUARD_DEB}..."

test -d ${FISH_PACKAGES_DIR}/wireguard || mkdir -p ${FISH_PACKAGES_DIR}/wireguard
wget -O $FISH_WIREGUARD_DEB "https://github.com/Lochnair/vyatta-wireguard/releases/download/0.0.20191219-2/wireguard-v2.0-e300-0.0.20191219-2.deb"

# link debs
echo "$(date +%Y-%m-%d\ %H:%M:%S) - linking $FISH_WIREGUARD_DEB to ${UBNT_FIRSTBOOT_PKGS_DIR}/wireguard.deb" 
ln -sf $FISH_WIREGUARD_DEB ${UBNT_FIRSTBOOT_PKGS_DIR}/wireguard.deb

# 生成local_env配置
test -d ${FISH_ETC_DIR}/default || mkdir -p ${FISH_ETC_DIR}/default
FISH_VYATTA_LOCAL_ENV_CONFIG=${FISH_ETC_DIR}/default/vyatta-local-env
echo "$(date +%Y-%m-%d\ %H:%M:%S) - generating ${FISH_VYATTA_LOCAL_ENV_CONFIG}..."
cat << EOF > $FISH_VYATTA_LOCAL_ENV_CONFIG
export LANG=en_US.UTF-8
export LC_ALL=C.UTF-8
export TERM=rxvt
alias ll="ls -alh"
EOF

# 配置apt源
test -d ${FISH_ETC_DIR}/apt/sources.list.d || mkdir -p ${FISH_ETC_DIR}/apt/sources.list.d
FISH_STRETCH_LIST_CONFIG=${FISH_ETC_DIR}/apt/sources.list.d/stretch.list
echo "$(date +%Y-%m-%d\ %H:%M:%S) - generating ${FISH_STRETCH_LIST_CONFIG}..."
cat << EOF > $FISH_STRETCH_LIST_CONFIG
deb http://mirrors.huaweicloud.com/debian/ stretch main contrib 
deb http://mirrors.huaweicloud.com/debian/ stretch-updates main contrib 
deb http://mirrors.huaweicloud.com/debian/ stretch-backports main contrib  
deb http://mirrors.huaweicloud.com/debian-security/ stretch/updates main 
EOF

# 生成init脚本
test -d ${FISH_SCRIPTS_DIR}/firstboot.d || mkdir -p ${FISH_SCRIPTS_DIR}/firstboot.d
FISH_INIT_SCRIPT=${FISH_SCRIPTS_DIR}/firstboot.d/fish_init.sh
echo "$(date +%Y-%m-%d\ %H:%M:%S) - generating ${FISH_INIT_SCRIPT}..."
cat << EOF > $FISH_INIT_SCRIPT
#!/bin/bash
#
# 初始化脚本
#

echo "$(date +%Y-%m-%d\ %H:%M:%S) - Starting /config/scripts/firstboot.d/fish_init.sh..." 

# 设置系统时区
echo "$(date +%Y-%m-%d\ %H:%M:%S) - Setting timezone Asia/Shanghai" 
timedatectl set-timezone Asia/Shanghai

# link vyatta_local_env
echo "$(date +%Y-%m-%d\ %H:%M:%S) - linking $FISH_VYATTA_LOCAL_ENV_CONFIG to /etc/default/vyatta-local-env" 
ln -sf $FISH_VYATTA_LOCAL_ENV_CONFIG /etc/default/vyatta-local-env

# link stretch.list
echo "$(date +%Y-%m-%d\ %H:%M:%S) - linking $FISH_STRETCH_LIST_CONFIG to /etc/apt/sources.list.d/stretch.list" 
ln -sf $FISH_STRETCH_LIST_CONFIG /etc/apt/sources.list.d/stretch.list

echo "$(date +%Y-%m-%d\ %H:%M:%S) - finish /config/scripts/firstboot.d/fish_init.sh..." 
EOF

# 8. vim wget zip unzip dnsutils net-tools安装脚本

# 9. 生成dnsmasq配置、设置ipset 脚本
#    下载*.list

# 10. restart service脚本

# 11. link
#   packages link到UBNT_FIRSTBOOT_PKGS_DIR
#   生成link etc




echo "$(date +%Y-%m-%d\ %H:%M:%S) - finish install.sh..." 