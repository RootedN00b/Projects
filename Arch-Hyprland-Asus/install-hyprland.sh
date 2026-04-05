#!/usr/bin/env bash
# =============================================================================
#  Hyprland Minimal Installer — Arch Linux + NVIDIA (ASUS ROG Strix)
#  Includes: Dracula GTK theme, icons, cursor, SDDM, waybar, kitty, rofi
#
#  Reference: https://github.com/JaKooLit/Arch-Hyprland
#             https://wiki.hyprland.org/Nvidia/
#             https://wiki.archlinux.org/title/NVIDIA
#             https://draculatheme.com
#
#  Run as a regular user (NOT root). Script will sudo where needed.
#  Log: ~/hyprland-install.log
# =============================================================================

set -euo pipefail

# ── Log file ──────────────────────────────────────────────────────────────────
LOGFILE="$HOME/hyprland-install.log"
exec > >(tee -a "$LOGFILE") 2>&1
echo "=== Install started: $(date) ==="

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()   { echo -e "${YELLOW}[!]${NC} $*"; }
error()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }
header() {
    echo -e "\n${CYAN}══════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $*${NC}"
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
}

# ── Sanity checks ─────────────────────────────────────────────────────────────
[[ "$EUID" -eq 0 ]]        && error "Do NOT run as root. Run as your regular user."
[[ -f /etc/arch-release ]] || error "This script is for Arch Linux only."
ping -c1 -W3 archlinux.org &>/dev/null || error "No internet connection detected."

# ── Detect installed kernel package ───────────────────────────────────────────
detect_kernel_pkg() {
    local kpkg
    kpkg=$(pacman -Qeq | grep -E '^linux(-lts|-zen|-hardened|-rt)?$' | head -1)
    if [[ -z "$kpkg" ]]; then
        local uname_r
        uname_r=$(uname -r)
        if   [[ "$uname_r" == *lts*      ]]; then kpkg="linux-lts"
        elif [[ "$uname_r" == *zen*      ]]; then kpkg="linux-zen"
        elif [[ "$uname_r" == *hardened* ]]; then kpkg="linux-hardened"
        else kpkg="linux"
        fi
    fi
    echo "$kpkg"
}

KERNEL_PKG=$(detect_kernel_pkg)
HEADERS_PKG="${KERNEL_PKG}-headers"
log "Detected kernel package: $KERNEL_PKG  →  headers: $HEADERS_PKG"

# ── Welcome ───────────────────────────────────────────────────────────────────
header "Hyprland + Dracula Installer — NVIDIA / ASUS ROG Strix"
echo ""
echo -e "  Kernel  : ${CYAN}$KERNEL_PKG${NC}"
echo -e "  Theme   : ${CYAN}Dracula (GTK + Icons + Cursor + SDDM + Waybar + Kitty + Rofi)${NC}"
echo -e "  Log     : ${CYAN}$LOGFILE${NC}"
echo ""
warn "This will modify: /etc/mkinitcpio.conf, /etc/modprobe.d/, pacman hooks."
warn "A full system update will run first."
echo ""
read -rp "  Continue? [y/N]: " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ── NVIDIA driver choice ──────────────────────────────────────────────────────
echo ""
echo -e "  ${CYAN}NVIDIA driver choice:${NC}"
echo "  [1] nvidia-dkms       — proprietary, supports GTX 900+ (safe default)"
echo "  [2] nvidia-open-dkms  — open kernel module, requires Turing (RTX 20xx+)"
echo ""
read -rp "  Choose [1/2] (default: 1): " drv_choice
if [[ "${drv_choice:-1}" == "2" ]]; then
    NVIDIA_DRIVER="nvidia-open-dkms"
    log "Using nvidia-open-dkms."
else
    NVIDIA_DRIVER="nvidia-dkms"
    log "Using nvidia-dkms."
fi

# ── 1. Full system update ─────────────────────────────────────────────────────
header "Step 1 — System Update"
sudo pacman -Syu --noconfirm

# ── 2. Base build tools ───────────────────────────────────────────────────────
header "Step 2 — Base Build Tools"
sudo pacman -S --needed --noconfirm base-devel git curl wget

# ── 3. AUR helper (yay) ───────────────────────────────────────────────────────
header "Step 3 — AUR Helper (yay)"
if ! command -v yay &>/dev/null; then
    log "Installing yay..."
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    git clone --depth=1 https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    trap - EXIT
    rm -rf "$tmpdir"
    log "yay installed."
else
    log "yay already present — skipping."
fi

# ── 4. Linux headers ──────────────────────────────────────────────────────────
header "Step 4 — Linux Headers (DKMS requirement)"
sudo pacman -S --needed --noconfirm "$HEADERS_PKG"

# ── 5. NVIDIA drivers ─────────────────────────────────────────────────────────
header "Step 5 — NVIDIA Drivers ($NVIDIA_DRIVER)"
sudo pacman -S --needed --noconfirm \
    "$NVIDIA_DRIVER" \
    nvidia-utils \
    nvidia-settings \
    egl-wayland \
    libva-nvidia-driver

