#
<div align="center">

# 🐉 Hyprland + Dracula — Arch Linux Installer
### NVIDIA · ASUS ROG Strix · Minimal · Fully Themed

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=hyprland&logoColor=black)
![NVIDIA](https://img.shields.io/badge/NVIDIA-76B900?style=for-the-badge&logo=nvidia&logoColor=white)
![Dracula](https://img.shields.io/badge/Dracula_Theme-282A36?style=for-the-badge&logo=dracula&logoColor=BD93F9)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)

A single-script, fully automated installer for **Hyprland** on Arch Linux,
purpose-built for **NVIDIA GPUs** and **ASUS ROG Strix** laptops.
Ships with a complete **Dracula** theme stack out of the box.

</div>

---

## ✨ Features

- **NVIDIA-first** — DRM modeset, early KMS, nouveau blacklist, VA-API, and a pacman hook that auto-rebuilds initramfs on every kernel or driver update
- **Driver choice** — prompts between `nvidia-dkms` (GTX 900+) and `nvidia-open-dkms` (RTX 20xx+ open kernel module)
- **Auto kernel detection** — detects `linux`, `linux-lts`, `linux-zen`, `linux-hardened` and installs the correct headers
- **Minimal by design** — only installs what is strictly required for the system to function
- **Full Dracula theme stack** — GTK3/4, icons, cursor, SDDM login screen, Waybar, Kitty, Rofi, Mako notifications, Qt5/Qt6 via Kvantum
- **Idempotent** — safe to run more than once; every step checks before modifying
- **Full log** — every line of output is written to `~/hyprland-install.log`
- **Wallpaper Bank** — optional 1 GB wallpaper collection from [JaKooLit/Wallpaper-Bank](https://github.com/JaKooLit/Wallpaper-Bank), randomly sets a default wallpaper on first login

---

## 📋 Requirements

| Requirement | Details |
|-------------|---------|
| OS | Arch Linux (minimal/server install) |
| GPU | NVIDIA GTX 900 series or newer |
| Hardware | Tested on ASUS ROG Strix (works on any NVIDIA laptop/desktop) |
| Kernel | `linux`, `linux-lts`, `linux-zen`, or `linux-hardened` |
| Network | Active internet connection required |
| User | Regular user with `sudo` access — **do not run as root** |
| Disk space | ~3 GB base · ~4 GB with Wallpaper Bank |

> **Recommended:** Create a system snapshot with `timeshift` or `snapper` before running.

---

## 🚀 Installation

```bash
# Clone the repo
git clone https://github.com/RootedN00b/hyprland-nvidia-installer.git
cd hyprland-nvidia-installer

# Make executable and run
chmod +x install-hyprland-nvidia.sh
./install-hyprland-nvidia.sh
```

The script will prompt you for two choices before anything is installed:

1. **Continue?** — confirm you want to proceed
2. **NVIDIA driver** — choose proprietary (`nvidia-dkms`) or open kernel module (`nvidia-open-dkms`)
3. **Wallpaper Bank** — optionally download ~1 GB wallpaper collection at the end

When the script completes, reboot:

```bash
sudo reboot
```

---

## 📦 What Gets Installed

### NVIDIA Stack
| Package | Purpose |
|---------|---------|
| `nvidia-dkms` / `nvidia-open-dkms` | Kernel driver (your choice) |
| `nvidia-utils` | Userspace utilities |
| `nvidia-settings` | GPU configuration GUI |
| `egl-wayland` | EGL/Wayland compatibility layer |
| `libva-nvidia-driver` | Hardware video decode on Wayland |

### Hyprland Core
| Package | Purpose |
|---------|---------|
| `hyprland` | Wayland compositor |
| `xorg-xwayland` | X11 app compatibility |
| `xdg-desktop-portal-hyprland` | Screenshare & file portals |
| `qt5-wayland` / `qt6-wayland` | Native Qt Wayland rendering |
| `polkit-kde-agent` | Authentication agent |

### Audio
| Package | Purpose |
|---------|---------|
| `pipewire` | Audio server + screen capture |
| `pipewire-pulse` | PulseAudio drop-in |
| `wireplumber` | Session manager |
| `pipewire-alsa` | ALSA routing |
| `pipewire-jack` | JACK routing |

### Session Tools
| Package | Purpose |
|---------|---------|
| `waybar` | Status bar |
| `kitty` | Terminal emulator |
| `rofi-wayland` | App launcher |
| `swww` | Wallpaper daemon |
| `mako` | Notification daemon |
| `grim` + `slurp` | Screenshot tools |
| `brightnessctl` | Backlight control |
| `pamixer` | Volume control |
| `wl-clipboard` + `cliphist` | Clipboard + history |
| `thunar` | File manager |
| `networkmanager` + applet | Network management |
| `sddm` | Display/login manager |

### Dracula Theme (AUR)
| Package | Purpose |
|---------|---------|
| `dracula-gtk-theme` | GTK 3/4 window theme |
| `dracula-cursors-git` | Cursor set |
| `sddm-theme-dracula` | Login screen |
| `papirus-icon-theme` + `papirus-folders` | Icons with Dracula purple folders |
| `kvantum` + `qt5ct` + `qt6ct` | Qt app theming |

---

## 🎨 Dracula Theme Coverage

Every visible surface is themed at install time — nothing left unstyled.

| Surface | Theme applied |
|---------|--------------|
| GTK3 apps | Dracula via `~/.config/gtk-3.0/settings.ini` |
| GTK4 apps | Dracula via `~/.config/gtk-4.0/settings.ini` |
| Qt5/Qt6 apps | Kvantum dark via `qt5ct` / `qt6ct` |
| SDDM login screen | `sddm-theme-dracula` |
| Waybar | Full Dracula CSS with per-module accent colors |
| Kitty terminal | Complete 16-color Dracula palette |
| Rofi launcher | Dracula `.rasi` theme |
| Mako notifications | Dracula colors with urgency levels |
| Window borders | Purple → Pink gradient (`#bd93f9` → `#ff79c6`) |
| Folder icons | Papirus-Dark with violet (Dracula purple) folders |
| Cursor | Dracula-cursors system-wide |

### Dracula Color Reference

| Name | Hex | Used for |
|------|-----|---------|
| Background | `#282a36` | Windows, bar, terminal |
| Current Line | `#44475a` | Selection, inactive borders |
| Comment | `#6272a4` | Inactive workspace indicators |
| Foreground | `#f8f8f2` | Text |
| Purple | `#bd93f9` | Active borders, accents, waybar bottom line |
| Pink | `#ff79c6` | Border gradient end, memory module |
| Cyan | `#8be9fd` | CPU, network modules |
| Green | `#50fa7b` | Battery module |
| Yellow | `#f1fa8c` | Clock, backlight modules |
| Red | `#ff5555` | Critical states, urgent notifications |
| Orange | `#ffb86c` | Temperature, battery warning |

---

## ⌨️ Default Keybinds

`$mod` = **SUPER** (Windows key)

| Keybind | Action |
|---------|--------|
| `SUPER + Return` | Open terminal (kitty) |
| `SUPER + D` | App launcher (rofi) |
| `SUPER + E` | File manager (thunar) |
| `SUPER + Q` | Close window |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + SHIFT + Space` | Toggle floating |
| `SUPER + M` | Exit Hyprland |
| `SUPER + H/J/K/L` | Move focus (vim-style) |
| `SUPER + SHIFT + H/J/K/L` | Move window |
| `SUPER + ALT + H/J/K/L` | Resize window |
| `SUPER + 1–9` | Switch workspace |
| `SUPER + SHIFT + 1–9` | Move window to workspace |
| `SUPER + S` | Toggle scratchpad |
| `SUPER + SHIFT + S` | Move to scratchpad |
| `SUPER + V` | Clipboard history picker |
| `SUPER + drag` | Move window with mouse |
| `SUPER + right-click drag` | Resize window with mouse |
| `Print` | Screenshot (full screen) |
| `SHIFT + Print` | Screenshot (select region) |
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioLowerVolume` | Volume −5% |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Toggle mic mute |
| `XF86MonBrightnessUp` | Brightness +5% |
| `XF86MonBrightnessDown` | Brightness −5% |

---

## 🗂️ Config File Locations

```
~/.config/hypr/
├── hyprland.conf          # Main Hyprland config
└── nvidia-env.conf        # NVIDIA Wayland environment variables

~/.config/waybar/
├── config.jsonc           # Bar layout and modules
└── style.css              # Dracula color scheme

~/.config/kitty/
└── kitty.conf             # Terminal — Dracula palette + JetBrainsMono

~/.config/rofi/
├── config.rasi            # Rofi settings (uses Dracula theme)
└── dracula.rasi           # Dracula theme definition

~/.config/mako/
└── config                 # Notification daemon — Dracula colors

~/.config/gtk-3.0/
└── settings.ini           # GTK3 theme settings

~/.config/gtk-4.0/
└── settings.ini           # GTK4 theme settings

~/.config/qt5ct/
└── qt5ct.conf             # Qt5 appearance (Kvantum dark + Papirus-Dark)

~/.config/qt6ct/
└── qt6ct.conf             # Qt6 appearance

~/.config/Kvantum/
└── kvantum.kvconfig       # Kvantum Qt theme engine config

/etc/sddm.conf.d/
└── theme.conf             # SDDM Dracula login screen

/etc/modprobe.d/
├── nvidia.conf            # DRM modeset=1 fbdev=1
└── blacklist-nouveau.conf # Nouveau blacklisted

/etc/pacman.d/hooks/
└── nvidia-initramfs.hook  # Auto-rebuild initramfs on kernel/driver update
```

---

## 🔧 Post-Install Checklist

After the script finishes, do the following:

### 1. Reboot
```bash
sudo reboot
```

### 2. Verify NVIDIA DRM is active
```bash
cat /sys/module/nvidia_drm/parameters/modeset
# Must return: Y
```

### 3. Set a wallpaper (if you skipped the Wallpaper Bank)
```bash
swww img ~/Pictures/Wallpapers/your-wallpaper.png --transition-type fade
```

---

## 🛠️ Troubleshooting

### SDDM black screen / login hang
This is a known NVIDIA issue. Fix:
1. Press `Ctrl + Alt + F2` to get a TTY
2. Log in with your username and password
3. Find your GPU's DRM device:
```bash
lspci -nn | grep -i nvidia          # note your PCI ID
ls -l /dev/dri/by-path              # find matching symlink (e.g. → ../card1)
```
4. Add to `~/.config/hypr/nvidia-env.conf`:
```
env = WLR_DRM_DEVICES,/dev/dri/card1
```
5. Reboot

### Cursor invisible after login
In `~/.config/hypr/nvidia-env.conf`, change:
```
env = WLR_NO_HARDWARE_CURSORS,1
```
to `0` if you want hardware cursors, or leave as `1` for software cursors (more compatible with NVIDIA).

### Apps crash or render incorrectly
`GBM_BACKEND=nvidia-drm` can occasionally cause issues with specific apps. Comment it out in `~/.config/hypr/nvidia-env.conf`:
```
# env = GBM_BACKEND,nvidia-drm
```

### Brightness keys not working
Your user must be in the `video` group (the script does this automatically, but requires a reboot to take effect):
```bash
groups $USER | grep video   # verify
```
If missing:
```bash
sudo usermod -aG video $USER
# then reboot
```

### PipeWire / no audio
```bash
systemctl --user status pipewire pipewire-pulse wireplumber
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### GTK apps not using Dracula theme
The `gsettings` lines in `hyprland.conf` autostart re-apply the theme on every login. If they fail, run manually:
```bash
gsettings set org.gnome.desktop.interface gtk-theme 'Dracula'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Dracula-cursors'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

---

## 🎮 Optional — ASUS ROG Utilities

For fan control, RGB keyboard lighting, and battery charge limit (charge to 80% for longevity):

```bash
yay -S asusctl supergfxctl
sudo systemctl enable --now asusd
```

---

## 📁 Repository Structure

```
.
├── install-hyprland.sh   # Main installer script
└── README.md                    # This file
```

---

## 🙏 Credits & References

| Resource | Link |
|----------|------|
| JaKooLit Arch-Hyprland | [github.com/JaKooLit/Arch-Hyprland](https://github.com/JaKooLit/Arch-Hyprland) |
| JaKooLit Wallpaper-Bank | [github.com/JaKooLit/Wallpaper-Bank](https://github.com/JaKooLit/Wallpaper-Bank) |
| Hyprland Wiki | [wiki.hyprland.org](https://wiki.hyprland.org) |
| Hyprland NVIDIA Guide | [wiki.hyprland.org/Nvidia](https://wiki.hyprland.org/Nvidia/) |
| Arch Wiki — NVIDIA | [wiki.archlinux.org/title/NVIDIA](https://wiki.archlinux.org/title/NVIDIA) |
| Dracula Theme | [draculatheme.com](https://draculatheme.com) |

---

## 📄 License

MIT — free to use, modify, and distribute. Credit appreciated but not required.

---

<div align="center">
Made for the ROG. Built for the terminal. Themed in Dracula.
</div>
