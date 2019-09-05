#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: compile openwrt
#	Version: 1.0.0
#	Author: expoli
#	Blog: http://expoli.tech
#   created 2019.09.21
#   email zzucty@gmail.com,zzutcy@qq.com
#=================================================

# openwrt ENV
OPENWRT_VERSION="18.06.4"
OPENWRT_PLATFORM="x86"
OPENWRT_TARGETS="generic"
DOWNLOAD_DIR="./"
BUILD_DIR="./"
BUILD_TARGETS="Generic"
IMAGE_DIR="bin/targets/x86/generic"
ZIP_DIR="${BUILD_DIR}/openwrt_zip"
DEFAULT_PACKAGES="luci luci-app-upnp luci-proto-ipv6 kmod-e1000e kmod-tcp-bbr nginx shadowsocks-libev-config shadowsocks-libev-ss-local shadowsocks-libev-ss-redir shadowsocks-libev-ss-rules shadowsocks-libev-ss-server shadowsocks-libev-ss-tunnel luci-app-shadowsocks-libev luci-i18n-wol-zh-cn kmod-ebtables-ipv6 kmod-fs-vfat kmod-fs-ext4 kmod-ip6-tunnel kmod-ip6tables kmod-ipsec6 kmod-ipsec4 kmod-nft-nat6 kmod-nls-utf8 curl eapol-test-openssl firewall ip-full ip-bridge ipset-dns ipip iputils-traceroute6 iw-full zram-swap luci-app-advanced-reboot luci-i18n-aria2-zh-cn luci-i18n-firewall-zh-cn luci-i18n-freifunk-policyrouting-zh-cn luci-i18n-hd-idle-zh-cn  luci-i18n-minidlna-zh-cn luci-i18n-openvpn-zh-cn luci-i18n-qos-zh-cn luci-i18n-watchcat-zh-cn luci-ssl-openssl zabbix-agentd zabbix-extra-network zabbix-get python"

# Date
LOG_DATE='date "+%Y-%m-%d"'
LOG_TIME='date "+%H-%M-%S"'

CDATE=$(date "+%Y-%m-%d")
CTIME=$(date "+%H-%M-%S")

# SHELL ENV
SHELL_NAME="compile-openwrt"
SHELL_DIR=${PWD}
LOCK_FILE=".//compile-openwrt.lock"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"

# 加锁
shell_lock(){
    touch ${LOCK_FILE}
}

shell_unlock(){
    rm ${LOCK_FILE} -f
}

# 写日志
write_log(){
    LOG_INFO=$1
    echo "${CDATE} ${CTIME}: ${SHELL_NAME} : ${LOG_INFO} " >> ${SHELL_LOG}
}

#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu|Ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu|Ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}

# 安装依赖
installation_dependency(){
    if [[ ${release} == "centos" ]]; then
        yum -y update 
        yum install -y axel libncurses5-dev zlib1g-dev gawk flex patch git-core g++ subversion xz zip unzip make 
    else 
        if [[ ${release} == "ubuntu" || ${release} == "debian" ]]; then
            echo "installation_dependency"
            apt-get update -y
            apt-get install axel libncurses5-dev zlib1g-dev gawk flex patch git-core g++ subversion xz-utils zip unzip make -y
        fi
    fi
}
# 获取 openwrt-imagebuilder
# https://downloads.openwrt.org/releases/18.06.4/targets/x86/generic/openwrt-imagebuilder-18.06.4-x86-generic.Linux-x86_64.tar.xz
get_openwrt_imagebuilder(){
    DOWNLOAD_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${OPENWRT_PLATFORM}/${OPENWRT_TARGETS}/openwrt-imagebuilder-${OPENWRT_VERSION}-${OPENWRT_PLATFORM}-${OPENWRT_TARGETS}.Linux-x86_64.tar.xz"
    echo "${DOWNLOAD_URL}"
    axel -n 30 ${DOWNLOAD_URL} -o ${BUILD_DIR}/openwrt-imagebuilder-${OPENWRT_VERSION}-${OPENWRT_PLATFORM}-${OPENWRT_TARGETS}.Linux-x86_64.tar.xz
}

# 解压缩
unzip_openwrt_imagebuilder(){
    xz -d ${DOWNLOAD_DIR}/openwrt-imagebuilder-${OPENWRT_VERSION}-${OPENWRT_PLATFORM}-${OPENWRT_TARGETS}.Linux-x86_64.tar.xz
    cd ${BUILD_DIR} && tar -xvf ${DOWNLOAD_DIR}/openwrt-imagebuilder-${OPENWRT_VERSION}-${OPENWRT_PLATFORM}-${OPENWRT_TARGETS}.Linux-x86_64.tar 
}

# 测试
compile_test(){
    cd ${BUILD_DIR}/openwrt-imagebuilder-${OPENWRT_VERSION}-${OPENWRT_PLATFORM}-${OPENWRT_TARGETS}.Linux-x86_64 && make info
}

# 编译
compile_openwrt(){
    PACKAGES_TMP=$1
    PACKAGES=${PACKAGES_TMP:-${DEFAULT_PACKAGES}}
    COMPILE_OPTION="PROFILE=${BUILD_TARGETS} PACKAGES=${PACKAGES}"
    echo "${COMPILE_OPTION}"
    cd ${BUILD_DIR}/openwrt-imagebuilder-${OPENWRT_VERSION}-${OPENWRT_PLATFORM}-${OPENWRT_TARGETS}.Linux-x86_64 && make image PROFILE=${BUILD_TARGETS} PACKAGES="${PACKAGES}"
}

# 打包压缩
zip_images(){
    zip -r ${BUILD_DIR}/openwrt-image-${OPENWRT_VERSION}-${OPENWRT_PLATFORM}-${OPENWRT_TARGETS}.Linux-x86.zip ${BUILD_DIR}/openwrt-imagebuilder-${OPENWRT_VERSION}-${OPENWRT_PLATFORM}-${OPENWRT_TARGETS}.Linux-x86_64/${IMAGE_DIR}
}

# 更换位置
mv_images(){
    mkdir -p ${ZIP_DIR}
    mv ${BUILD_DIR}/openwrt-image-${OPENWRT_VERSION}-${OPENWRT_PLATFORM}-${OPENWRT_TARGETS}.Linux-x86.zip ${ZIP_DIR}
}

# 主程序
main(){
    # 锁文件
    if [ -f $LOCK_FILE ];then
        echo "Shell is runing" && exit;
    fi
    shell_lock;
    # check_sys;
    # installation_dependency;
    # get_openwrt_imagebuilder;
    # unzip_openwrt_imagebuilder;
    compile_test;
    # compile_openwrt;
    # zip_images;
    # mv_images;
    shell_unlock;
}

main