# ── 6. NVIDIA Wayland configuration ──────────────────────────────────────────
header "Step 6 — NVIDIA Wayland Configuration"

NVIDIA_CONF="/etc/modprobe.d/nvidia.conf"
if ! grep -q "nvidia-drm" "$NVIDIA_CONF" 2>/dev/null; then
    log "Writing $NVIDIA_CONF..."
    echo "options nvidia-drm modeset=1 fbdev=1" | sudo tee "$NVIDIA_CONF" > /dev/null
else
    log "$NVIDIA_CONF already configured — skipping."
fi

NOUVEAU_BLACKLIST="/etc/modprobe.d/blacklist-nouveau.conf"
if [[ ! -f "$NOUVEAU_BLACKLIST" ]]; then
    log "Blacklisting nouveau..."
    printf 'blacklist nouveau\noptions nouveau modeset=0\n' \
        | sudo tee "$NOUVEAU_BLACKLIST" > /dev/null
else
    log "nouveau already blacklisted — skipping."
fi

MKINIT_CONF="/etc/mkinitcpio.conf"
log "Backing up $MKINIT_CONF..."
sudo cp "$MKINIT_CONF" "${MKINIT_CONF}.bak"

if grep -Pq '\bkms\b' "$MKINIT_CONF" 2>/dev/null; then
    log "Removing 'kms' from HOOKS in mkinitcpio..."
    sudo sed -i -E 's/(\bkms\b)[[:space:]]?//g' "$MKINIT_CONF"
fi

if ! grep -q 'nvidia' "$MKINIT_CONF" 2>/dev/null; then
    log "Adding nvidia modules to MODULES array..."
    sudo sed -i \
        's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
        "$MKINIT_CONF"
    sudo sed -i 's/MODULES=( /MODULES=(/' "$MKINIT_CONF"
else
    log "mkinitcpio MODULES already contains nvidia entries — skipping."
fi

log "Rebuilding initramfs..."
sudo mkinitcpio -P

HOOK_DIR="/etc/pacman.d/hooks"
sudo mkdir -p "$HOOK_DIR"
HOOK_FILE="$HOOK_DIR/nvidia-initramfs.hook"
if [[ ! -f "$HOOK_FILE" ]]; then
    log "Creating pacman hook: $HOOK_FILE"
    sudo tee "$HOOK_FILE" > /dev/null <<HOOKEOF
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=${NVIDIA_DRIVER}
Target=${KERNEL_PKG}
Target=${HEADERS_PKG}

[Action]
Description=Rebuilding initramfs after NVIDIA or kernel update...
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
HOOKEOF
else
    log "Pacman hook already exists — skipping."
fi

# ── 7. Hyprland + core Wayland stack ─────────────────────────────────────────
header "Step 7 — Hyprland + Core Wayland Stack"

HYPRLAND_PKGS=(
    hyprland
    xorg-xwayland
    wayland
    wayland-protocols
    xdg-desktop-portal-hyprland
    xdg-desktop-portal
    xdg-utils
    xdg-user-dirs
    qt5-wayland
    qt6-wayland
    polkit-kde-agent
    dbus
)

sudo pacman -S --needed --noconfirm "${HYPRLAND_PKGS[@]}"

# ── 8. PipeWire audio ────────────────────────────────────────────────────────
header "Step 8 — PipeWire Audio"

AUDIO_PKGS=(
    pipewire
    pipewire-pulse
    wireplumber
    pipewire-alsa
    pipewire-jack
)

sudo pacman -S --needed --noconfirm "${AUDIO_PKGS[@]}"

log "Enabling PipeWire user services..."
systemctl --user enable --now pipewire.service        || true
systemctl --user enable --now pipewire-pulse.service  || true
systemctl --user enable --now wireplumber.service     || true

# ── 9. Display manager (SDDM) ────────────────────────────────────────────────
header "Step 9 — Display Manager (SDDM)"
sudo pacman -S --needed --noconfirm sddm qt5-declarative

for dm in gdm lightdm lxdm; do
    if systemctl is-enabled "$dm.service" &>/dev/null; then
        warn "Disabling conflicting display manager: $dm"
        sudo systemctl disable "$dm.service" || true
    fi
done

sudo systemctl enable sddm.service
log "SDDM enabled."

# ── 10. Minimal session tools ────────────────────────────────────────────────
header "Step 10 — Minimal Session Tools"

SESSION_PKGS=(
    waybar
    kitty
    rofi-wayland
    swww
    mako
    brightnessctl
    pamixer
    grim
    slurp
    wl-clipboard
    cliphist
    networkmanager
    network-manager-applet
    thunar
    noto-fonts
    noto-fonts-emoji
    ttf-jetbrains-mono-nerd
    papirus-icon-theme        # Base for Dracula-colored icons
    kvantum                   # Qt app theming engine
    qt5ct                     # Qt5 appearance config tool
    qt6ct                     # Qt6 appearance config tool
    nwg-look                  # GTK settings GUI for Wayland
    dconf                     # Required by gsettings to persist GTK theme settings
)

