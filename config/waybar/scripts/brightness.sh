#!/usr/bin/env bash
# ============================================================
#  亮度控制：笔记本背光 (brightnessctl) + 外接显示器 (DDC/CI)
#
#  用法:
#    brightness.sh                    弹出主菜单（笔记本 / 外接屏）
#    brightness.sh menu [int|ext]     直接打开指定屏幕的调节菜单
#    brightness.sh int  get|up|down|set <pct>
#    brightness.sh ext  get|up|down|set <pct>|status
#
#  外接屏需要 ddcutil，首次使用请运行：
#    sudo ~/.config/waybar/scripts/setup-ddc.sh
#
#  状态栏显示的是"目标亮度"：滚轮后立即变化，实际下发交给后台 worker
#  反复重试（每次最多 3 次 + 1 秒间隔），直到显示器真正到达该值，最长 60 秒。
#  失败详情见 $XDG_RUNTIME_DIR/waybar-brightness/ddc.log
#
#  多台外接屏时，可用 DDC_DISPLAY=2 指定 ddcutil 的 display 编号。
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar-brightness"
CACHE_FILE="$STATE_DIR/ext-percent"
DETECT_FILE="$STATE_DIR/ext-display"
TARGET_FILE="$STATE_DIR/ext-target"
mkdir -p "$STATE_DIR"

DDC_DISPLAY="${DDC_DISPLAY:-}"
STEP="${BRIGHTNESS_STEP:-5}"
ROFI_FONT="JetBrainsMono Nerd Font 12"

# ------------------------- 通用工具 -------------------------
clamp() {
    local v="${1:-50}"
    [[ $v =~ ^-?[0-9]+$ ]] || v=50
    (( v < 1 )) && v=1
    (( v > 100 )) && v=100
    printf '%s\n' "$v"
}

refresh_waybar() {
    # waybar 配置里 custom/brightness-ext 的 signal 为 8
    pkill -RTMIN+8 waybar 2>/dev/null || true
}

rofi_menu() {
    local prompt=$1
    shift
    rofi -dmenu -i -p "$prompt" -font "$ROFI_FONT" -l 16 "$@"
}

make_bar() {
    local pct=$1 width=${2:-20} filled empty bar="" i
    filled=$(( (pct * width + 50) / 100 ))
    (( filled > width )) && filled=$width
    empty=$(( width - filled ))
    for ((i=0; i<filled; i++)); do bar+='█'; done
    for ((i=0; i<empty; i++));  do bar+='░'; done
    printf '%s' "$bar"
}

notify_error() {
    local detail=$1 last=""
    # 附上最后一次 ddcutil 的真实报错，方便定位
    [[ -s $STATE_DIR/ddc.log ]] && last=$(tail -n 1 "$STATE_DIR/ddc.log")
    command -v notify-send >/dev/null 2>&1 \
        && notify-send -a "亮度" "外接屏亮度调节失败" \
            "${detail}${last:+$'\n\n'$last}" 2>/dev/null || true
}

# ------------------------- 笔记本屏幕 -------------------------
int_get() {
    local p
    p=$(brightnessctl -m 2>/dev/null | awk -F, 'NR==1 {gsub(/%/, "", $4); print $4}')
    [[ $p =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "$p"
}

int_set() {
    local p
    p=$(clamp "$1")
    brightnessctl set "${p}%" -q 2>/dev/null
}

int_step() {
    local cur
    cur=$(int_get) || cur=50
    case "$1" in
        up)   int_set $((cur + STEP)) ;;
        down) int_set $((cur - STEP)) ;;
    esac
}

# ------------------------- 外接显示器 -------------------------
ext_installed() {
    command -v ddcutil >/dev/null 2>&1
}

# 串行化 DDC 调用，避免快速滚轮时多个 ddcutil 抢 I2C 总线
ddc_run() {
    local lock="$STATE_DIR/ddc.lock"
    (
        flock -w 20 9 || exit 1
        "$@"
    ) 9>"$lock"
}

