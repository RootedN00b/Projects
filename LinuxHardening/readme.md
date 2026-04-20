

# Titan Hardening & Anonymity Suite

**Author:** rootedn00b

A terminal-based, menu-driven Linux hardening script that applies security controls across authentication, networking, the kernel, filesystem, and more. Designed for users who want structured system hardening without manually editing dozens of config files.

---

## Table of Contents

- [Overview](#overview)
- [Compatibility](#compatibility)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Usage](#usage)
- [Menu Reference](#menu-reference)
- [What Gets Changed](#what-gets-changed)
- [Backups](#backups)
- [Logs](#logs)
- [Warnings](#warnings)
- [FAQ](#faq)
- [License](#license)

---

## Overview

Titan provides a `whiptail` TUI (text-based UI) with 23 individually selectable hardening modules. You can run modules one at a time or trigger a full sequential lockdown. Every module that modifies a system file creates a `.bak` backup first.

The suite covers:

- Mandatory Access Control (AppArmor)
- Password policy and hashing strength
- SSH daemon hardening
- Kernel sysctl hardening
- PAM authentication and account lockout
- File integrity monitoring
- Kernel-level audit logging (auditd)
- USB storage lockdown
- Filesystem mount hardening
- Rootkit detection
- Network anonymity (MAC address / hostname randomisation)
- Automatic security updates
- User account auditing
- Secure Boot status
- Entropy pool enhancement
- Interactive log viewer for auditd and fail2ban

---

## Compatibility

| Distribution | Status |
|---|---|
| Ubuntu (20.04+) | Fully supported |
| Debian (11+) | Fully supported |
| Arch Linux | Fully supported (AUR helper required for some optional tools) |
| Other distros | Script detects OS and exits gracefully for unsupported systems |

> **Arch note:** Some packages (chkrootkit) are AUR-only. Install `yay` or `paru` before running those modules.

---

## Dependencies

### Required

| Package | Purpose |
|---|---|
| `whiptail` | TUI menus and dialogs (part of `newt`) |
| `bash` | Script interpreter |
| `sudo` | Privilege escalation (not needed if running as root) |

### Optional (installed on demand)

Each module prompts to install its own dependency if missing. The following packages are used across the suite:

| Package | Module | Arch package name |
|---|---|---|
| `apparmor` | MAC Framework | `apparmor` |
| `acct` | System Accounting | `acct` |
| `aide` | File Integrity (Debian/Ubuntu only) | AUR only — `paccheck` used instead |
| `pacutils` | File Integrity (Arch only) | `pacutils` |
| `openssl` | Crypto Check | `openssl` |
| `ufw` | Firewall | `ufw` |
| `macchanger` | Network Anonymity | `macchanger` |
| `fail2ban` | IDS / Honeyports | `fail2ban` |
| `ncat` | Honeyports | included in `nmap` on Arch |
| `auditd` | Kernel Audit | `audit` |
| `libpam-pwquality` | PAM Hardening | `libpwquality` |
| `rkhunter` | Rootkit Detection | `rkhunter` |
| `chkrootkit` | Rootkit Detection | AUR: `chkrootkit` |
| `haveged` | Entropy | `haveged` |
| `lynis` | Full Security Audit | `lynis` |
| `unattended-upgrades` | Auto Updates (Debian/Ubuntu) | n/a |
| `pacman-contrib` | Auto Updates (Arch) | `pacman-contrib` |
| `mokutil` | Secure Boot Check | `mokutil` |

---

## Installation

```bash
git clone https://github.com/<your-username>/titan.git
cd titan
chmod +x titan.sh
```

No build step required.

---

## Usage

Run as root or with a user that has full sudo privileges:

```bash
sudo ./titan.sh
```

Or as root directly:

```bash
su -
./titan.sh
```

The TUI menu launches immediately. Use arrow keys to navigate, Enter to select, and Escape or the Exit option to quit.

> The script displays your detected OS in the menu subtitle so you can confirm detection is correct before proceeding.

---

## Menu Reference

| Option | Name | What it does |
|---|---|---|
| 1 | MAC Framework | Installs and enables AppArmor. On Arch, provides kernel parameter instructions for full LSM activation. |
| 2 | Password Aging & SHA512 Hashing | Hardens `/etc/login.defs`: sets SHA512 with 640,000 rounds (NIST-aligned) and enforces 90-day maximum password age with a 14-day warning. |
| 3 | System Accounting | Enables the `acct` daemon so per-user command history is recorded and queryable with `lastcomm` and `sa`. |
| 4 | File Integrity Monitoring | **Debian/Ubuntu:** Initialises an AIDE database snapshot. Run `aide --check` periodically to detect unauthorised changes. **Arch:** Uses `paccheck` to validate installed files against the pacman database. |
| 5 | Cryptography & SSL Cert Check | Ensures an ED25519 SSH host key exists. Scans system certificate stores and reports any certificate expiring within 30 days. |
| 6 | Kernel & Sysctl Hardening | Writes 14 sysctl parameters to `/etc/sysctl.d/99-titan.conf` covering ASLR, kernel pointer restriction, reverse-path filtering, SYN cookie protection, and ICMP/redirect hardening. |
| 7 | Network Anonymity | Randomises the MAC address on the primary interface using `macchanger`. Optionally randomises the system hostname to a random 8-character string. |
| — | UFW Firewall *(Full Lockdown only)* | Installs and enables `ufw` with a default deny-inbound policy. Not available as a standalone menu option — runs automatically as part of Full Lockdown (option 23). |
| 8 | USB Hardware Lockdown | Three-option submenu: **Enable** (module blacklist + udev rule), **Disable** (removes both), **Status** (reports current state and whether the module is loaded). |
| 9 | IDS & Honeyports | Installs and enables `fail2ban` for automated IP banning. Optionally starts `ncat` listeners on ports 23 (Telnet), 5900 (VNC), and 3389 (RDP) as honeypots. |
| 10 | SSH Daemon Hardening | Writes a drop-in config to `/etc/ssh/sshd_config.d/99-titan.conf` enforcing key-only authentication, disabling root login, restricting to modern ciphers/MACs/KexAlgorithms, and tightening session limits. Validates with `sshd -t` and auto-reverts on failure. |
| 11 | Kernel Audit Framework | Installs `auditd` and loads CIS-aligned rules monitoring credential files, sudoers, SSH config, privilege escalation, setuid calls, module loads, and access denials. Rules are made immutable until the next reboot (`-e 2`). |
| 12 | PAM: Password Quality & Lockout | Configures `pam_pwquality` (minimum 14 characters, 3 character classes, no repeats) and `pam_faillock` (5 failures triggers a 10-minute lockout). Wires both into the appropriate PAM stack file per distro. |
| 13 | SUID/SGID Binary Audit | Scans the full filesystem for SUID/SGID binaries and shows a scrollable list. Offers to strip the SUID bit from a curated list of non-essential candidates (`wall`, `write`, `traceroute`, `chfn`, `chsh`, `newgrp`, `pppd`). |
| 14 | Core Dump Hardening | Disables core dumps at four independent layers: PAM `limits.d`, kernel sysctl (`suid_dumpable=0`), systemd `system.conf.d`, and `systemd-coredump.conf`. Prevents plaintext key and secret leakage from crash dumps. |
| 15 | Filesystem Mount Hardening | Blacklists exotic kernel filesystems (`cramfs`, `freevxfs`, `jffs2`, `hfs`, `hfsplus`, `squashfs`, `udf`) via `modprobe.d`. **squashfs is skipped if Flatpak is installed** (Flatpak runtimes are squashfs images). Remounts `/tmp` with `noexec`, `nosuid`, `nodev` and persists in `/etc/fstab`. `/dev/shm` is hardened the same way **unless Wayland/Hyprland is detected** — GPU buffer sharing via `/dev/shm` requires exec permissions. |
| 16 | Rootkit Detection | Runs `rkhunter` (with property update) and `chkrootkit` sequentially. Saves output to `/var/log/titan/` (root-only, `chmod 700`). |
| 17 | Automatic Security Updates | **Debian/Ubuntu:** Configures `unattended-upgrades` for daily security-only patches with no automatic reboot. **Arch:** Installs a weekly systemd timer that syncs the package database and logs pending updates to `/var/log/titan/pending-updates.log` — you apply them manually. |
| 18 | User Account Audit & Session Timeout | Reports accounts with empty passwords, non-root UID 0 accounts, shell accounts with no expiry, and a count of world-writable files. Optionally enforces a 15-minute idle shell timeout (`TMOUT=900`) via `/etc/profile.d/`. |
| 19 | Secure Boot Status Check | Detects Secure Boot state via `mokutil` or by reading the EFI variable directly. Reports current status and advises enabling it if off. |
| 20 | Entropy Enhancement | Reports current kernel entropy pool size and installs `haveged` to continuously replenish it, improving key quality for SSH, TLS, and MAC randomisation. |
| 21 | Run Full Security Audit | Runs `lynis audit system` in the terminal and displays the scored report. |
| 22 | Log Viewer | Interactive submenu with 8 views: 6 auditd queries (by audit key) and 2 fail2ban views (jail status with banned IPs, raw log tail). All views detect missing tools and direct you to the install option. |
| 23 | FULL SYSTEM LOCKDOWN | Runs all 21 hardening modules sequentially after a single confirmation (includes UFW firewall setup which has no standalone menu entry). Advises a reboot on completion. |
| 24 | Exit | Exits the script. |

---

## What Gets Changed

The following files and directories may be created or modified depending on which modules you run:

| Path | Module | Notes |
|---|---|---|
| `/etc/login.defs` | 2 | Backup created at `.bak` |
| `/etc/ssh/sshd_config` | 10 | Backup created at `.bak`; Include directive added |
| `/etc/ssh/sshd_config.d/99-titan.conf` | 10 | New drop-in file |
| `/etc/audit/rules.d/99-titan.rules` | 11 | New file |
| `/etc/security/pwquality.conf` | 12 | Overwritten |
| `/etc/security/faillock.conf` | 12 | Overwritten |
| `/etc/pam.d/common-auth` | 12 | Backup at `.bak` (Debian/Ubuntu) |
| `/etc/pam.d/common-password` | 12 | Backup at `.bak` (Debian/Ubuntu) |
| `/etc/pam.d/system-auth` | 12 | Backup at `.bak` (Arch) |
| `/etc/pam.d/system-password` | 12 | Backup at `.bak` (Arch) |
| `/etc/security/limits.d/99-titan-coredump.conf` | 14 | New file |
| `/etc/sysctl.d/99-titan.conf` | 6 | New file (overwritten on repeat runs) |
| `/etc/sysctl.d/99-titan-coredump.conf` | 14 | New file |
| `/etc/systemd/system.conf.d/99-titan-coredump.conf` | 14 | New file |
| `/etc/systemd/coredump.conf` | 14 | Backup at `.bak` |
| `/etc/modprobe.d/99-titan-fs-blacklist.conf` | 15 | New file |
| `/etc/modprobe.d/99-titan-usb-storage.conf` | 8 | New file (Enable), deleted (Disable) |
| `/etc/udev/rules.d/99-titan-usb-lock.rules` | 8 | New file (Enable), deleted (Disable) |
| `/etc/fstab` | 15 | Backup at `.bak`; entries appended |
| `/etc/profile.d/titan-tmout.sh` | 18 | New file |
| `/etc/systemd/system/titan-autoupdate.*` | 17 | New service and timer (Arch) |
| `/etc/apt/apt.conf.d/50titan-unattended-upgrades` | 17 | New file (Debian/Ubuntu) |
| `/etc/apt/apt.conf.d/20titan-auto-upgrades` | 17 | New file (Debian/Ubuntu) |
| `/var/log/titan/` | 16, 17 | Root-only log directory (`chmod 700`) |

---

## Backups

Every module that modifies an existing system file copies it to `<original-path>.bak` before making changes. To revert any individual change:

```bash
# Example: revert SSH config
sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
sudo systemctl restart sshd

# Example: revert PAM auth (Debian/Ubuntu)
sudo cp /etc/pam.d/common-auth.bak /etc/pam.d/common-auth
sudo cp /etc/pam.d/common-password.bak /etc/pam.d/common-password

# Example: revert login.defs
sudo cp /etc/login.defs.bak /etc/login.defs
```

> Backup files are not rotated. If you run a module twice, the second run overwrites the `.bak` with the already-modified version. Take your own snapshots before repeat runs if you need to preserve the original state.

---

## Logs

| Path | Contents |
|---|---|
| `/var/log/titan/rkhunter.log` | Full rkhunter scan output |
| `/var/log/titan/chkrootkit.log` | Full chkrootkit scan output |
| `/var/log/titan/pending-updates.log` | Arch: packages with available updates (refreshed weekly) |
| `/var/log/titan/update-history.log` | Arch: timestamp and update count per weekly check |

All files under `/var/log/titan/` are owned by root and readable only by root (`chmod 700` on the directory).

---

## Warnings

### SSH Hardening (option 10 and Full Lockdown)

Option 10 disables SSH password authentication and enforces key-only login. **If you do not have an `authorized_keys` entry in place before running this module, you will be locked out of SSH.** The script prompts you to confirm you have keys configured, but it cannot verify this for you.

**Before running SSH hardening:**

```bash
# On your local machine, copy your public key to the server
ssh-copy-id user@your-server

# Verify key-based login works in a separate terminal
ssh user@your-server

# Only then run option 10
```

### PAM Hardening (option 12)

This module edits `/etc/pam.d/` files which control how all logins are authenticated. A misconfiguration can prevent all users, including root, from logging in.

**Recommended precaution:** Keep an active root shell session open while running this module so you can revert the backup if something goes wrong.

### AppArmor on Arch (option 1)

The module installs AppArmor and enables the systemd unit, but AppArmor enforcement requires a kernel boot parameter. Without it, the service starts but no profiles are enforced. After running option 1 on Arch, add the following to your bootloader's kernel command line and reboot:

```
lsm=landlock,yama,integrity,apparmor,bpf
```

> **Note:** `lockdown` is intentionally omitted. Including it blocks DRM/KMS ioctls used by Wayland compositors (Hyprland, sway, etc.), causing a black screen on next boot.

For GRUB, edit `/etc/default/grub`, append the parameter to `GRUB_CMDLINE_LINUX_DEFAULT`, then regenerate the config:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Reboot After Full Lockdown

Several modules write configurations that only take full effect after a reboot:

- sysctl parameters (applied live, but re-read from file on boot)
- modprobe blacklists (prevent modules from loading on next boot)
- fstab mount options (applied live where possible, persistent on next boot)
- systemd limits (require daemon-reload and session restart)

After running Full Lockdown (option 23), reboot before considering the system fully hardened.

### Arch Rolling Release Updates (option 17)

The Arch auto-update configuration intentionally does **not** run `pacman -Syu` automatically. Unattended full upgrades on a rolling-release system risk dependency conflicts that can leave the system in a broken state. The timer syncs the package database and logs what is available — you apply updates at a time of your choosing.

---

## FAQ

**Can I run individual modules without doing a full lockdown?**

Yes. Every menu option is independent. Run only what you need.

**Does the script work on servers without a graphical interface?**

Yes. `whiptail` works over SSH and on any terminal. No graphical display is required.

**What happens if I run a module twice?**

Most modules are idempotent — running them twice produces the same result. The main exception is that the second run overwrites the `.bak` backup with the already-modified version of the file, so you lose the original pre-Titan state. Take your own snapshot before re-running if that matters.

**Can I undo the full lockdown?**

Yes, piecemeal. Each change has a documented backup or can be reversed by deleting the file Titan created. There is no single "undo all" command. Refer to the [What Gets Changed](#what-gets-changed) table for the full list of modified paths.

**Why does the AIDE scan take so long?**

AIDE hashes every file on the filesystem to build its baseline database. On a system with a large number of files, this can take several minutes. This is normal behaviour.

**The PAM module says it modified my files but login still works the same way — why?**

PAM changes take effect on the next login attempt, not the current session. Open a new terminal and attempt a login to verify the new policy is active.

**I'm on Arch and chkrootkit won't install — is it skipped?**

The script will offer to install it via your AUR helper (`yay` or `paru`). If neither is installed, the chkrootkit step is skipped gracefully with an explanatory message. `rkhunter` (available in official Arch repos) still runs.

**Is this script safe to run on a production server?**

It is stable and has been reviewed for correctness, but treat it like any system-hardening tool: test in a VM or staging environment first, understand what each module does, and keep backups. The SSH hardening module in particular carries real lockout risk if applied without care.

---

## License

MIT License — use freely, modify freely, contribute back if you improve it.

```
Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