sudo pacman -S --needed --noconfirm "${SESSION_PKGS[@]}"

sudo systemctl enable NetworkManager.service
sudo usermod -aG video "$USER"
log "Added $USER to video group (required for brightnessctl)."

# ── 11. Dracula theme packages ───────────────────────────────────────────────
header "Step 11 — Dracula Theme (AUR packages)"
log "Installing Dracula GTK theme, cursor, and SDDM theme from AUR..."

# dracula-gtk-theme  : GTK 3/4 Dracula theme
# dracula-cursors-git: Dracula cursor set
# sddm-theme-dracula : Dracula SDDM login screen
# papirus-folders    : Recolor Papirus folder icons to Dracula purple
yay -S --needed --noconfirm \
    dracula-gtk-theme \
    dracula-cursors-git \
    sddm-theme-dracula \
    papirus-folders

log "Dracula AUR packages installed."

# ── 12. Apply Dracula theming ────────────────────────────────────────────────
header "Step 12 — Applying Dracula Theme"

# 12a. Recolor Papirus folders to Dracula purple (#bd93f9 → closest = violet)
log "Setting Papirus folder color to violet (Dracula purple)..."
papirus-folders -C violet --theme Papirus-Dark

# 12b. Apply GTK theme, icon theme, and cursor via gsettings (affects GTK apps)
log "Applying GTK theme settings..."
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

# gtk-3.0 settings.ini
cat > "$HOME/.config/gtk-3.0/settings.ini" <<'GTKEOF'
[Settings]
gtk-theme-name=Dracula
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Dracula-cursors
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 11
gtk-application-prefer-dark-theme=1
GTKEOF

# gtk-4.0 settings.ini (same values)
cat > "$HOME/.config/gtk-4.0/settings.ini" <<'GTKEOF'
[Settings]
gtk-theme-name=Dracula
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Dracula-cursors
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 11
gtk-application-prefer-dark-theme=1
GTKEOF

# Also write ~/.gtkrc-2.0 for any legacy GTK2 apps
cat > "$HOME/.gtkrc-2.0" <<'GTK2EOF'
gtk-theme-name="Dracula"
gtk-icon-theme-name="Papirus-Dark"
gtk-cursor-theme-name="Dracula-cursors"
gtk-cursor-theme-size=24
gtk-font-name="Noto Sans 11"
GTK2EOF

# 12c. Set cursor theme system-wide via /usr/share/icons/default
log "Setting system cursor theme..."
sudo mkdir -p /usr/share/icons/default
sudo tee /usr/share/icons/default/index.theme > /dev/null <<'CURSOREOF'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Dracula-cursors
CURSOREOF

# Also set user-level cursor override
mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" <<'CURSOREOF'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Dracula-cursors
CURSOREOF

# 12d. Configure Qt5/Qt6 to use kvantum + respect GTK dark theme
log "Configuring Qt theming (qt5ct / qt6ct)..."
mkdir -p "$HOME/.config/qt5ct" "$HOME/.config/qt6ct"

cat > "$HOME/.config/qt5ct/qt5ct.conf" <<'QT5EOF'
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Papirus-Dark
standard_dialogs=default
style=kvantum-dark

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x12JetBrainsMono Nerd Font\0\0\0\0\0\0\0\0\0\x32\x0\0\0\0\x0\0\0\0\x0\x5\x0)
general=@Variant(\0\0\0@\0\0\0\x16Noto Sans\0\0\0\0\0\0\0\0\0\x16\x0\0\0\0\x0\0\0\0\x0\x5\x0)

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
QT5EOF

# qt6ct mirrors qt5ct structure
cat > "$HOME/.config/qt6ct/qt6ct.conf" <<'QT6EOF'
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Papirus-Dark
standard_dialogs=default
style=kvantum-dark

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x12JetBrainsMono Nerd Font\0\0\0\0\0\0\0\0\0\x32\x0\0\0\0\x0\0\0\0\x0\x5\x0)
general=@Variant(\0\0\0@\0\0\0\x16Noto Sans\0\0\0\0\0\0\0\0\0\x16\x0\0\0\0\x0\0\0\0\x0\x5\x0)

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
QT6EOF

# 12e. Configure Kvantum to use its built-in KvDracula (closest match)
#      Kvantum ships KvDracula in kvantum-theme-dracula (AUR) but we use
#      the built-in dark theme as a reliable fallback without extra AUR pkg.
log "Configuring Kvantum theme..."
mkdir -p "$HOME/.config/Kvantum"
cat > "$HOME/.config/Kvantum/kvantum.kvconfig" <<'KVEOF'
[General]
theme=KvDark
KVEOF

# 12f. Configure SDDM to use Dracula theme
log "Configuring SDDM to use Dracula theme..."
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<'SDDMEOF'
[Theme]
Current=dracula
CursorTheme=Dracula-cursors
CursorSize=24
SDDMEOF

