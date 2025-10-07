#!/bin/bash
# auto_load_tcp_pcc.sh
# 自动检查 tcp_pcc 模块，缺失时下载 headers + 源码并编译

set -e

MODULE_NAME="tcp_pcc"
SYSCTL_CONF="/etc/sysctl.d/99-tcp_pcc.conf"

install_headers_and_source() {
    echo "=== 安装内核 headers 和源码 ==="
    
    # 获取当前内核版本
    KVER=$(uname -r)
    echo "当前内核版本: $KVER"

    # 检查 headers
    if [ ! -d "/lib/modules/$KVER/build" ]; then
        echo "内核 headers 不存在，尝试安装..."
        if command -v apt >/dev/null 2>&1; then
            apt update
            apt install -y "linux-headers-$KVER"
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y "kernel-devel-$KVER" "kernel-headers-$KVER"
        else
            echo "请手动安装内核 headers"
            exit 1
        fi
    else
        echo "内核 headers 已存在"
    fi
}

install_pcc() {
    echo "=== 编译 tcp_pcc 模块 ==="
    apt install git
    git clone https://github.com/flben233/PCC-Plus.git -b vivace
    # 假设源码在当前目录 tcp_pcc/
    SRC_PATH="$PWD/PCC-Plus/src"
    cd "$SRC_PATH"
    if [ ! -f "$SRC_PATH/$MODULE_NAME.ko" ]; then
        make
    fi
    echo "=== 加载模块并设置为默认算法 ==="
    if ! lsmod | grep -q "^$MODULE_NAME"; then
        insmod "$MODULE_NAME.ko"
    fi
    available=$(cat /proc/sys/net/ipv4/tcp_available_congestion_control)
    if ! echo "$available" | grep -qw "pcc"; then
        echo "pcc未出现在可用算法中，请检查编译安装过程是否出错"
        exit 1
    fi
    cd -
}

set_default() {
    # 设置默认算法
    sysctl -w net.ipv4.tcp_congestion_control=pcc
    echo "net.ipv4.tcp_congestion_control = pcc" | sudo tee $SYSCTL_CONF
    sysctl --system
    echo "当前默认算法: $(cat /proc/sys/net/ipv4/tcp_congestion_control)"
}

main() {
    if lsmod | grep -q "^$MODULE_NAME"; then
        echo "模块 $MODULE_NAME 已加载"
    else
        echo "模块 $MODULE_NAME 未加载，准备安装和编译..."
        install_headers_and_source
        install_pcc
    fi
    set_default
}

main