# 带重试的 ddcutil 调用：DDC/CI 偶发无响应（尤其廉价显示器）时自动再试，
# 失败详情写到日志，方便排查
DDC_LOG="$STATE_DIR/ddc.log"

ddc_retry() {
    local attempt out err
    for attempt in 1 2 3; do
        if out=$(ddc_run ddcutil "$@" 2>"$STATE_DIR/ddc.err"); then
            printf '%s' "$out"
            return 0
        fi
        err=$(tr -s ' \n' ' ' < "$STATE_DIR/ddc.err" 2>/dev/null)
        printf '%s try=%s args=[%s] err=%s\n' \
            "$(date '+%F %T')" "$attempt" "$*" "${err:-无输出}" >> "$DDC_LOG"
        sleep 0.3
    done
    return 1
}

ext_display() {
    if [[ -n $DDC_DISPLAY ]]; then
        printf '%s\n' "$DDC_DISPLAY"
        return 0
    fi
    if [[ -s $DETECT_FILE ]]; then
        cat "$DETECT_FILE"
        return 0
    fi
    local n
    n=$(ddc_retry detect --brief \
        | awk '/^Display [0-9]+/ {print $2; exit}')
    [[ -n $n ]] || return 1
    printf '%s\n' "$n" > "$DETECT_FILE"
    printf '%s\n' "$n"
}

# 输出: <当前值> <最大值>（取自 VCP 10 的 continuous 输出）
ext_read() {
    local disp out
    disp=$(ext_display) || return 1
    out=$(ddc_retry getvcp 10 --brief --display "$disp") || {
        # display 编号可能在拔插后变化，清缓存后重试一次
        [[ -z $DDC_DISPLAY ]] && rm -f "$DETECT_FILE"
        disp=$(ext_display) || return 1
        out=$(ddc_retry getvcp 10 --brief --display "$disp") || return 1
    }
    awk '$1=="VCP" && $2=="10" && $3=="C" {print $4, $5; exit}' <<<"$out"
}

ext_get_percent() {
    local cur max
    read -r cur max < <(ext_read) || return 1
    [[ $cur =~ ^[0-9]+$ && $max =~ ^[0-9]+$ ]] || return 1
    (( max > 0 )) || return 1
    printf '%s\n' "$(( (cur * 100 + max / 2) / max ))"
}