# 12g. Write Dracula waybar style.css
log "Writing Dracula waybar style.css..."
mkdir -p "$HOME/.config/waybar"
cat > "$HOME/.config/waybar/style.css" <<'CSSEOF'
/* ── Dracula Waybar Theme ──────────────────────────────────────────────────── */
/* Palette: https://draculatheme.com/contribute                                */
/* Background  #282a36   Foreground #f8f8f2   Comment  #6272a4                */
/* Purple      #bd93f9   Pink       #ff79c6   Cyan     #8be9fd                */
/* Green       #50fa7b   Yellow     #f1fa8c   Red      #ff5555   Orange #ffb86c */

* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", "Noto Sans", sans-serif;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(40, 42, 54, 0.92);
    color: #f8f8f2;
    border-bottom: 2px solid #bd93f9;
}

/* ── Workspaces ────────────────────────────────────────────────────────────── */
#workspaces button {
    padding: 0 6px;
    background-color: transparent;
    color: #6272a4;
    border-bottom: 2px solid transparent;
}

#workspaces button:hover {
    background-color: rgba(189, 147, 249, 0.15);
    color: #f8f8f2;
    border-bottom: 2px solid #bd93f9;
}

#workspaces button.active {
    color: #bd93f9;
    border-bottom: 2px solid #bd93f9;
    font-weight: bold;
}

#workspaces button.urgent {
    color: #ff5555;
    border-bottom: 2px solid #ff5555;
}

/* ── Modules — shared ──────────────────────────────────────────────────────── */
#clock,
#battery,
#cpu,
#memory,
#network,
#pulseaudio,
#tray,
#backlight,
#temperature {
    padding: 0 10px;
    color: #f8f8f2;
}

/* ── Individual module accent colors ──────────────────────────────────────── */
#clock          { color: #f1fa8c; }   /* yellow  */
#battery        { color: #50fa7b; }   /* green   */
#battery.warning{ color: #ffb86c; }   /* orange  */
#battery.critical{ color: #ff5555; }  /* red     */
#cpu            { color: #8be9fd; }   /* cyan    */
#memory         { color: #ff79c6; }   /* pink    */
#network        { color: #8be9fd; }   /* cyan    */
#network.disconnected { color: #ff5555; }
#pulseaudio     { color: #bd93f9; }   /* purple  */
#pulseaudio.muted { color: #6272a4; } /* comment */
#backlight      { color: #f1fa8c; }   /* yellow  */
#temperature    { color: #ffb86c; }   /* orange  */
#temperature.critical { color: #ff5555; }
#tray           { padding: 0 8px; }

/* ── Tooltip ───────────────────────────────────────────────────────────────── */
tooltip {
    background-color: #282a36;
    border: 1px solid #bd93f9;
    color: #f8f8f2;
    border-radius: 6px;
}
CSSEOF

# 12h. Write a matching Dracula waybar config
log "Writing Dracula waybar config.jsonc..."
cat > "$HOME/.config/waybar/config.jsonc" <<'WBEOF'
// ── Dracula Waybar Config ──────────────────────────────────────────────────
{
    "layer": "top",
    "position": "top",
    "height": 32,
    "spacing": 4,

    "modules-left":   ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right":  ["cpu", "memory", "temperature", "backlight",
                       "pulseaudio", "network", "battery", "tray"],

    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "1": "󰎤", "2": "󰎧", "3": "󰎪", "4": "󰎭", "5": "󰎱",
            "6": "󰎳", "7": "󰎶", "8": "󰎹", "9": "󰎼",
            "active": "󱓻", "default": "󰍹"
        },
        "on-click": "activate"
    },

    "hyprland/window": {
        "format": "{}",
        "max-length": 60,
        "separate-outputs": true
    },

    "clock": {
        "format": " {:%a %d %b  %H:%M}",
        "tooltip-format": "<tt>{calendar}</tt>"
    },

    "cpu": {
        "format": "󰍛 {usage}%",
        "interval": 2,
        "tooltip": false
    },

    "memory": {
        "format": "󰾆 {used:0.1f}G",
        "interval": 5
    },

    "temperature": {
        "critical-threshold": 85,
        "format": "󰔏 {temperatureC}°C",
        "format-critical": "󰸁 {temperatureC}°C"
    },

    "backlight": {
        "format": "{icon} {percent}%",
        "format-icons": ["󰃞", "󰃟", "󰃠"]
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "󰝟 muted",
        "format-icons": {
            "default": ["󰕿", "󰖀", "󰕾"]
        },
        "on-click": "pamixer -t",
        "on-scroll-up": "pamixer -i 5",
        "on-scroll-down": "pamixer -d 5"
    },

    "network": {
        "format-wifi": "󰤨 {essid}",
        "format-ethernet": "󰈀 {ipaddr}",
        "format-disconnected": "󰤭 Offline",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}\n{gwaddr}",
        "interval": 5
    },

    "battery": {
        "states": { "warning": 30, "critical": 15 },
        "format": "{icon} {capacity}%",
        "format-charging": "󰂄 {capacity}%",
        "format-icons": ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]
    },

    "tray": {
        "spacing": 8
    }
}
WBEOF

