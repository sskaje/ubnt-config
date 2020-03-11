#!/bin/bash
#
# ubnt自愈能力安装脚本
#
# 说明：
#   * ubnt路由器在升级固件后会删除所有配置和数据，除了/config目录,导致每次升级后都需要大量人工操作。
#   * 执行此脚本后，自动设置好所有配置。
#   * 此脚本是安装程序，即安装后使ubnt具备自愈能力，故安装此脚本时需ubnt正常运转且已连接互联网。
#   * 请切换到root用户执行此脚本。sudo su -

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "starting install.sh"
if [ ! -d /etc/ubnt ]; then
    log "This script is designed for running on UBNT/Unifi Routers"
    exit 1
fi

# 定义系统目录
# UBNT开头的变量是EdgeOS默认自动执行或读取的目录
# 根目录是/config，升级固件后数据不会丢失
#
# 在执行firstboot.d脚本前，自动安装目录中的*.deb
UBNT_FIRSTBOOT_PKGS_DIR=/config/data/firstboot/install-packages
# 三个启动时按顺序自动执行的脚本目录:
#   /config/scripts/firstboot.d   升级完固件只执行一次
#   /config/scripts/pre-config.d  每次重启后在加载config.boot之前执行
#   /config/scripts/post-config.d 每次重启后在加载config.boot之后执行
UBNT_FIRSTBOOT_DIR=/config/scripts/firstboot.d
UBNT_PRECONFIG_DIR=/config/scripts/pre-config.d
UBNT_POSTCONFIG_DIR=/config/scripts/post-config.d

# 定义本地目录
# LOCAL开头的变量是本地目录
#
# 根目录/config/user-data/local
LOCAL_DIR=/config/user-data/local
# 存放用户本地配置
LOCAL_ETC_DIR=${LOCAL_DIR}/etc
# 本地包目录
LOCAL_PACKAGES_DIR=${LOCAL_DIR}/packages
# 本地脚本目录
LOCAL_SCRIPTS_DIR=${LOCAL_DIR}/scripts
# 本地数据目录
LOCAL_DATA_DIR=${LOCAL_DIR}/data

if [ ! -f ${LOCAL_DATA_DIR}/wg_remote_address ]; then
    log "${LOCAL_DATA_DIR}/wg_remote_address is required"
    exit 1
fi