ext_cached_any() {
    local p
    [[ -s $CACHE_FILE ]] || return 1
    read -r p < "$CACHE_FILE"
    [[ $p =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "$p"
}

# 目标亮度：状态栏显示的就是它（先落到 target，DDC 慢慢追）
# 取值顺序：目标值 -> 上次缓存 -> 实时读取
ext_target() {
    local p
    if [[ -s $TARGET_FILE ]]; then
        read -r p < "$TARGET_FILE"
        [[ $p =~ ^[0-9]+$ ]] && { printf '%s\n' "$p"; return 0; }
    fi
    ext_cached_any || ext_get_percent
}

# 供状态栏/菜单显示：直接用目标值（即时返回，不必等 DDC 回读）
ext_cached_percent() {
    ext_target
}

ext_set_percent() {
    local pct
    pct=$(clamp "$1")
    # 先把目标值落地：状态栏立刻显示目标，实际亮度由后台去追
    printf '%s\n' "$pct" > "$TARGET_FILE"
    printf '%s\n' "$pct" > "$CACHE_FILE"
    refresh_waybar
    start_apply_worker
    return 0
}

# 把 target 下发一次；返回 0 表示已到达或下发成功
ext_apply_target() {
    local tgt disp cur max raw
    [[ -s $TARGET_FILE ]] || return 1
    read -r tgt < "$TARGET_FILE"
    [[ $tgt =~ ^[0-9]+$ ]] || return 1
    disp=$(ext_display) || return 1

    if read -r cur max < <(ext_read) && [[ $max =~ ^[0-9]+$ ]] && (( max > 0 )); then
        :
    else
        max=100
    fi

    raw=$(( (tgt * max + 50) / 100 ))
    (( raw < 1 )) && raw=1
    (( cur == raw )) && return 0

    ddc_retry setvcp 10 "$raw" --display "$disp" \
        --max-setvcp-and-verify-tries=3 >/dev/null
}

start_apply_worker() {
    nohup bash "$0" _apply-worker >/dev/null 2>&1 &
}

# 后台反复下发，直到实际亮度等于目标值（最多 60 秒，始终以最新 target 为准）
apply_worker() {
    local lock="$STATE_DIR/apply.lock" deadline tgt
    exec 8>"$lock"
    flock -n 8 || exit 0    # 已有 worker 在跑，它会自动追最新的目标
    deadline=$(( $(date +%s) + 60 ))

    while (( $(date +%s) < deadline )); do
        [[ -s $TARGET_FILE ]] || exit 0
        read -r tgt < "$TARGET_FILE"
        [[ $tgt =~ ^[0-9]+$ ]] || exit 0
        if ext_apply_target; then
            # 下发期间目标可能又被滚轮改了，改了就继续追新值
            local now=""
            [[ -s $TARGET_FILE ]] && read -r now < "$TARGET_FILE"
            [[ $now == "$tgt" ]] && exit 0
            continue
        fi
        sleep 1
    done

    printf '%s 60s 内未能把外接屏亮度调到 %s%%\n' "$(date '+%F %T')" "$tgt" >> "$DDC_LOG"
    command -v notify-send >/dev/null 2>&1 \
        && notify-send -a "亮度" "外接屏亮度未生效" "反复重试 60 秒仍未到达 ${tgt}%" 2>/dev/null || true
}

ext_step() {
    local cur
    cur=$(ext_target) || cur=50
    case "$1" in
        up)   ext_set_percent $((cur + STEP)) ;;
        down) ext_set_percent $((cur - STEP)) ;;
    esac
}

# waybar custom module 的 JSON 输出
ext_status() {
    local p
    if ! ext_installed; then
        printf '{"text":"--","tooltip":"未安装 ddcutil\\n点击查看安装方法","class":"off"}\n'
        return 0
    fi
    if p=$(ext_cached_percent); then
        printf '{"text":"%s%%","tooltip":"外接显示器亮度 %s%%\\n左键菜单 · 滚轮调节","class":"on"}\n' \
            "$p" "$p"
    else
        printf '{"text":"--","tooltip":"外接显示器不可用\\n点击查看诊断","class":"off"}\n'
    fi
}

ddc_error() {
    local msg
    if ! ext_installed; then
        msg=$'未安装 ddcutil。\n\n请运行：\n  sudo pacman -S ddcutil\n  sudo modprobe i2c-dev\n\n或直接运行：\n  sudo '"$SCRIPT_DIR"$'/setup-ddc.sh'
    else
        msg=$'无法控制外接显示器亮度。\n\n请检查：\n  • 显示器已连接并开启 DDC/CI\n  • 已加载 i2c-dev：sudo modprobe i2c-dev\n  • 当前用户有 /dev/i2c-* 访问权限\n\n诊断命令：\n  ddcutil detect\n  ddcutil getvcp 10'
    fi
    rofi -e "$msg" -font "$ROFI_FONT" 2>/dev/null || true
}

# ------------------------- 菜单 -------------------------
set_by() {
    local kind=$1 pct
    pct=$(clamp "$2")
    if [[ $kind == int ]]; then
        int_set "$pct" || return 1
    else
        if ! ext_set_percent "$pct"; then
            ddc_error
            return 1
        fi
    fi
    refresh_waybar
}