# 12i. Write Dracula kitty terminal theme
log "Writing Dracula kitty.conf..."
mkdir -p "$HOME/.config/kitty"
cat > "$HOME/.config/kitty/kitty.conf" <<'KITTYEOF'
# ── Dracula Kitty Theme ────────────────────────────────────────────────────────
# https://draculatheme.com/kitty

font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        12.0

# ── Dracula palette ────────────────────────────────────────────────────────────
foreground            #f8f8f2
background            #282a36
selection_foreground  #ffffff
selection_background  #44475a

color0   #21222c
color1   #ff5555
color2   #50fa7b
color3   #f1fa8c
color4   #bd93f9
color5   #ff79c6
color6   #8be9fd
color7   #f8f8f2
color8   #6272a4
color9   #ff6e6e
color10  #69ff94
color11  #ffffa5
color12  #d6acff
color13  #ff92df
color14  #a4ffff
color15  #ffffff

cursor            #f8f8f2
cursor_text_color #282a36

url_color         #8be9fd

active_border_color   #bd93f9
inactive_border_color #44475a
bell_border_color     #ff5555

active_tab_foreground   #282a36
active_tab_background   #bd93f9
inactive_tab_foreground #f8f8f2
inactive_tab_background #44475a

# ── Window ─────────────────────────────────────────────────────────────────────
window_padding_width    8
hide_window_decorations yes
background_opacity      0.95

# ── Cursor ─────────────────────────────────────────────────────────────────────
cursor_shape           block
cursor_blink_interval  0

# ── Shell integration ──────────────────────────────────────────────────────────
shell_integration      enabled
KITTYEOF

# 12j. Write Dracula rofi theme
log "Writing Dracula rofi theme..."
mkdir -p "$HOME/.config/rofi"
cat > "$HOME/.config/rofi/dracula.rasi" <<'ROFIEOF'
/* ── Dracula Rofi Theme ───────────────────────────────────────────────────── */
* {
    bg0:     #282a36;
    bg1:     #44475a;
    fg0:     #f8f8f2;
    fg1:     #6272a4;
    accent:  #bd93f9;
    urgent:  #ff5555;
    green:   #50fa7b;

    background-color: transparent;
    text-color:       @fg0;
    font:             "JetBrainsMono Nerd Font 12";
}

window {
    background-color: @bg0;
    border:           2px solid;
    border-color:     @accent;
    border-radius:    8px;
    width:            480px;
    padding:          12px;
}

mainbox  { background-color: @bg0; }
inputbar { background-color: @bg1; border-radius: 6px; padding: 8px; margin-bottom: 8px; }
prompt   { text-color: @accent; }
entry    { text-color: @fg0; }

listview {
    background-color: @bg0;
    lines:            8;
    spacing:          4px;
}

element {
    background-color: transparent;
    padding:          8px 12px;
    border-radius:    6px;
}

element selected {
    background-color: @accent;
    text-color:       @bg0;
}

element-icon  { size: 20px; margin-right: 8px; }
element-text  { vertical-align: 0.5; }

scrollbar { handle-color: @accent; background-color: @bg1; }
ROFIEOF

# Write rofi config.rasi to use Dracula theme by default
cat > "$HOME/.config/rofi/config.rasi" <<'ROFICONF'
configuration {
    modi:                "drun,run,window";
    show-icons:          true;
    icon-theme:          "Papirus-Dark";
    display-drun:        "  Apps";
    display-run:         "  Run";
    display-window:      "  Windows";
    drun-display-format: "{name}";
    hover-select:        true;
}

@theme "/home/PLACEHOLDER/.config/rofi/dracula.rasi"
ROFICONF
# Replace PLACEHOLDER with actual username
sed -i "s|PLACEHOLDER|$USER|g" "$HOME/.config/rofi/config.rasi"

# 12k. Write Dracula mako notification config
log "Writing Dracula mako config..."
mkdir -p "$HOME/.config/mako"
cat > "$HOME/.config/mako/config" <<'MAKOEOF'
# ── Dracula Mako Notification Theme ───────────────────────────────────────────
font=JetBrainsMono Nerd Font 11
background-color=#282a36ee
text-color=#f8f8f2
border-color=#bd93f9
border-size=2
border-radius=8
width=360
height=120
padding=12
margin=8
default-timeout=5000
ignore-timeout=0

[urgency=low]
background-color=#282a36ee
border-color=#6272a4

[urgency=normal]
background-color=#282a36ee
border-color=#bd93f9

[urgency=high]
background-color=#44475aee
border-color=#ff5555
text-color=#ff5555
MAKOEOF

log "All Dracula theme configs written."

