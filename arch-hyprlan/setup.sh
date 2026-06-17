#!/usr/bin/env bash
#
# setup-hyprland.sh — Hyprland desktop for Arch Linux (Dell laptop), Dracula theme.
# Installs ONLY the desktop environment. No security tooling — add your own later.
# Config is split into modular files under ~/.config/hypr/ and sourced by hyprland.conf.
#
# Run as your normal user (NOT root). Requires a working Arch base + internet.
# Usage:  chmod +x setup-hyprland.sh && ./setup-hyprland.sh
#
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "[!] Do NOT run as root. Run as your user; sudo is invoked where needed."
  exit 1
fi
command -v pacman >/dev/null || { echo "[!] Not an Arch system."; exit 1; }

log() { printf '\n\033[1;35m[*] %s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------
# 1. System update + graphics (Intel/AMD auto-detect)
# ---------------------------------------------------------------------------
log "Updating system"
sudo pacman -Syu --noconfirm

log "Installing graphics + Wayland base"
GPU_PKGS="mesa vulkan-icd-loader libva-utils"
if lspci | grep -qiE 'vga.*intel'; then
  GPU_PKGS+=" vulkan-intel intel-media-driver"
elif lspci | grep -qiE 'vga.*amd|vga.*ati'; then
  GPU_PKGS+=" vulkan-radeon libva-mesa-driver"
fi
# shellcheck disable=SC2086
sudo pacman -S --needed --noconfirm $GPU_PKGS

# ---------------------------------------------------------------------------
# 2. Hyprland + desktop components
# ---------------------------------------------------------------------------
log "Installing Hyprland and core desktop stack"
sudo pacman -S --needed --noconfirm \
  hyprland xdg-desktop-portal-hyprland \
  waybar rofi-wayland mako kitty \
  hyprpaper hyprlock hypridle \
  grim slurp wl-clipboard cliphist \
  brightnessctl playerctl pamixer pavucontrol \
  network-manager-applet blueman \
  thunar thunar-archive-plugin gvfs file-roller \
  polkit-gnome qt5-wayland qt6-wayland \
  pipewire pipewire-pulse pipewire-alsa wireplumber \
  ttf-jetbrains-mono-nerd ttf-font-awesome noto-fonts noto-fonts-emoji \
  papirus-icon-theme imagemagick

log "Enabling services"
sudo systemctl enable bluetooth.service NetworkManager.service

# ---------------------------------------------------------------------------
# 3. AUR helper (paru) for theming
# ---------------------------------------------------------------------------
if ! command -v paru >/dev/null; then
  log "Installing paru (AUR helper)"
  sudo pacman -S --needed --noconfirm base-devel git
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru.git "$tmp/paru"
  ( cd "$tmp/paru" && makepkg -si --noconfirm )
  rm -rf "$tmp"
fi

log "Installing theming (Dracula stack)"
paru -S --needed --noconfirm \
  dracula-gtk-theme dracula-icons-git \
  qt5ct qt6ct kvantum kvantum-theme-dracula-git \
  wlogout || echo "[*] Some AUR theme pkgs may need manual review."

# ---------------------------------------------------------------------------
# 4. Modular Hyprland config under ~/.config/hypr/
# ---------------------------------------------------------------------------
log "Writing modular config files"
CFG="$HOME/.config"
HYPR="$CFG/hypr"
mkdir -p "$HYPR/conf" "$CFG/waybar" "$CFG/rofi" "$CFG/kitty" "$CFG/mako" "$CFG/gtk-3.0"

# ---- main entry: sources the rest ----
cat > "$HYPR/hyprland.conf" <<'EOF'
# ~/.config/hypr/hyprland.conf
# Main entry point. Each concern lives in its own file under conf/.
# Edit those files; this one only wires them together.

source = ~/.config/hypr/conf/env.conf
source = ~/.config/hypr/conf/monitors.conf
source = ~/.config/hypr/conf/input.conf
source = ~/.config/hypr/conf/looknfeel.conf
source = ~/.config/hypr/conf/animations.conf
source = ~/.config/hypr/conf/autostart.conf
source = ~/.config/hypr/conf/workspaces.conf
source = ~/.config/hypr/conf/keybinds.conf
source = ~/.config/hypr/conf/windowrules.conf
EOF

# ---- env.conf ----
cat > "$HYPR/conf/env.conf" <<'EOF'
# Environment variables
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_QPA_PLATFORM,wayland;xcb
env = GDK_BACKEND,wayland,x11
env = MOZ_ENABLE_WAYLAND,1
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
EOF

# ---- monitors.conf ----
cat > "$HYPR/conf/monitors.conf" <<'EOF'
# Monitor layout. `hyprctl monitors` lists connected outputs.
# Format: monitor = name, resolution@hz, position, scale
monitor = , preferred, auto, 1

# Example external display:
# monitor = HDMI-A-1, 1920x1080@60, 1920x0, 1
EOF

# ---- input.conf ----
cat > "$HYPR/conf/input.conf" <<'EOF'
input {
  kb_layout = us
  follow_mouse = 1
  sensitivity = 0
  touchpad {
    natural_scroll = true
    tap-to-click = true
    disable_while_typing = true
    clickfinger_behavior = true
  }
}

gestures {
  workspace_swipe = true
  workspace_swipe_fingers = 3
}
EOF

# ---- looknfeel.conf ----
cat > "$HYPR/conf/looknfeel.conf" <<'EOF'
# Dracula palette: bg #282a36, purple #bd93f9, pink #ff79c6, comment #6272a4
general {
  gaps_in = 5
  gaps_out = 10
  border_size = 2
  col.active_border = rgba(bd93f9ee) rgba(ff79c6ee) 45deg
  col.inactive_border = rgba(44475aaa)
  layout = dwindle
  resize_on_border = true
}

decoration {
  rounding = 10
  active_opacity = 1.0
  inactive_opacity = 0.94
  blur {
    enabled = true
    size = 6
    passes = 3
    new_optimizations = true
  }
  shadow {
    enabled = true
    range = 16
    render_power = 3
    color = rgba(1a1a2eee)
  }
}

dwindle {
  pseudotile = true
  preserve_split = true
}

misc {
  disable_hyprland_logo = true
  disable_splash_rendering = true
  vfr = true
}
EOF

# ---- animations.conf ----
cat > "$HYPR/conf/animations.conf" <<'EOF'
animations {
  enabled = true
  bezier = ease, 0.25, 0.1, 0.25, 1.0
  bezier = overshoot, 0.05, 0.9, 0.1, 1.05
  animation = windows, 1, 5, overshoot
  animation = windowsOut, 1, 5, ease, popin 80%
  animation = fade, 1, 6, ease
  animation = border, 1, 8, ease
  animation = workspaces, 1, 5, ease, slide
}
EOF

# ---- autostart.conf ----
cat > "$HYPR/conf/autostart.conf" <<'EOF'
exec-once = waybar
exec-once = mako
exec-once = hyprpaper
exec-once = hypridle
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = wl-paste --watch cliphist store
EOF

# ---- workspaces.conf ----
cat > "$HYPR/conf/workspaces.conf" <<'EOF'
# Persistent named workspaces. Bound to keys in keybinds.conf (SUPER+F1..F5).
# Rename freely — these are just suggestions for organizing your work.
workspace = name:RECON,   monitor:, default:true
workspace = name:EXPLOIT, monitor:
workspace = name:C2,      monitor:
workspace = name:SOC,     monitor:
workspace = name:DFIR,    monitor:
EOF

# ---- keybinds.conf ----
cat > "$HYPR/conf/keybinds.conf" <<'EOF'
$mod = SUPER

# Apps
bind = $mod, Return, exec, kitty
bind = $mod, E, exec, thunar
bind = $mod, B, exec, firefox
bind = $mod, R, exec, rofi -show drun
bind = $mod, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy

# Window management
bind = $mod, Q, killactive,
bind = $mod, V, togglefloating,
bind = $mod, F, fullscreen,
bind = $mod, P, pseudo,
bind = $mod, J, togglesplit,
bind = $mod SHIFT, M, exit,

# Lock / power
bind = $mod, L, exec, hyprlock
bind = $mod SHIFT, E, exec, wlogout

# Focus
bind = $mod, left,  movefocus, l
bind = $mod, right, movefocus, r
bind = $mod, up,    movefocus, u
bind = $mod, down,  movefocus, d

# Move windows
bind = $mod SHIFT, left,  movewindow, l
bind = $mod SHIFT, right, movewindow, r
bind = $mod SHIFT, up,    movewindow, u
bind = $mod SHIFT, down,  movewindow, d

# Numeric workspaces
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5

# Named workspaces
bind = $mod, F1, workspace, name:RECON
bind = $mod, F2, workspace, name:EXPLOIT
bind = $mod, F3, workspace, name:C2
bind = $mod, F4, workspace, name:SOC
bind = $mod, F5, workspace, name:DFIR

# Screenshots
bind = , Print,       exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print,  exec, grim - | wl-copy

# Laptop keys
binde = , XF86MonBrightnessUp,   exec, brightnessctl set 5%+
binde = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
binde = , XF86AudioRaiseVolume,  exec, pamixer -i 5
binde = , XF86AudioLowerVolume,  exec, pamixer -d 5
bind  = , XF86AudioMute,         exec, pamixer -t
bind  = , XF86AudioPlay,         exec, playerctl play-pause
bind  = , XF86AudioNext,         exec, playerctl next
bind  = , XF86AudioPrev,         exec, playerctl previous

# Mouse drag
bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow
EOF

# ---- windowrules.conf ----
cat > "$HYPR/conf/windowrules.conf" <<'EOF'
# Float common dialogs / pickers
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(blueman-manager)$
windowrulev2 = float, class:^(nm-connection-editor)$
windowrulev2 = float, title:^(Open File)$
windowrulev2 = float, title:^(Save File)$
windowrulev2 = float, class:^(thunar)$, title:^(File Operation Progress)$

# Picture-in-picture always floating + pinned
windowrulev2 = float, title:^(Picture-in-Picture)$
windowrulev2 = pin,   title:^(Picture-in-Picture)$
EOF

# ---- hyprpaper.conf (lives at hypr root, not sourced by hyprland.conf) ----
cat > "$HYPR/hyprpaper.conf" <<'EOF'
preload = ~/.config/hypr/wall.png
wallpaper = ,~/.config/hypr/wall.png
splash = false
EOF

# Generate a Dracula gradient wallpaper
if command -v magick >/dev/null 2>&1; then
  magick -size 1920x1080 gradient:'#282a36'-'#1a1a2e' "$HYPR/wall.png" || true
elif command -v convert >/dev/null 2>&1; then
  convert -size 1920x1080 gradient:'#282a36'-'#1a1a2e' "$HYPR/wall.png" || true
fi

# ---- hypridle.conf ----
cat > "$HYPR/hypridle.conf" <<'EOF'
general {
  lock_cmd = pidof hyprlock || hyprlock
  before_sleep_cmd = loginctl lock-session
  after_sleep_cmd = hyprctl dispatch dpms on
}
listener {
  timeout = 300
  on-timeout = brightnessctl -s set 10%
  on-resume = brightnessctl -r
}
listener {
  timeout = 600
  on-timeout = loginctl lock-session
}
listener {
  timeout = 900
  on-timeout = systemctl suspend
}
EOF

# ---- hyprlock.conf ----
cat > "$HYPR/hyprlock.conf" <<'EOF'
background {
  monitor =
  path = ~/.config/hypr/wall.png
  blur_passes = 3
}
input-field {
  monitor =
  size = 250, 50
  outline_thickness = 2
  dots_size = 0.25
  outer_color = rgb(bd93f9)
  inner_color = rgb(282a36)
  font_color = rgb(f8f8f2)
  placeholder_text = <i>Authenticate</i>
  position = 0, -20
  halign = center
  valign = center
}
label {
  monitor =
  text = cmd[update:1000] echo "$(date +'%H:%M')"
  color = rgb(f8f8f2)
  font_size = 64
  position = 0, 120
  halign = center
  valign = center
}
EOF

# ---------------------------------------------------------------------------
# 5. Companion app configs (Waybar, Kitty, Mako, Rofi, GTK)
# ---------------------------------------------------------------------------
cat > "$CFG/waybar/config.jsonc" <<'EOF'
{
  "layer": "top",
  "position": "top",
  "height": 32,
  "spacing": 6,
  "modules-left": ["hyprland/workspaces", "hyprland/window"],
  "modules-center": ["clock"],
  "modules-right": ["network", "pulseaudio", "backlight", "battery", "tray"],
  "hyprland/workspaces": { "format": "{name}", "on-click": "activate" },
  "clock": {
    "format": "  {:%a %d %b  %H:%M}",
    "tooltip-format": "<tt>{calendar}</tt>"
  },
  "network": {
    "format-wifi": "  {essid} ({signalStrength}%)",
    "format-ethernet": "  {ipaddr}",
    "format-disconnected": "  off",
    "tooltip-format": "{ifname}: {ipaddr}"
  },
  "pulseaudio": {
    "format": "{icon}  {volume}%",
    "format-muted": "  muted",
    "format-icons": { "default": ["", "", ""] },
    "on-click": "pavucontrol"
  },
  "backlight": { "format": "  {percent}%" },
  "battery": {
    "states": { "warning": 30, "critical": 15 },
    "format": "{icon}  {capacity}%",
    "format-charging": "  {capacity}%",
    "format-icons": ["", "", "", "", ""]
  },
  "tray": { "spacing": 8 }
}
EOF

cat > "$CFG/waybar/style.css" <<'EOF'
* {
  font-family: "JetBrainsMono Nerd Font";
  font-size: 13px;
  border: none;
  border-radius: 0;
}
window#waybar { background: rgba(40, 42, 54, 0.85); color: #f8f8f2; }
#workspaces button { padding: 0 8px; color: #6272a4; background: transparent; }
#workspaces button.active { color: #282a36; background: #bd93f9; border-radius: 6px; }
#workspaces button.urgent { color: #ff5555; }
#clock { color: #8be9fd; font-weight: bold; }
#network, #pulseaudio, #backlight, #battery, #tray { padding: 0 10px; }
#battery.critical { color: #ff5555; }
#battery.warning { color: #ffb86c; }
EOF

cat > "$CFG/kitty/kitty.conf" <<'EOF'
font_family      JetBrainsMono Nerd Font
font_size        11.5
background_opacity 0.92
window_padding_width 8
cursor_shape     beam
scrollback_lines 20000
enable_audio_bell no

foreground            #f8f8f2
background            #282a36
selection_foreground  #ffffff
selection_background  #44475a
color0  #21222c
color1  #ff5555
color2  #50fa7b
color3  #f1fa8c
color4  #bd93f9
color5  #ff79c6
color6  #8be9fd
color7  #f8f8f2
color8  #6272a4
color9  #ff6e6e
color10 #69ff94
color11 #ffffa5
color12 #d6acff
color13 #ff92df
color14 #a4ffff
color15 #ffffff
EOF

cat > "$CFG/mako/config" <<'EOF'
font=JetBrainsMono Nerd Font 11
background-color=#282a36
text-color=#f8f8f2
border-color=#bd93f9
border-size=2
border-radius=8
default-timeout=6000
padding=12
margin=8
[urgency=critical]
border-color=#ff5555
EOF

cat > "$CFG/rofi/config.rasi" <<'EOF'
configuration {
  modi: "drun,run,window";
  show-icons: true;
  icon-theme: "Papirus-Dark";
  font: "JetBrainsMono Nerd Font 12";
}
* {
  bg:     #282a36;
  bg-alt: #44475a;
  fg:     #f8f8f2;
  accent: #bd93f9;
}
window { background-color: @bg; border-radius: 10px; width: 600px; }
mainbox { padding: 12px; }
inputbar { background-color: @bg-alt; border-radius: 8px; padding: 8px; text-color: @fg; }
listview { lines: 8; }
element { padding: 8px; border-radius: 6px; }
element selected { background-color: @accent; text-color: @bg; }
element-text, element-icon { background-color: inherit; text-color: inherit; }
EOF

cat > "$CFG/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Dracula
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
EOF

# ---------------------------------------------------------------------------
# 6. Done
# ---------------------------------------------------------------------------
log "Setup complete"
cat <<'DONE'

  Config layout (~/.config/hypr/):
    hyprland.conf        -> entry point, sources everything in conf/
    conf/env.conf        -> environment variables
    conf/monitors.conf   -> display layout
    conf/input.conf      -> keyboard + touchpad
    conf/looknfeel.conf  -> gaps, borders, blur, shadow (Dracula)
    conf/animations.conf -> animation curves
    conf/autostart.conf  -> exec-once programs
    conf/workspaces.conf -> named workspaces
    conf/keybinds.conf   -> all keybindings
    conf/windowrules.conf-> float/pin rules
    hyprpaper.conf / hypridle.conf / hyprlock.conf

  Next steps:
    1. Qt theme: run `qt6ct` -> set "kvantum", then `kvantummanager` -> Dracula.
    2. Log out, then from a TTY:  Hyprland
    3. Keys: SUPER+Return terminal, SUPER+R launcher, SUPER+F1..F5 workspaces,
       SUPER+L lock, Print = region screenshot.

  No security tools were installed — add whatever you want with pacman/paru.
DONE