menu_for() {
    local kind=$1 label=$2
    while true; do
        local cur
        if [[ $kind == int ]]; then
            cur=$(int_get) || cur=50
        else
            cur=$(ext_target) || { ddc_error; return 1; }
        fi

        local nearest=$(( (cur + STEP / 2) / STEP * STEP ))
        (( nearest < STEP )) && nearest=$STEP
        (( nearest > 100 )) && nearest=100

        local rows=() idx=0 selected=0 p bar
        rows+=("  ← 返回")
        rows+=("  + ${STEP}%")
        rows+=("  - ${STEP}%")
        rows+=("  + 1%")
        rows+=("  - 1%")
        rows+=("  ─────────────────────")
        idx=6

        for (( p=100; p>=STEP; p-=STEP )); do
            bar=$(make_bar "$p")
            if (( p == nearest )); then
                rows+=("$(printf '● %3d%%  %s' "$p" "$bar")")
                selected=$idx
            else
                rows+=("$(printf '  %3d%%  %s' "$p" "$bar")")
            fi
            ((idx++))
        done

        local choice
        choice=$(printf '%s\n' "${rows[@]}" \
            | rofi_menu "${label}  ${cur}%" \
                -mesg "↑↓ 选择 · Enter 应用 · Esc 关闭" \
                -selected-row "$selected")
        [[ -z $choice ]] && return 0

        case "$choice" in
            *返回*)          return 0 ;;
            *"+ 1%"*)        set_by "$kind" $((cur + 1)) ;;
            *"- 1%"*)        set_by "$kind" $((cur - 1)) ;;
            *"+ ${STEP}%"*)  set_by "$kind" $((cur + STEP)) ;;
            *"- ${STEP}%"*)  set_by "$kind" $((cur - STEP)) ;;
            *%*)
                local val
                val=$(sed -E 's/^[^0-9]*([0-9]+)%.*/\1/' <<<"$choice")
                [[ $val =~ ^[0-9]+$ ]] && set_by "$kind" "$val"
                ;;
        esac
    done
}

menu_main() {
    local ip ep eline
    ip=$(int_get) || ip="--"

    if ! ext_installed; then
        eline="未安装"
    elif ep=$(ext_cached_percent); then
        eline="${ep}%"
    else
        eline="不可用"
    fi

    local entries=(
        "$(printf '  󰌶  笔记本屏幕      %4s' "${ip}%")"
        "$(printf '  󰍹  外接显示器      %s' "$eline")"
    )

    local choice
    choice=$(printf '%s\n' "${entries[@]}" \
        | rofi_menu "亮度" -mesg "Enter 进入 · Esc 关闭")

    case "$choice" in
        *笔记本*) menu_for int "笔记本" ;;
        *外接*)   if ext_installed; then menu_for ext "外接屏"; else ddc_error; fi ;;
    esac
}

# ------------------------- 入口 -------------------------
case "${1:-menu}" in
    menu)
        case "${2:-}" in
            int) menu_for int "笔记本" ;;
            ext) if ext_installed; then menu_for ext "外接屏"; else ddc_error; fi ;;
            *)   menu_main ;;
        esac
        ;;
    int)
        case "${2:-get}" in
            get)  int_get ;;
            set)  int_set "${3:-50}" ;;
            up)   int_step up ;;
            down) int_step down ;;
            *) echo "用法: $0 int get|set <pct>|up|down" >&2; exit 2 ;;
        esac
        ;;
    ext)
        case "${2:-get}" in
            get)    ext_target ;;
            set)    ext_set_percent "${3:-50}" ;;
            up)     ext_step up || notify_error "请检查 ddcutil / i2c-dev 是否可用" ;;
            down)   ext_step down || notify_error "请检查 ddcutil / i2c-dev 是否可用" ;;
            status) ext_status ;;
            *) echo "用法: $0 ext get|set <pct>|up|down|status" >&2; exit 2 ;;
        esac
        ;;
    _apply-worker)
        apply_worker
        ;;
    *)
        echo "用法: $0 [menu [int|ext] | int ... | ext ...]" >&2
        exit 2
        ;;
esac