# ── 13. Hyprland config ──────────────────────────────────────────────────────
header "Step 13 — Writing Hyprland Config"

HYPR_DIR="$HOME/.config/hypr"
mkdir -p "$HYPR_DIR"

# ── nvidia-env.conf ──────────────────────────────────────────────────────────
ENV_FILE="$HYPR_DIR/nvidia-env.conf"
log "Writing $ENV_FILE..."
cat > "$ENV_FILE" <<'ENVEOF'
# ─── NVIDIA Wayland Environment Variables ─────────────────────────────────────
# Source: https://wiki.hyprland.org/Nvidia/

env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = NVD_BACKEND,direct

# Hardware cursors — change to 0 if cursor is invisible after login
env = WLR_NO_HARDWARE_CURSORS,1

# Force native Wayland for all major toolkits
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = XDG_CURRENT_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland
env = MOZ_ENABLE_WAYLAND,1
env = ELECTRON_OZONE_PLATFORM_HINT,wayland

# Qt theming — tell Qt5/Qt6 apps to use qt5ct/qt6ct for styling
env = QT_QPA_PLATFORMTHEME,qt5ct
ENVEOF

# ── hyprland.conf ─────────────────────────────────────────────────────────────
HYPR_CONF="$HYPR_DIR/hyprland.conf"

if [[ -f "$HYPR_CONF" ]]; then
    warn "Existing hyprland.conf found — backing up to hyprland.conf.bak"
    cp "$HYPR_CONF" "${HYPR_CONF}.bak"
    if ! grep -q "nvidia-env.conf" "$HYPR_CONF"; then
        log "Prepending nvidia-env source to existing config..."
        { echo "source = $HYPR_DIR/nvidia-env.conf"; echo ""; cat "$HYPR_CONF"; } \
            > "${HYPR_CONF}.tmp" && mv "${HYPR_CONF}.tmp" "$HYPR_CONF"
    fi
else
    log "Creating $HYPR_CONF..."
    cat > "$HYPR_CONF" <<CONFEOF
# ─── Hyprland Config — Generated by install-hyprland-nvidia.sh ───────────────
# Theme: Dracula | Docs: https://wiki.hyprland.org/Configuring/

source = $HYPR_DIR/nvidia-env.conf

# ── Monitor ───────────────────────────────────────────────────────────────────
# Auto-detect. Edit for multi-monitor: monitor = DP-1, 2560x1440@165, 0x0, 1
monitor = ,preferred,auto,1

# ── Default apps ──────────────────────────────────────────────────────────────
\$terminal    = kitty
\$launcher    = rofi -show drun
\$filemanager = thunar

# ── Autostart ─────────────────────────────────────────────────────────────────
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = waybar
exec-once = mako
exec-once = swww-daemon
exec-once = nm-applet --indicator
exec-once = wl-paste --watch cliphist store
# Apply GTK theme on each login (ensures Dracula stays applied)
exec-once = gsettings set org.gnome.desktop.interface gtk-theme 'Dracula'
exec-once = gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
exec-once = gsettings set org.gnome.desktop.interface cursor-theme 'Dracula-cursors'
exec-once = gsettings set org.gnome.desktop.interface cursor-size 24
exec-once = gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'
exec-once = gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# ── Input ─────────────────────────────────────────────────────────────────────
input {
    kb_layout    = us
    follow_mouse = 1
    sensitivity  = 0

    touchpad {
        natural_scroll       = true
        disable_while_typing = true
        tap-to-click         = true
    }
}

# ── General — Dracula border colors ───────────────────────────────────────────
general {
    gaps_in    = 5
    gaps_out   = 10
    border_size = 2
    layout     = dwindle

    col.active_border   = rgba(bd93f9ff) rgba(ff79c6ff) 45deg
    col.inactive_border = rgba(44475aaa)
}

# ── Decoration ────────────────────────────────────────────────────────────────
decoration {
    rounding = 8

    # Dracula-style shadow (purple tint)
    shadow {
        enabled        = true
        range          = 12
        render_power   = 3
        color          = rgba(bd93f9cc)
        color_inactive = rgba(00000066)
    }

    blur {
        enabled = true
        size    = 5
        passes  = 2
    }
}

# ── Animations ────────────────────────────────────────────────────────────────
animations {
    enabled = true
    bezier  = dracula, 0.05, 0.9, 0.1, 1.05
    bezier  = linear,  0.0,  0.0, 1.0, 1.0

    animation = windows,     1, 5, dracula
    animation = windowsOut,  1, 4, default, popin 80%
    animation = border,      1, 5, default
    animation = borderangle, 1, 8, linear, loop
    animation = fade,        1, 4, default
    animation = workspaces,  1, 5, dracula
}

# ── Layout ────────────────────────────────────────────────────────────────────
dwindle {
    pseudotile     = true
    preserve_split = true
}

# ── Misc ──────────────────────────────────────────────────────────────────────
misc {
    disable_hyprland_logo    = true
    disable_splash_rendering = true
    mouse_move_enables_dpms  = true
}

