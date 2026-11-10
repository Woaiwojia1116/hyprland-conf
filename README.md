<div align="center">

# 🐟 MC's Dotfiles

**Arch Linux · Hyprland · Wayland · Catppuccin Mocha**

一套日常使用的 Hyprland 桌面配置：暖色磨砂玻璃、胶囊式 Waybar、静态 + 动态双壁纸，
以及中文输入法和一套顺手的快捷键。

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=archlinux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/WM-Hyprland-cba6f7?style=flat-square)](https://hypr.land/)
[![Wayland](https://img.shields.io/badge/Display-Wayland-89b4fa?style=flat-square)](https://wayland.freedesktop.org/)
[![Catppuccin Mocha](https://img.shields.io/badge/Theme-Catppuccin_Mocha-f5c2e7?style=flat-square)](https://catppuccin.com/)

<a href="wallpapers/current-desktop.png">
  <img src="docs/preview.jpg" alt="桌面与锁屏壁纸预览" width="100%">
</a>

<sub>左：桌面壁纸（eDP-1） · 右：锁屏壁纸</sub>

</div>

## 📖 简介

这是一份从本人正在使用的系统中整理出来的配置存档，不是从零编写的模板。
仓库里的文件均对应当前生效的版本，已剔除 `*.bak-*`、Waybar 历史备份等旧文件。

| 组件 | 说明 |
| --- | --- |
| **Hyprland** | 主配置为 Lua 格式的 `hyprland.lua`；`hyprland.conf` 是空占位文件 |
| **Kitty** | Catppuccin Mocha 配色，JetBrainsMono Nerd Font，保留编程连字 |
| **Waybar** | 顶部悬浮胶囊，分组模块；含亮度、电源、通知等自定义脚本 |
| **SwayNC** | 通知中心 / 控制中心，与 Waybar 联动 |
| **Hyprlock / Hypridle** | 磨砂锁屏；空闲 5 分钟自动锁定 |
| **Hyprpaper / mpvpaper** | 笔记本静态壁纸 + 外接屏视频壁纸 |
| **Fcitx5** | Rime + 键盘 US，默认中文输入方案 |
| **Fastfetch / Starship** | 终端欢迎信息（随机 logo）与 Shell 提示符 |

## ✨ 特性

- **Catppuccin Mocha 暖色主题**：桌面、终端、Waybar、锁屏使用同一套调色板。
- **磨砂玻璃质感**：Hyprland acrylic 模糊、非活动窗口压暗、双色渐变边框、弹簧动画。
- **胶囊式 Waybar**：nav / hero / media / hardware / status 分组布局，中央时钟为视觉焦点。
- **双屏壁纸**：笔记本 `eDP-1` 使用静态壁纸，外接屏 `HDMI-A-1` 由 `mpvpaper` 播放视频壁纸。
- **亮度双控**：笔记本背光走 `brightnessctl`，外接屏走 DDC/CI，带 rofi 菜单和异步重试。
- **完整中文环境**：Fcitx5 + Rime，Hyprland 已配置输入法环境变量与弹窗模糊。
- **Lua 配置**：使用 Hyprland 新版 Lua 配置 API，结构比传统 `.conf` 更清晰。

## 📂 目录结构

```text
.
├── config/
│   ├── hypr/
│   │   ├── hyprland.lua        # 主配置（Lua API）
│   │   ├── hyprland.conf       # 空占位文件
│   │   ├── hyprpaper.conf      # 静态壁纸
│   │   ├── hyprlock.conf       # 锁屏
│   │   └── hypridle.conf       # 空闲管理
│   ├── kitty/
│   │   ├── kitty.conf          # 当前配置
│   │   └── kittyback.conf      # 旧版参考
│   ├── waybar/
│   │   ├── config.jsonc        # 模块与布局
│   │   ├── style.css           # 样式
│   │   ├── theme.css           # Catppuccin 调色板
│   │   └── scripts/            # 亮度、电源、DDC 初始化
│   ├── swaync/                 # 通知中心
│   ├── fastfetch/              # 欢迎信息 + logo
│   ├── fcitx5/                 # 输入法
│   └── starship.toml
├── shell/
│   └── bashrc                  # 对应 ~/.bashrc
├── wallpapers/
│   ├── current-desktop.png     # 当前桌面壁纸
│   ├── hyprlock-2.jpg          # 锁屏壁纸
│   ├── 1.jpg                   # 备用壁纸
│   ├── 收藏/                   # 壁纸收藏
│   └── video/1.mp4             # 外接屏动态壁纸
├── docs/
│   └── preview.jpg             # README 预览图
└── MANIFEST.sha256             # 文件校验清单
```

## 🖼️ 壁纸

| 文件 | 用途 | 尺寸 / 大小 |
| --- | --- | --- |
| `wallpapers/current-desktop.png` | 笔记本桌面壁纸（`eDP-1`） | 4000 × 2250 |
| `wallpapers/hyprlock-2.jpg` | 锁屏背景 | 4000 × 2667 |
| `wallpapers/1.jpg` | 备用静态壁纸 | 4004 × 2160 |
| `wallpapers/收藏/` | 6 张二次元 / DeepSeek 壁纸 | — |
| `wallpapers/video/1.mp4` | 外接屏 `mpvpaper` 动态壁纸 | 约 53 MB |

> 壁纸仅作个人配置展示，版权归原作者所有。若仓库公开，建议确认壁纸的再分发许可；
> 也可以只保留 `docs/preview.jpg` 并删除原始壁纸。

## 🚀 安装

以下步骤以 **Arch Linux + Hyprland** 为前提。其他发行版请自行替换包管理器。

### 1. 克隆仓库

```bash
git clone https://github.com/<your-name>/dotfiles.git
cd dotfiles
```

### 2. 备份现有配置

```bash
BACKUP="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

for dir in hypr kitty waybar swaync fastfetch fcitx5; do
    [ -d "$HOME/.config/$dir" ] && cp -a "$HOME/.config/$dir" "$BACKUP/"
done

cp -a "$HOME/.bashrc" "$BACKUP/bashrc" 2>/dev/null || true
echo "已备份到：$BACKUP"
```

### 3. 安装依赖

```bash
sudo pacman -S --needed \
  hyprland hyprpaper hyprlock hypridle hyprlauncher mpvpaper \
  kitty waybar swaync \
  fcitx5 fcitx5-rime fcitx5-configtool fcitx5-gtk fcitx5-qt \
  starship fastfetch rofi ddcutil brightnessctl playerctl \
  polkit-gnome ttf-jetbrains-mono-nerd noto-fonts-cjk \
  grim slurp wl-clipboard dolphin pavucontrol \
  xdg-desktop-portal-hyprland
```

字体是必需的：Waybar、Kitty、Hyprlock 都使用 `JetBrainsMono Nerd Font`，
缺少 Nerd Font 时图标会显示为方框。

### 4. 部署配置

```bash
cp -a config/. "$HOME/.config/"
cp shell/bashrc "$HOME/.bashrc"
```

如果你更喜欢用符号链接管理 dotfiles，也可以对每个目录分别使用
`ln -s "$PWD/config/hypr" "$HOME/.config/hypr"` 等方式，但本仓库内的脚本默认按复制方式使用。

### 5. 替换硬编码路径

配置中保留了原机器的绝对路径 `/home/MC`。如果新用户名不同，先统一替换：

```bash
grep -rIl '/home/MC' config | xargs -r sed -i "s|/home/MC|$HOME|g"
```

然后检查显示器名称。配置里写死了：

- `eDP-1`：笔记本屏幕；
- `HDMI-A-1`：外接屏幕。

用 `hyprctl monitors` 查看实际名称，再修改 `hyprpaper.conf`、`hyprlock.conf`
和 `hyprland.lua` 中对应的值。

### 6. 放回壁纸

```bash
mkdir -p "$HOME/下载" "$HOME/Downloads"

cp wallpapers/current-desktop.png "$HOME/下载/1.png"
cp wallpapers/hyprlock-2.jpg      "$HOME/Downloads/2.jpg"
cp wallpapers/video/1.mp4         "$HOME/Downloads/1.mp4"
```

如果使用了第 5 步的路径替换，请相应改成替换后的路径。

### 7. 重新加载

```bash
hyprctl reload

killall waybar 2>/dev/null
waybar >/dev/null 2>&1 &

pkill hyprpaper 2>/dev/null
hyprpaper >/dev/null 2>&1 &
```

重新登录后会自动执行完整启动流程（Fcitx5 → 壁纸 → polkit → SwayNC → Waybar → Hypridle）。

### 8. 可选：外接屏亮度

首次使用 DDC/CI 前执行一次：

```bash
sudo ~/.config/waybar/scripts/setup-ddc.sh
```

## ⌨️ 常用快捷键

主修饰键为 `SUPER`（Windows 键）。

| 快捷键 | 功能 |
| --- | --- |
| `SUPER + T` | 打开 Kitty |
| `SUPER + Q` | 关闭当前窗口 |
| `SUPER + E` | 打开 Dolphin |
| `SUPER + R` | 打开 `hyprlauncher` |
| `SUPER + L` | 锁屏 |
| `SUPER + M` | 电源菜单 / 退出 Hyprland |
| `SUPER + V` | 切换窗口浮动 |
| `SUPER + P` | 切换伪平铺 |
| `SUPER + J` | 切换 dwindle 分屏方向 |
| `SUPER + 方向键` | 移动焦点 |
| `SUPER + 1..0` | 切换工作区 |
| `SUPER + Shift + 1..0` | 把窗口移到对应工作区 |
| `SUPER + S` | 打开/关闭临时工作区 |
| `SUPER + Shift + S` | 把窗口移到临时工作区 |
| `SUPER + Print` | 区域截图到剪贴板 |
| `SUPER + Shift + Print` | 全屏截图到剪贴板 |
| `SUPER + 左键拖动` | 移动窗口 |
| `SUPER + 右键拖动` | 调整窗口大小 |
| `SUPER + 滚轮` | 切换工作区 |
| 三指横滑 | 切换工作区 |

音量、亮度、播放控制等媒体键也已绑定。

## 🎨 主题与设计

- **调色板**：Catppuccin Mocha，定义在 `config/waybar/theme.css`，换主题只需改这一个文件。
- **Hyprland**：`gaps_in 6 / gaps_out 16`、圆角 12、2px 双色渐变边框、
  acrylic 模糊、非活动窗口 `dim`、弹簧动画。
- **Waybar**：顶部悬浮胶囊，模块按冷色 / 暖色分区，中间用 `custom/seam` 分隔。
- **Hyprlock**：背景模糊 3 次、加噪点、暖色输入框，与桌面保持同一套质感。
- **窗口规则**：Kitty 半透明、浏览器保持不透明，Waybar / SwayNC / rofi / Fcitx5 弹窗统一模糊。

## ⚠️ 注意事项

- **`hyprland.conf` 是空文件**，真正生效的是 `hyprland.lua`，修改时不要改错。
- `hyprland.lua` 使用的是较新的 Hyprland Lua 配置 API（本机版本 `0.57.1`）。
  旧版 Hyprland 无法加载该文件，需要先升级，或改用传统 `hyprland.conf`。
- 配置依赖绝对路径 `/home/MC`，换机器时务必执行第 5 步的替换。
- 显示器名 `eDP-1` / `HDMI-A-1` 按原机器写死，换设备后需要修改。
- Waybar 配置中的图标使用 Nerd Font 私有区码位，编辑时请避免被格式化工具剥除。
- `hyprland.lua` 中的 `menu` 变量指向 `hyprlauncher`；未安装时 `SUPER + R` 不可用，
  可改成 `rofi -show drun`。
- 动态壁纸依赖 `mpvpaper`，并且只作用于 `HDMI-A-1`；没有外接屏时可删除对应启动行。
- `wallpapers/video/1.mp4` 约 53 MB：GitHub 单文件上限为 100 MB，使用 `git push` 没问题，
  但网页拖拽上传单文件上限是 25 MB。如果不想让仓库过大，可以删除该文件并注释掉
  `hyprland.lua` 中的 `mpvpaper` 启动行。

## ☁️ 上传到 GitHub

如果这个目录还不是 Git 仓库，可以按下面的步骤初始化并推送：

```bash
cd ~/dotfiles-backup-20261110   # 或你重命名后的目录
git init
git add .
git commit -m "chore: initial dotfiles"
git branch -M main
git remote add origin git@github.com:<your-name>/dotfiles.git
git push -u origin main
```

使用 HTTPS 时，把远程地址换成
`https://github.com/<your-name>/dotfiles.git`。

也可以使用 GitHub CLI 直接创建仓库：

```bash
gh repo create dotfiles --private --source=. --remote=origin --push
```

## 🙏 致谢

- [Catppuccin](https://github.com/catppuccin/catppuccin) — 配色方案
- [Hyprland Wiki](https://wiki.hypr.land/) — 配置文档
- [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots) — Waybar 胶囊布局灵感
- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — 悬浮组件灵感
- [SwayNC](https://github.com/ErikReider/SwayNotificationCenter) — 通知中心

## 📄 License

个人配置存档，仅供学习与参考。第三方主题、字体与壁纸的版权归各自原作者所有。
