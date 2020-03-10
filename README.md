# ubnt自愈能力安装脚本

## 1. 概述

* ubnt路由器在升级固件后会删除所有配置和数据，除了/config目录，导致每次升级后都需要大量人工操作，执行此脚本后，自动设置好所有配置。
* 此脚本是安装程序，即安装后使ubnt具备自愈能力，故安装此脚本时需ubnt正常运转且已连接互联网。
* 请在UBNT路由器上切换到root用户执行此脚本。sudo su -

## 2. 说明

install.sh自动创建以下目录：

#### UBNT目录
UBNT目录会被EdgeOS默认自动执行或读取的目录。

packages目录：
```
/config/data/firstboot/install-packages 自动安装目录中的*.deb，仅在第一次启动时执行一次。
```

启动时按顺序自动执行的脚本目录:
```
/config/scripts/firstboot.d   升级完固件只执行一次
/config/scripts/pre-config.d  每次重启后在加载config.boot之前执行
/config/scripts/post-config.d 每次重启后在加载config.boot之后执行
```

#### LOCAL目录：
LOCAL目录存放本地用户数据。

```
/config/user-data/local 根目录
/config/user-data/local/etc 存放用户本地配置，install.sh会自动link到/etc下对应目录
/config/user-data/local/packages 本地包目录
/config/user-data/local/scripts 本地脚本目录
/config/user-data/local/data 本地数据目录
```

#### 3. Usage

注意：执行install.sh之前需要在/config/user-data/local/data目录创建wg_remote_address文件。比如：
```
    echo "192.168.2.1" > /config/user-data/local/data/wg_remote_address
```
 * ip为wireguard服务端内网ip，用于dnsmasq配置中server字段的dns。
 * 当前版本还不支持ubnt负载均衡方式，后续加入支持。

执行安装脚本：
```
bash install.sh
```

手动更新dnsmasq配置：（需先执行安装脚本）
```
bash /config/user-data/local/scripts/update_dnsmasq.sh 
```