# ══════════════════════════════════════════════════════════════════════════════
#  KEYBINDS  (\$mod = SUPER / Windows key)
# ══════════════════════════════════════════════════════════════════════════════
\$mod = SUPER

# Apps
bind = \$mod,       Return, exec, \$terminal
bind = \$mod,       D,      exec, \$launcher
bind = \$mod,       E,      exec, \$filemanager

# Window management
bind = \$mod,       Q,     killactive
bind = \$mod,       M,     exit
bind = \$mod,       F,     fullscreen
bind = \$mod SHIFT, Space, togglefloating
bind = \$mod,       P,     pseudo

# Focus (vim-style)
bind = \$mod, H, movefocus, l
bind = \$mod, L, movefocus, r
bind = \$mod, K, movefocus, u
bind = \$mod, J, movefocus, d

# Move windows
bind = \$mod SHIFT, H, movewindow, l
bind = \$mod SHIFT, L, movewindow, r
bind = \$mod SHIFT, K, movewindow, u
bind = \$mod SHIFT, J, movewindow, d

# Resize windows
binde = \$mod ALT, H, resizeactive, -30 0
binde = \$mod ALT, L, resizeactive,  30 0
binde = \$mod ALT, K, resizeactive,  0 -30
binde = \$mod ALT, J, resizeactive,  0  30

# Workspaces 1–9
bind = \$mod,       1, workspace, 1
bind = \$mod,       2, workspace, 2
bind = \$mod,       3, workspace, 3
bind = \$mod,       4, workspace, 4
bind = \$mod,       5, workspace, 5
bind = \$mod,       6, workspace, 6
bind = \$mod,       7, workspace, 7
bind = \$mod,       8, workspace, 8
bind = \$mod,       9, workspace, 9
bind = \$mod SHIFT, 1, movetoworkspace, 1
bind = \$mod SHIFT, 2, movetoworkspace, 2
bind = \$mod SHIFT, 3, movetoworkspace, 3
bind = \$mod SHIFT, 4, movetoworkspace, 4
bind = \$mod SHIFT, 5, movetoworkspace, 5
bind = \$mod SHIFT, 6, movetoworkspace, 6
bind = \$mod SHIFT, 7, movetoworkspace, 7
bind = \$mod SHIFT, 8, movetoworkspace, 8
bind = \$mod SHIFT, 9, movetoworkspace, 9

# Scratchpad
bind = \$mod,       S, togglespecialworkspace, magic
bind = \$mod SHIFT, S, movetoworkspace,        special:magic

# Mouse window management
bindm = \$mod, mouse:272, movewindow
bindm = \$mod, mouse:273, resizewindow

# Volume (ASUS ROG media keys)
bindel = , XF86AudioRaiseVolume, exec, pamixer -i 5
bindel = , XF86AudioLowerVolume, exec, pamixer -d 5
bindl  = , XF86AudioMute,        exec, pamixer -t
bindl  = , XF86AudioMicMute,     exec, pamixer --default-source -t

# Brightness (ASUS ROG backlight keys)
bindel = , XF86MonBrightnessUp,   exec, brightnessctl set +5%
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Screenshots — saved to ~/Pictures/Screenshots/
bind = ,      Print, exec, grim "\$HOME/Pictures/Screenshots/\$(date +%Y%m%d-%H%M%S).png"
bind = SHIFT, Print, exec, grim -g "\$(slurp)" "\$HOME/Pictures/Screenshots/\$(date +%Y%m%d-%H%M%S).png"

# Clipboard history picker
bind = \$mod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
CONFEOF
fi

mkdir -p "$HOME/Pictures/Screenshots"
log "Screenshots folder: ~/Pictures/Screenshots"

# ── 14. Wallpaper Bank (optional) ────────────────────────────────────────────
header "Step 14 — Wallpaper Bank (Optional)"
echo ""
echo -e "  ${CYAN}JaKooLit's Wallpaper-Bank${NC} is a curated collection of high-quality"
echo    "  wallpapers used in the reference Hyprland dotfiles."
echo    "  Repo: https://github.com/JaKooLit/Wallpaper-Bank"
echo ""
warn   "  ⚠  This repo is approximately 1 GB. Make sure you have enough"
warn   "     disk space and a stable internet connection before proceeding."
echo ""
read -rp "  Download Wallpaper-Bank to ~/Pictures/Wallpapers? [y/N]: " wp_choice