# 下载deb
function add_deb() {
    if [ $# -ne 3 ]; then
        log "You must specify 3 args"
        exit 1
    fi

    if [ ! -f ${LOCAL_PACKAGES_DIR}/$2 ]; then
        log "downloading $2"
        wget -O ${LOCAL_PACKAGES_DIR}/$2 $3
    fi

    log "overwriting ${LOCAL_PACKAGES_DIR}/$2 to ${UBNT_FIRSTBOOT_PKGS_DIR}/$1"
    cp -f ${LOCAL_PACKAGES_DIR}/$2 $UBNT_FIRSTBOOT_PKGS_DIR/$1
}

# 创建文件夹
function create_directories() {
    log "creating UBNT directories"
    mkdir -p $UBNT_FIRSTBOOT_PKGS_DIR $UBNT_FIRSTBOOT_DIR $UBNT_PRECONFIG_DIR $UBNT_POSTCONFIG_DIR

    log "creating LOCAL directories"
    mkdir -p $LOCAL_ETC_DIR $LOCAL_PACKAGES_DIR $LOCAL_SCRIPTS_DIR $LOCAL_DATA_DIR
}

# 添加deb到初始化安装目录
function add_debs_to_firstboot_install_packages() {
    # wireguard
    add_deb "wireguard.deb" "wireguard-v2.0-e300-0.0.20191219-2.deb" "https://github.com/Lochnair/vyatta-wireguard/releases/download/0.0.20191219-2/wireguard-v2.0-e300-0.0.20191219-2.deb"
}

# 生成第一次启动执行的脚本
function generate_firstboot_script() {
    # 设置时区
    script_name="00_first_boot_set_timezone.sh"
    log "generating $script_name"
    cat > $UBNT_FIRSTBOOT_DIR/$script_name <<- 'EOF'
#!/bin/bash
#
# 设置时区
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "Starting $0" 

# 设置系统时区
log "Setting timezone Asia/Shanghai" 
timedatectl set-timezone Asia/Shanghai

log "finish ${0}" 
EOF
    log "finish generate $script_name"

    # 设置语言
    script_name="01_first_boot_set_locale.sh"
    log "generating $script_name"
    cat > $UBNT_FIRSTBOOT_DIR/$script_name <<- 'EOF'
#!/bin/bash
#
# 设置语言
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "Starting $0" 

# 设置语言环境，支持中文
log "replace LC_ALL=C to LC_ALL=C.UTF-8 in /etc/default/vyatta-local-env"
locale -a | grep "C\.UTF\-8" > /dev/null && sed -i "/^export LC_ALL=C$/s/LC_ALL=C/LC_ALL=C.UTF-8/g" /etc/default/vyatta-local-env

log "finish ${0}" 
EOF
    log "finish generate $script_name"

    # 设置apt源
    script_name="02_first_boot_set_sources.sh"
    log "generating $script_name"
    cat > $UBNT_FIRSTBOOT_DIR/$script_name <<- 'EOF'
#!/bin/bash
#
# 设置apt源
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "Starting $0"

# 更新apt源
log "overwriting /etc/apt/sources.list.d/stretch.list"
cat > /etc/apt/sources.list.d/stretch.list <<- 'SUBEOF'
deb http://mirrors.huaweicloud.com/debian/ stretch main contrib 
deb http://mirrors.huaweicloud.com/debian/ stretch-updates main contrib 
deb http://mirrors.huaweicloud.com/debian/ stretch-backports main contrib  
deb http://mirrors.huaweicloud.com/debian-security/ stretch/updates main 
SUBEOF

log "finish ${0}" 
EOF
    log "finish generate $script_name"
}

# 生成加载配置前执行的脚本
function generate_preconfig_script() {
    # 设置别名
    script_name="00_pre_config_set_alias.sh"
    log "generating $script_name"
    cat > $UBNT_PRECONFIG_DIR/$script_name <<- 'EOF'
#!/bin/bash
#
# 设置别名
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "Starting $0" 

# alias ll="ls -alh"
log "append alias ll=\"ls -alh\" to /etc/default/vyatta-local-env"
grep "alias ll=\"ls -alh\"" /etc/default/vyatta-local-env > /dev/null || sed -i '$a \alias ll="ls -alh"' /etc/default/vyatta-local-env

log "finish ${0}" 
EOF
    log "finish generate $script_name"

    script_name="01_pre_config_link_etc.sh"
    log "generating $script_name"
    cat > $UBNT_PRECONFIG_DIR/$script_name <<- 'EOF'
#!/bin/bash
#
# local配置link到/etc
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "Starting $0"

LOCAL_DIR=/config/user-data/local
LOCAL_ETC_DIR=${LOCAL_DIR}/etc

log "linking $LOCAL_ETC_DIR to /etc" 
function link_etc() {
    cd $LOCAL_DIR
    for i in `find etc -type f | grep -v "\.skip"`; do
        log "link ${LOCAL_DIR}/$i to /$i"
        ln -sf ${LOCAL_DIR}/$i /$i
    done;    
}
link_etc

log "finish ${0}" 
EOF
    log "finish generate $script_name"
}

# 生成加载配置后执行的脚本
function generate_postconfig_script() {
    # 安装软件
    script_name="00_post_config_install_app.sh"
    log "generating $script_name"
    cat > $UBNT_POSTCONFIG_DIR/$script_name <<- 'EOF'
#!/bin/bash
#
# 安装软件
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "Starting $0"

log "updaing apt sources" 
apt update -y

echo "installing wget zip unzip dnsutils net-tools" 
apt install -y wget zip unzip dnsutils net-tools

log "finish ${0}" 
EOF
    log "finish generate $script_name"

    script_name="01_post_config_dnsmasq_conf.sh"
    log "generating $script_name"
    cat > $UBNT_POSTCONFIG_DIR/$script_name <<- 'EOF'
#!/bin/bash
#
# 生成dnsmasq配置
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "Starting $0"

LOCAL_DIR=/config/user-data/local
LOCAL_DATA_DIR=${LOCAL_DIR}/data

# 生成dnsmasq配置
if [ $# -eq 1 -a "$1" == "update" ]; then
    rm -f ${LOCAL_DATA_DIR}/domain.list
fi

if [ ! -s ${LOCAL_DATA_DIR}/domain.list ]; then
    log "downloading domain.list"
    wget -O ${LOCAL_DATA_DIR}/domain.list "https://raw.githubusercontent.com/sskaje/ubnt-config/dev/proxy/domain.list"
fi

if [ ! -s ${LOCAL_DATA_DIR}/wg_remote_address ]; then
    log "dnsmasq server ip is required"
    exit 1
fi

WG_REMOTE_ADDRESS=`cat ${LOCAL_DATA_DIR}/wg_remote_address`

test -f /etc/dnsmasq.d/domain.conf || touch /etc/dnsmasq.d/domain.conf

sed "/^#/d;/^$/d;s/8.8.8.8/${WG_REMOTE_ADDRESS}/g" ${LOCAL_DATA_DIR}/domain.list | awk -F , '{if($2!=""){print"server=/"$1"/"$2;}if($3!=""){print"ipset=/."$1"/"$3;}if($4!=""){print"address=/."$1"/"$4;}}' | tee /etc/dnsmasq.d/domain.conf

echo "$(date +%Y-%m-%d\ %H:%M:%S) - restart dnsmasq.service" 
systemctl restart dnsmasq.service

log "finish ${0}" 
EOF
    log "finish generate $script_name"

    script_name="02_post_config_ipset_net.sh"
    log "generating $script_name"
    cat > $UBNT_POSTCONFIG_DIR/$script_name <<- 'EOF'
#!/bin/bash
#
# 配置ipset net类型
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "Starting $0"

LOCAL_DIR=/config/user-data/local
LOCAL_DATA_DIR=${LOCAL_DIR}/data

if [ $# -eq 1 -a "$1" == "update" ]; then
    rm -f ${LOCAL_DATA_DIR}/ip.list
fi

if [ ! -s ${LOCAL_DATA_DIR}/ip.list ]; then
    log "downloading ip.list"
    wget -O ${LOCAL_DATA_DIR}/ip.list "https://raw.githubusercontent.com/sskaje/ubnt-config/dev/proxy/ip.list"
fi

sed '/^#/d;/^$/d' ${LOCAL_DATA_DIR}/ip.list | \
    while read -r line; do 
        log $line
        net_v=$(echo $line | cut -f1 -d,)
        ipset_v=$(echo $line | cut -f3 -d,)

        if [[ -z $net_v ]]; then
            log "net is required"
            exit
        fi

        ipset -! add $ipset_v $net_v
    done

log "finish ${0}" 
EOF
    log "finish generate $script_name"

    script_name="03_post_config_ipset_port.sh"
    log "generating $script_name"
    cat > $UBNT_POSTCONFIG_DIR/$script_name <<- 'EOF'
#!/bin/bash
#
# 配置ipset port类型
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "Starting $0"

LOCAL_DIR=/config/user-data/local
LOCAL_DATA_DIR=${LOCAL_DIR}/data

if [ $# -eq 1 -a "$1" == "update" ]; then
    rm -f ${LOCAL_DATA_DIR}/port.list
fi

if [ ! -s ${LOCAL_DATA_DIR}/port.list ]; then
    log "downloading port.list"
    wget -O ${LOCAL_DATA_DIR}/port.list "https://raw.githubusercontent.com/sskaje/ubnt-config/dev/proxy/port.list"
fi

sed '/^#/d;/^$/d' ${LOCAL_DATA_DIR}/port.list | \
    while read -r line; do 
        log $line
        port_v=$(echo $line | cut -f1 -d,)
        ipset_v=$(echo $line | cut -f3 -d,)

        if [[ -z $port_v ]]; then
            log "port is required"
            exit
        fi

        ipset -! add $ipset_v ${port_v}
    done

log "finish ${0}" 
EOF
    log "finish generate $script_name"

    script_name="04_post_config_firewall.sh"
    log "generating $script_name"
    cat > $UBNT_POSTCONFIG_DIR/$script_name <<- 'EOF'
#!/bin/bash
#
# 配置防火墙
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "Starting $0"

log "l2tp启用翻墙"
test -z "$(iptables -t mangle -L VYATTA_FW_IN_HOOK -v | grep 'l2tp+')" && iptables -t mangle -A VYATTA_FW_IN_HOOK -i l2tp+ -j AUTO_VPN

log "pptp启用翻墙"
test -z "$(iptables -t mangle -L VYATTA_FW_IN_HOOK -v | grep 'pptp+')" && iptables -t mangle -A VYATTA_FW_IN_HOOK -i pptp+ -j AUTO_VPN

log "finish ${0}" 
EOF
    log "finish generate $script_name"
}

# 生成手动更新dnsmasq脚本
function generate_update_dnsmasq_script() {
    script_name="update_dnsmasq.sh"
    log "generating $script_name"
    cat > $LOCAL_SCRIPTS_DIR/$script_name <<- 'EOF'
#!/bin/bash
#
# 手动更新dnsmasq脚本
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

function log() {
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $1..."
}

log "Starting $0" 

UBNT_POSTCONFIG_DIR=/config/scripts/post-config.d

bash $UBNT_POSTCONFIG_DIR/01_post_config_dnsmasq_conf.sh update
bash $UBNT_POSTCONFIG_DIR/02_post_config_ipset_net.sh update
bash $UBNT_POSTCONFIG_DIR/03_post_config_ipset_port.sh update

log "finish ${0}" 
EOF
    log "finish generate $script_name"
}

function install() {
    create_directories
    add_debs_to_firstboot_install_packages
    generate_firstboot_script
    generate_preconfig_script
    generate_postconfig_script
    generate_update_dnsmasq_script
}

install

log "finish install.sh"