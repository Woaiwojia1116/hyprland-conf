#!/usr/bin/env bash
# ============================================================
#  一键启用外接显示器亮度控制 (DDC/CI)
#
#  用法：
#    sudo ~/.config/waybar/scripts/setup-ddc.sh
#
#  作用：
#    1. 安装 ddcutil
#    2. 加载 i2c-dev 内核模块
#    3. 刷新 udev 规则，让当前桌面用户可访问 /dev/i2c-*
#    4. 检测支持 DDC/CI 的显示器
# ============================================================
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "请用 root 运行：" >&2
    echo "  sudo $0" >&2
    exit 1
fi

echo "==> 1/4 安装 ddcutil"
if pacman -Qq ddcutil >/dev/null 2>&1; then
    echo "    ddcutil 已安装，跳过"
else
    pacman -S --needed --noconfirm ddcutil
fi

echo "==> 2/4 加载 i2c-dev 内核模块"
modprobe i2c-dev
echo "    $(lsmod | awk '$1=="i2c_dev" {print "i2c_dev 已加载"}' || true)"

echo "==> 3/4 刷新 udev 规则"
udevadm control --reload-rules
udevadm trigger --action=add --subsystem-match=i2c-dev
sleep 0.5

echo "==> 4/4 检测显示器"
if ! ddcutil detect --brief; then
    echo
    echo "⚠ 未检测到支持 DDC/CI 的显示器。"
    echo "  请确认显示器已开机、使用 HDMI/DP 连接，并在显示器菜单里开启 DDC/CI。"
    exit 0
fi

# 找到调用安装的桌面用户（sudo 或 pkexec 两种方式）
TARGET_USER="${SUDO_USER:-}"
TARGET_UID="${SUDO_UID:-}"
if [[ -z $TARGET_USER && -n ${PKEXEC_UID:-} ]]; then
    TARGET_UID="$PKEXEC_UID"
    TARGET_USER=$(getent passwd "$TARGET_UID" | cut -d: -f1)
fi

if [[ -n $TARGET_USER ]]; then
    echo
    echo "==> 验证普通用户权限 (${TARGET_USER})"
    if runuser -u "$TARGET_USER" -- \
        env HOME="$(getent passwd "$TARGET_UID" | cut -d: -f6)" \
            XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" \
            ddcutil getvcp 10 --brief >/dev/null 2>&1; then
        echo "✔ 外接屏亮度控制已可用。现在点击 waybar 的亮度图标即可。"
    else
        echo "⚠ 显示器已检测到，但普通用户暂时没有 /dev/i2c-* 权限。"
        echo "  请注销并重新登录一次，然后再试。"
    fi
fi

# 让 waybar 立刻重新读取外接屏亮度
pkill -RTMIN+8 -x waybar 2>/dev/null || true
