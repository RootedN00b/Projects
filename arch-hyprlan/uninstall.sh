#!/usr/bin/env bash
#
# uninstall.sh — Reverse everything setup-hyprland.sh did.
# Removes the packages it installed, the config files it wrote, the services it
# enabled, and (optionally) paru. Backs up your configs before deleting them.
#
# Run as your normal user (NOT root). Usage:
#   chmod +x uninstall.sh && ./uninstall.sh
#   ./uninstall.sh --yes          # skip the confirmation prompt
#   ./uninstall.sh --keep-paru    # leave paru installed
#   ./uninstall.sh --no-backup    # delete configs without backing up
#
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "[!] Do NOT run as root. Run as your user; sudo is invoked where needed."
  exit 1
fi
command -v pacman >/dev/null || { echo "[!] Not an Arch system."; exit 1; }

ASSUME_YES=0
KEEP_PARU=0
DO_BACKUP=1
for arg in "$@"; do
  case "$arg" in
    --yes|-y)      ASSUME_YES=1 ;;
    --keep-paru)   KEEP_PARU=1 ;;
    --no-backup)   DO_BACKUP=0 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

log()  { printf '\n\033[1;35m[*] %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------
# Package lists — mirror exactly what setup-hyprland.sh installed
# ---------------------------------------------------------------------------
PACMAN_PKGS=(
  hyprland xdg-desktop-portal-hyprland
  waybar rofi-wayland mako kitty
  hyprpaper hyprlock hypridle
  grim slurp wl-clipboard cliphist
  brightnessctl playerctl pamixer pavucontrol
  network-manager-applet blueman
  thunar thunar-archive-plugin gvfs file-roller
  polkit-gnome qt5-wayland qt6-wayland
  pipewire pipewire-pulse pipewire-alsa wireplumber
  ttf-jetbrains-mono-nerd ttf-font-awesome noto-fonts noto-fonts-emoji
  papirus-icon-theme imagemagick
  vulkan-intel intel-media-driver vulkan-radeon libva-mesa-driver
  mesa vulkan-icd-loader libva-utils
)

AUR_PKGS=(
  dracula-gtk-theme dracula-icons-git
  qt5ct qt6ct kvantum kvantum-theme-dracula-git
  wlogout
)

CONFIG_DIRS=(
  "$HOME/.config/hypr"
  "$HOME/.config/waybar"
  "$HOME/.config/rofi"
  "$HOME/.config/kitty"
  "$HOME/.config/mako"
)
GTK_FILE="$HOME/.config/gtk-3.0/settings.ini"

# ---------------------------------------------------------------------------
# Confirmation
# ---------------------------------------------------------------------------
cat <<EOF

This will REMOVE the following, reversing setup-hyprland.sh:
  - Hyprland + desktop packages (pacman)         [${#PACMAN_PKGS[@]} packages]
  - Dracula theming packages (AUR)               [${#AUR_PKGS[@]} packages]
  - Config dirs: ~/.config/{hypr,waybar,rofi,kitty,mako}
  - GTK setting: ~/.config/gtk-3.0/settings.ini (only if it matches what we wrote)
  - Disable bluetooth.service and NetworkManager.service
$( [[ $KEEP_PARU -eq 0 ]] && echo "  - paru (AUR helper)" )
$( [[ $DO_BACKUP -eq 1 ]] && echo "  Configs will be backed up first." || echo "  Configs will be DELETED without backup." )

EOF

if [[ $ASSUME_YES -ne 1 ]]; then
  read -rp "Proceed? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

# ---------------------------------------------------------------------------
# 1. Stop running desktop processes (so files/services release cleanly)
# ---------------------------------------------------------------------------
log "Stopping running desktop processes"
for proc in waybar mako hyprpaper hypridle hyprlock nm-applet blueman-applet \
            cliphist polkit-gnome-authentication-agent-1 Hyprland; do
  pkill -x "$proc" 2>/dev/null || true
done

# ---------------------------------------------------------------------------
# 2. Disable the services setup enabled
# ---------------------------------------------------------------------------
log "Disabling services"
sudo systemctl disable --now bluetooth.service 2>/dev/null || warn "bluetooth.service not active."
sudo systemctl disable NetworkManager.service 2>/dev/null || warn "NetworkManager.service not disabled (leaving network up)."
warn "NetworkManager was only disabled, not stopped, so you keep connectivity. It will not start on next boot — re-enable it or configure another network manager before rebooting."

# ---------------------------------------------------------------------------
# 3. Back up, then remove config files
# ---------------------------------------------------------------------------
if [[ $DO_BACKUP -eq 1 ]]; then
  BACKUP="$HOME/hypr-config-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  log "Backing up configs to $BACKUP"
  EXISTING=()
  for d in "${CONFIG_DIRS[@]}"; do [[ -e "$d" ]] && EXISTING+=("$d"); done
  [[ -e "$GTK_FILE" ]] && EXISTING+=("$GTK_FILE")
  if [[ ${#EXISTING[@]} -gt 0 ]]; then
    tar -czf "$BACKUP" -C / "${EXISTING[@]#/}" 2>/dev/null || warn "Backup had warnings."
  else
    warn "No config files found to back up."
  fi
fi

log "Removing config directories"
for d in "${CONFIG_DIRS[@]}"; do
  if [[ -d "$d" ]]; then
    rm -rf "$d"
    echo "    removed $d"
  fi
done

# Only remove the GTK file if it's the exact one we wrote (don't clobber user edits)
if [[ -f "$GTK_FILE" ]] && grep -q '^gtk-theme-name=Dracula$' "$GTK_FILE" 2>/dev/null; then
  rm -f "$GTK_FILE"
  echo "    removed $GTK_FILE"
  rmdir "$HOME/.config/gtk-3.0" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 4. Remove AUR packages (and paru) via paru if present
# ---------------------------------------------------------------------------
if command -v paru >/dev/null 2>&1; then
  log "Removing AUR theming packages"
  installed_aur=()
  for p in "${AUR_PKGS[@]}"; do
    pacman -Qq "$p" >/dev/null 2>&1 && installed_aur+=("$p")
  done
  if [[ ${#installed_aur[@]} -gt 0 ]]; then
    paru -Rns --noconfirm "${installed_aur[@]}" || warn "Some AUR removals failed; remove manually."
  else
    warn "No AUR theming packages found installed."
  fi
else
  warn "paru not found; skipping AUR package removal."
fi

# ---------------------------------------------------------------------------
# 5. Remove pacman packages
# ---------------------------------------------------------------------------
log "Removing pacman packages"
installed_pac=()
for p in "${PACMAN_PKGS[@]}"; do
  pacman -Qq "$p" >/dev/null 2>&1 && installed_pac+=("$p")
done
if [[ ${#installed_pac[@]} -gt 0 ]]; then
  # -Rns: remove package, unneeded deps, and config files (.pacsave avoided where possible)
  sudo pacman -Rns --noconfirm "${installed_pac[@]}" || \
    warn "Some packages could not be removed (likely depended on by other software). Review above."
else
  warn "None of the listed pacman packages are installed."
fi

# ---------------------------------------------------------------------------
# 6. Remove paru itself (unless --keep-paru)
# ---------------------------------------------------------------------------
if [[ $KEEP_PARU -eq 0 ]] && pacman -Qq paru >/dev/null 2>&1; then
  log "Removing paru"
  sudo pacman -Rns --noconfirm paru || warn "Could not remove paru; remove manually with: sudo pacman -Rns paru"
fi

# ---------------------------------------------------------------------------
# 7. Clean orphans + caches created during the process
# ---------------------------------------------------------------------------
log "Removing orphaned dependencies"
orphans="$(pacman -Qdtq 2>/dev/null || true)"
if [[ -n "$orphans" ]]; then
  # shellcheck disable=SC2086
  sudo pacman -Rns --noconfirm $orphans || warn "Orphan cleanup had issues."
else
  echo "    no orphans."
fi

log "Cleaning build/cache leftovers"
rm -rf "$HOME/.cache/paru" 2>/dev/null || true
rm -f  "$HOME"/.config/hypr/wall.png 2>/dev/null || true   # in case dir survived

# ---------------------------------------------------------------------------
# 8. Summary
# ---------------------------------------------------------------------------
log "Uninstall complete"
cat <<EOF

  Reversed:
    * Desktop + theming packages removed (pacman -Rns)
    * AUR theme packages removed
    * Config dirs deleted$( [[ $DO_BACKUP -eq 1 ]] && echo " (backup saved to $HOME/hypr-config-backup-*.tar.gz)" )
    * bluetooth + NetworkManager disabled
    $( [[ $KEEP_PARU -eq 0 ]] && echo "* paru removed" || echo "* paru kept (--keep-paru)" )
    * Orphans and paru cache cleaned

  IMPORTANT:
    - NetworkManager was disabled for next boot. If it is your only network
      manager, re-enable it now:  sudo systemctl enable --now NetworkManager
      or set up an alternative BEFORE rebooting, or you will boot with no network.
    - System packages that other software also depends on were NOT force-removed.
      Anything left is shared with the rest of your system.
    - A few package post-install files (font caches, icon caches) are regenerated
      by pacman hooks and are harmless to leave.

EOF
