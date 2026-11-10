#!/usr/bin/env bash
# ============================================================
# fastfetch 启动画面：从 ~/大肥鱼 随机选图，按终端尺寸自适应排版
# - 每次启动随机（自动避开上一次用过的图）
# - 宽窗口：图片在左、系统信息在右
# - 窄窗口：自动精简信息模块，保证图片与文字都不折行、不重叠
# ============================================================
set -u

IMG_DIR="$HOME/大肥鱼"
BASE_CONF="$HOME/.config/fastfetch/config.jsonc"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/fastfetch"
LAST_FILE="$CACHE_DIR/last-image"

# ---------- 终端行列 ----------
read -r rows cols < <(stty size 2>/dev/null) || true
[[ "${rows:-}" =~ ^[0-9]+$ ]] || rows=24
[[ "${cols:-}" =~ ^[0-9]+$ ]] || cols=80

# ---------- 单个字符单元的像素尺寸（用于按比例算图片框） ----------
cell_w=8
cell_h=17
if command -v python3 >/dev/null 2>&1; then
    read -r cw ch < <(python3 -c '
import fcntl, termios, struct, sys
try:
    _r, c, x, y = struct.unpack("HHHH", fcntl.ioctl(0, termios.TIOCGWINSZ, b"\0" * 8))
    if c and x and _r and y:
        print(max(1, x // c), max(1, y // _r))
except Exception:
    pass
' 2>/dev/null) || true
    [[ "${cw:-}" =~ ^[0-9]+$ ]] && cell_w=$cw
    [[ "${ch:-}" =~ ^[0-9]+$ ]] && cell_h=$ch
fi

# ---------- 收集图片 ----------
mapfile -d '' -t imgs < <(find "$IMG_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
       -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) \
    -print0 2>/dev/null)

if (( ${#imgs[@]} == 0 )); then
    exec fastfetch --config "$BASE_CONF"
fi

# ---------- 随机选图（避开上一张） ----------
last=""
[[ -r "$LAST_FILE" ]] && last=$(<"$LAST_FILE")

pick=${imgs[0]}
if (( ${#imgs[@]} > 1 )); then
    for _ in 1 2 3 4 5; do
        pick=${imgs[RANDOM % ${#imgs[@]}]}
        [[ "$pick" != "$last" ]] && break
    done
fi
mkdir -p "$CACHE_DIR" 2>/dev/null && printf '%s\n' "$pick" > "$LAST_FILE"

# ---------- 测量信息区最宽行（去掉 ANSI 颜色码后） ----------
text_width() {
    local structure="${1:-}"
    if [[ -n "$structure" ]]; then
        fastfetch --config "$BASE_CONF" --logo none --structure "$structure" 2>/dev/null
    else
        fastfetch --config "$BASE_CONF" --logo none 2>/dev/null
    fi | LC_ALL=C.UTF-8 awk '{
            gsub(/\033\[[0-9;]*[A-Za-z]/, "")
            if (length($0) > m) m = length($0)
        } END { print m + 0 }'
}

PAD=2                # 图片左右留白列数
SAFE=2               # 预留余量，防止数值变化导致折行
GAP=$(( PAD * 2 + SAFE ))

structure=""
tw=$(text_width)
avail=$(( cols - tw - GAP ))

# 窄窗口：精简模块，给图片腾出空间
if (( avail < 10 )); then
    structure="title:os:kernel:uptime:shell:wm:terminal:memory:colors"
    tw=$(text_width "$structure")
    avail=$(( cols - tw - GAP ))
fi

# 实在放不下就不显示图片，只保证文字完整
if (( avail < 8 || rows < 12 )); then
    if [[ -n "$structure" ]]; then
        exec fastfetch --config "$BASE_CONF" --logo none --structure "$structure"
    fi
    exec fastfetch --config "$BASE_CONF" --logo none
fi

# ---------- 图片框尺寸 ----------
# 按最瘦长的常见壁纸（16:9 竖图，高/宽≈1.78）计算：宽度不超过多少行数才装得下
max_w=$(( (rows - 3) * cell_h * 100 / (cell_w * 178) ))
(( max_w < 8 )) && max_w=8

logo_w=$avail
(( logo_w > max_w )) && logo_w=$max_w
# 框高按宽高比收紧，避免图片下方留出大片空白
logo_h=$(( (logo_w * cell_w * 178 + cell_h * 100 - 1) / (cell_h * 100) + 1 ))
(( logo_h > rows - 3 )) && logo_h=$(( rows - 3 ))
(( logo_h < 4 )) && logo_h=4

# ---------- 转成 PNG ----------
# kitty 图形协议只认 PNG（其余格式不会显示），这里按目标像素尺寸缩好再交给 kitty
PNG_DIR="$CACHE_DIR/png"
mkdir -p "$PNG_DIR" 2>/dev/null
find "$PNG_DIR" -type f -mtime +7 -delete 2>/dev/null

make_png() {
    local src="$1" pw="$2" ph="$3" key stamp out
    key=$(printf '%s' "$src" | md5sum | cut -c1-12)
    stamp=$(stat -c '%Y-%s' -- "$src" 2>/dev/null | tr -d ' \n')
    out="$PNG_DIR/${key}-${stamp}-${pw}x${ph}.png"
    [[ -s "$out" ]] && { printf '%s\n' "$out"; return 0; }

    if command -v vipsthumbnail >/dev/null 2>&1; then
        vipsthumbnail "$src" --size "${pw}x${ph}" --output "$out" >/dev/null 2>&1
    fi
    if [[ ! -s "$out" ]] && command -v ffmpeg >/dev/null 2>&1; then
        ffmpeg -nostdin -loglevel error -y -i "$src" \
            -vf "scale=${pw}:${ph}:force_original_aspect_ratio=decrease" \
            -frames:v 1 "$out" >/dev/null 2>&1
    fi
    [[ -s "$out" ]] && printf '%s\n' "$out"
}

png=$(make_png "$pick" $(( logo_w * cell_w )) $(( logo_h * cell_h )))

# 按转换后的真实高度收紧图片框：横竖比例不同的图都不会在下方留空
if [[ -n "$png" ]] && command -v vipsheader >/dev/null 2>&1; then
    png_h_px=$(vipsheader -f height "$png" 2>/dev/null)
    if [[ "${png_h_px:-}" =~ ^[0-9]+$ ]] && (( png_h_px > 0 )); then
        logo_h=$(( (png_h_px + cell_h - 1) / cell_h ))
        (( logo_h > rows - 3 )) && logo_h=$(( rows - 3 ))
        (( logo_h < 4 )) && logo_h=4
    fi
fi

args=(
    --config "$BASE_CONF"
    --logo-width "$logo_w"
    --logo-height "$logo_h"
    --logo-padding-left "$PAD"
    --logo-padding-right "$PAD"
    --logo-padding-top 0
    --logo-padding-bottom 0
)
if [[ -n "$png" ]]; then
    args+=(--logo-type kitty-direct --logo "$png")
else
    # 转换失败就别硬塞 JPEG（kitty 解不了），保持文字排版完整
    args+=(--logo none)
fi
[[ -n "$structure" ]] && args+=(--structure "$structure")

exec fastfetch "${args[@]}"