if [[ "${wp_choice:-N}" =~ ^[Yy]$ ]]; then
    WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

    if [[ -d "$WALLPAPER_DIR/.git" ]]; then
        # Repo already exists — pull latest instead of re-cloning
        warn "Wallpaper-Bank already present at $WALLPAPER_DIR — pulling latest..."
        git -C "$WALLPAPER_DIR" pull --ff-only || {
            warn "git pull failed — your local copy may have local changes. Skipping."
        }
    else
        mkdir -p "$HOME/Pictures"
        log "Cloning Wallpaper-Bank into $WALLPAPER_DIR (~1 GB, please wait)..."
        git clone --depth=1 \
            https://github.com/JaKooLit/Wallpaper-Bank.git \
            "$WALLPAPER_DIR" || {
            warn "Wallpaper download failed. You can clone it manually later:"
            warn "  git clone --depth=1 https://github.com/JaKooLit/Wallpaper-Bank.git ~/Pictures/Wallpapers"
        }
    fi

    # If download succeeded, set a random wallpaper from the collection as default
    if [[ -d "$WALLPAPER_DIR" ]]; then
        # Pick a random image to use as the initial wallpaper in hyprland.conf
        RANDOM_WP=$(find "$WALLPAPER_DIR" -type f \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
            | shuf -n 1)

        if [[ -n "$RANDOM_WP" ]]; then
            log "Setting random wallpaper as default: $(basename "$RANDOM_WP")"
            # Replace the swww-daemon exec-once line to also set the wallpaper on start
            HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
            # Only inject if the line is still the bare daemon start (not already modified)
            if grep -q "^exec-once = swww-daemon$" "$HYPR_CONF" 2>/dev/null; then
                sed -i "s|^exec-once = swww-daemon$|exec-once = swww-daemon \&\& sleep 1 \&\& swww img \"$RANDOM_WP\" --transition-type fade|" \
                    "$HYPR_CONF"
                log "Default wallpaper injected into hyprland.conf autostart."
            else
                log "swww-daemon line already modified — skipping wallpaper injection."
            fi
        fi

        log "Wallpaper-Bank downloaded to: $WALLPAPER_DIR"
        echo ""
        echo -e "  ${CYAN}To change wallpaper after login:${NC}"
        echo    "    swww img ~/Pictures/Wallpapers/<filename> --transition-type fade"
    fi
else
    log "Wallpaper-Bank skipped."
    echo ""
    echo -e "  ${CYAN}You can download it later with:${NC}"
    echo    "    git clone --depth=1 https://github.com/JaKooLit/Wallpaper-Bank.git ~/Pictures/Wallpapers"
    echo    "  Then set a wallpaper with:"
    echo    "    swww img ~/Pictures/Wallpapers/<file> --transition-type fade"
fi

# ── 15. XDG user dirs ────────────────────────────────────────────────────────
header "Step 15 — XDG User Directories"
xdg-user-dirs-update

# ── Done ─────────────────────────────────────────────────────────────────────
header "Installation Complete"
echo ""
echo -e "  ${GREEN}All steps completed.${NC}"
echo ""
echo -e "  ${CYAN}Log:${NC}              $LOGFILE"
echo -e "  ${CYAN}Hyprland config:${NC}  $HYPR_DIR/hyprland.conf"
echo -e "  ${CYAN}NVIDIA env:${NC}       $HYPR_DIR/nvidia-env.conf"
echo ""
echo -e "  ${CYAN}Dracula configs written:${NC}"
echo "    ~/.config/waybar/config.jsonc   (bar layout)"
echo "    ~/.config/waybar/style.css      (Dracula colors)"
echo "    ~/.config/kitty/kitty.conf      (terminal theme)"
echo "    ~/.config/rofi/dracula.rasi     (launcher theme)"
echo "    ~/.config/mako/config           (notification theme)"
echo "    ~/.config/gtk-3.0/settings.ini  (GTK3)"
echo "    ~/.config/gtk-4.0/settings.ini  (GTK4)"
echo "    /etc/sddm.conf.d/theme.conf     (login screen)"
echo ""
echo -e "  ${YELLOW}══ Post-install checklist ══${NC}"
echo ""
echo "  1. REBOOT — NVIDIA DRM must load before Hyprland starts."
echo "       sudo reboot"
echo ""
echo "  2. After reboot, verify DRM modeset:"
echo "       cat /sys/module/nvidia_drm/parameters/modeset  →  must return Y"
echo ""
echo "  3. SDDM black screen fix:"
echo "       Ctrl+Alt+F2 → login → run:"
echo "         lspci -nn | grep -i nvidia"
echo "         ls -l /dev/dri/by-path"
echo "       Add to ~/.config/hypr/nvidia-env.conf:"
echo "         env = WLR_DRM_DEVICES,/dev/dri/card1  (adjust X)"
echo ""
echo "  4. Set a Dracula wallpaper (dark purple recommended):"
echo "       swww img ~/Pictures/Wallpapers/<file> --transition-type fade"
echo "       Full collection: https://github.com/JaKooLit/Wallpaper-Bank"
echo ""
echo "  5. Optional — ROG fan/RGB control:"
echo "       yay -S asusctl supergfxctl"
echo "       sudo systemctl enable --now asusd"
echo ""
echo "  6. If GBM_BACKEND=nvidia-drm causes crashes, comment it out in:"
echo "       ~/.config/hypr/nvidia-env.conf"
echo ""
warn "Reboot required →  sudo reboot"
echo ""
echo "=== Install finished: $(date) ==="
