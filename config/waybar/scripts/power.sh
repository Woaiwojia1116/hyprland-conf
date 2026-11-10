#!/usr/bin/env bash
# rofi 电源菜单
set -euo pipefail

choice=$(printf ' Shutdown\n Reboot\n Suspend\n Logout' \
    | rofi -dmenu -i -p ' Power')

case "${choice// /}" in
    Shutdown) systemctl poweroff ;;
    Reboot)   systemctl reboot ;;
    Suspend)  systemctl suspend ;;
    Logout)   hyprctl dispatch exit ;;
    *) exit 0 ;;
esac
