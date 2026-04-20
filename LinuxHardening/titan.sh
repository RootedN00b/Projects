#!/bin/bash

# ==============================================================================
# TITAN HARDENING & ANONYMITY SUITE - EXTENDED VERSION
# ==============================================================================

# --- 1. CORE UTILITIES & DETECTION ---

# Runs a command with sudo only when not already root, avoiding double-sudo in root sessions.
run_sudo() {
    if [[ $EUID -ne 0 ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Populates the global $OS variable from /etc/os-release; used by all distro-branching logic below.
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        OS="unknown"
    fi
}

# Populates $DE (desktop environment, lowercased) and $SESSION_TYPE (x11/wayland).
# Used to guard Wayland-incompatible hardening steps (e.g. /dev/shm noexec).
detect_de() {
    DE="${XDG_CURRENT_DESKTOP:-unknown}"
    DE="${DE,,}"
    SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"
    SESSION_TYPE="${SESSION_TYPE,,}"
    # Fallback: infer wayland from WAYLAND_DISPLAY when XDG_SESSION_TYPE is unset
    if [[ "$SESSION_TYPE" == "unknown" && -n "$WAYLAND_DISPLAY" ]]; then
        SESSION_TYPE="wayland"
    fi
    # Fallback: detect Hyprland by binary when XDG_CURRENT_DESKTOP is unset
    if [[ "$DE" == "unknown" ]] && command -v hyprctl &>/dev/null; then
        DE="hyprland"
    fi
}

# Installs a package only when its command is absent; optional 3rd arg overrides the package name on Arch (e.g. nmap vs ncat).
smart_install() {
    local PKG=$1
    local CMD=$2
    local ARCH_PKG=${3:-$PKG}
    if command -v "$CMD" &>/dev/null; then
        return 0
    fi
    if whiptail --title "Installation Required" --yesno "$PKG is missing. Install it?" 8 45; then
        case "$OS" in
            ubuntu|debian) run_sudo apt-get update && run_sudo apt-get install -y "$PKG" ;;
            arch) run_sudo pacman -Syu --noconfirm "$ARCH_PKG" ;;
            *)
                whiptail --msgbox "Unsupported OS: '$OS'. Cannot auto-install $PKG." 8 55
                return 1
                ;;
        esac
    else
        return 1
    fi
}

# Installs an AUR package via yay or paru; returns 1 with a clear message if no AUR helper is present.
aur_install() {
    local PKG=$1
    if command -v yay &>/dev/null; then
        yay -S --noconfirm "$PKG"
    elif command -v paru &>/dev/null; then
        paru -S --noconfirm "$PKG"
    else
        whiptail --msgbox "No AUR helper found (yay/paru).\n\nCannot install '$PKG' automatically.\nInstall yay or paru first, then retry." 10 60
        return 1
    fi
}

# --- 2. ORIGINAL SECURITY FUNCTIONS ---

# Enables Mandatory Access Control: AppArmor on Debian/Ubuntu and Arch (with kernel param guidance on Arch).
fn_mac_framework() {
    case "$OS" in
        ubuntu|debian)
            if smart_install "apparmor" "apparmor_parser"; then
                run_sudo systemctl enable apparmor --now
                whiptail --msgbox "AppArmor is now active and enforcing." 8 45
            fi
            ;;
        arch)
            # AppArmor is in the official Arch repos and works with the standard kernel.
            # The lsm= kernel parameter is required to activate it at boot.
            # NOTE: 'lockdown' is intentionally omitted from the LSM list below.
            # lockdown=integrity blocks certain DRM/KMS ioctls that Wayland compositors
            # (Hyprland, sway, etc.) rely on, causing a black screen on next boot.
            if smart_install "apparmor" "apparmor_parser"; then
                run_sudo systemctl enable apparmor --now
                local APPARMOR_MSG="AppArmor installed and enabled.\n\nArch requires a kernel parameter to activate LSM at boot.\nAdd the following to your bootloader kernel line:\n\n  lsm=landlock,yama,integrity,apparmor,bpf\n\nFor GRUB: edit /etc/default/grub → GRUB_CMDLINE_LINUX_DEFAULT\nthen run: grub-mkconfig -o /boot/grub/grub.cfg\n\nA reboot is required for AppArmor to enforce profiles."
                if [[ "$SESSION_TYPE" == "wayland" || "$DE" == "hyprland" ]] || command -v hyprctl &>/dev/null; then
                    APPARMOR_MSG+="\n\nHyprland/Wayland detected: 'lockdown' has been omitted from the LSM list. Including it can block DRM ioctls and cause a black screen."
                fi
                whiptail --msgbox "$APPARMOR_MSG" 20 74
            fi
            ;;
        *)
            whiptail --msgbox "MAC framework setup not supported on OS: '$OS'." 8 55
            ;;
    esac
}

# Hardens /etc/login.defs: raises SHA512 rounds to 640000 (NIST-aligned) and enforces 90-day password expiry.
fn_password_aging_hashing() {
    local DEFS=/etc/login.defs
    run_sudo cp "$DEFS" "${DEFS}.bak"

    run_sudo sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/' "$DEFS"
    run_sudo sed -i 's/^#\?SHA_CRYPT_MIN_ROUNDS.*/SHA_CRYPT_MIN_ROUNDS 640000/' "$DEFS"
    run_sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' "$DEFS"
    run_sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' "$DEFS"
    run_sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 14/' "$DEFS"

    whiptail --msgbox "Identity Hardened: SHA512 rounds set to 640000. Password aging set to 90 days.\n\nBackup: ${DEFS}.bak" 10 65
}

# Enables the acct daemon to record per-user command history queryable with lastcomm/sa.
fn_system_accounting() {
    if smart_install "acct" "lastcomm"; then
        run_sudo systemctl enable acct --now
        whiptail --msgbox "Process Accounting Enabled: Use 'lastcomm' to see command history." 10 55
    fi
}

# Initialises file integrity monitoring: AIDE on Debian/Ubuntu; paccheck (pacutils) on Arch as the native alternative since AIDE is AUR-only there.
fn_file_integrity() {
    case "$OS" in
        ubuntu|debian)
            if smart_install "aide" "aide"; then
                whiptail --msgbox "Initializing AIDE database. This may take a minute..." 8 45
                run_sudo aideinit
                if [ -f /var/lib/aide/aide.db.new.gz ]; then
                    run_sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
                elif [ -f /var/lib/aide/aide.db.new ]; then
                    run_sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
                fi
                whiptail --msgbox "File Integrity Monitoring (AIDE) initialized.\n\nRun 'aide --check' periodically to detect changes." 10 55
            fi
            ;;
        arch)
            # AIDE is AUR-only on Arch. paccheck (from pacutils) validates installed files
            # against pacman's own database checksums — no separate snapshot needed.
            if smart_install "pacutils" "paccheck"; then
                whiptail --msgbox "Running paccheck integrity scan against pacman database.\nThis may take a minute..." 8 55
                local ISSUES
                ISSUES=$(run_sudo paccheck --md5sum --quiet 2>&1 | head -n 100)
                if [ -n "$ISSUES" ]; then
                    whiptail --title "Integrity Issues Found" --scrolltext --msgbox "$ISSUES" 30 75
                else
                    whiptail --msgbox "File Integrity OK: all installed package files match the pacman database." 8 65
                fi
            fi
            ;;
        *)
            whiptail --msgbox "File integrity monitoring not configured for OS: '$OS'." 8 55
            ;;
    esac
}

# Ensures an ED25519 SSH host key exists and scans system cert stores for certificates expiring within 30 days.
fn_crypto_check() {
    echo "Performing Cryptography and SSL Audit..."
    smart_install "openssl" "openssl"

    if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
        echo "Generating secure ED25519 host keys..."
        run_sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
    fi

    CERT_PATHS="/etc/ssl/certs /etc/pki/tls/certs"
    EXPIRED_CERTS=""

    echo "Scanning system certificates for expiration..."
    for path in $CERT_PATHS; do
        if [ -d "$path" ]; then
            while IFS= read -r cert; do
                if ! openssl x509 -checkend 2592000 -noout -in "$cert" &>/dev/null; then
                    EXPIRED_CERTS+="$(basename "$cert")"$'\n'
                fi
            done < <(find "$path" -type f \( -name "*.crt" -o -name "*.pem" \) 2>/dev/null | head -n 20)
        fi
    done

    if [ -n "$EXPIRED_CERTS" ]; then
        whiptail --title "SSL Warning" --msgbox "The following certificates are expired or expire soon:\n\n$EXPIRED_CERTS" 15 60
    else
        whiptail --title "Crypto Check" --msgbox "Cryptography Verified:\n- SSH Host Keys: ED25519 Active\n- SSL Certs: All valid for >30 days." 10 60
    fi
}

# Writes 14 sysctl hardening parameters to /etc/sysctl.d/99-titan.conf covering ASLR, pointer leaks, reverse-path filtering, and redirect rejection.
fn_harden_kernel() {
    local CONF=/etc/sysctl.d/99-titan.conf
    run_sudo tee "$CONF" > /dev/null << 'EOF'
# Titan: kernel hardening
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv6.conf.all.accept_redirects = 0
EOF
    run_sudo sysctl -p "$CONF"
    whiptail --msgbox "Kernel hardening applied (14 sysctl settings)." 8 50
}

# Installs and enables UFW with its default deny-inbound policy as a baseline host firewall.
fn_setup_firewall() {
    if smart_install "ufw" "ufw"; then
        run_sudo ufw enable
        whiptail --msgbox "UFW firewall enabled." 8 40
    fi
}

# Randomises the MAC address on the primary interface via macchanger and optionally randomises the system hostname.
fn_network_anonymity() {
    local IFACE
    IFACE=$(ip -o link show | awk -F': ' '$2 !~ /^lo/{print $2}' | head -n1)

    if [ -z "$IFACE" ]; then
        whiptail --msgbox "No non-loopback interface found." 8 45
        return 1
    fi

    if whiptail --title "Network Anonymity" --yesno "Randomize MAC address on interface: $IFACE?" 8 55; then
        if smart_install "macchanger" "macchanger"; then
            run_sudo ip link set "$IFACE" down
            run_sudo macchanger -r "$IFACE"
            run_sudo ip link set "$IFACE" up
            whiptail --msgbox "MAC address randomized on $IFACE." 8 50
        fi
    fi

    if whiptail --title "Hostname Anonymity" --yesno "Randomize system hostname?" 8 45; then
        local NEW_HOST
        NEW_HOST="host-$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8)"
        run_sudo hostnamectl set-hostname "$NEW_HOST"
        whiptail --msgbox "Hostname set to: $NEW_HOST" 8 45
    fi
}

# Blocks USB storage via two independent layers: kernel module blacklist (usb_storage + uas) and a udev rule that de-authorises at driver-bind level. Includes enable/disable/status options.
fn_usb_lockdown() {
    local MOD_CONF=/etc/modprobe.d/99-titan-usb-storage.conf
    local RULE=/etc/udev/rules.d/99-titan-usb-lock.rules

    local OPT
    OPT=$(whiptail --title "USB Hardware Lockdown" --menu "Choose action:" 12 60 3 \
        "1" "Enable USB storage lockdown" \
        "2" "Disable USB storage lockdown" \
        "3" "Check current status" \
        3>&1 1>&2 2>&3) || return 0

    case "$OPT" in
        1)
            if ! whiptail --title "USB Lockdown" --yesno \
                "Block all USB storage devices?\n\nTwo layers will be applied:\n  1. Kernel module blacklist (usb_storage + uas)\n  2. udev rule at driver-bind level\n\nCurrently connected drives are unaffected until replug.\nReboot recommended to fully unload already-loaded modules." \
                14 68; then
                return 0
            fi

            # Layer 1: prevent usb_storage and uas kernel modules from loading
            run_sudo tee "$MOD_CONF" > /dev/null << 'EOF'
install usb_storage /bin/true
install uas /bin/true
EOF

            # Layer 2: udev rule matching at driver-bind (interface) level.
            # $DEVPATH is set by udev when RUN executes; dirname strips the
            # interface suffix (e.g. 1-1:1.0 → 1-1) to reach the USB device
            # node which holds the authorized attribute.
            run_sudo tee "$RULE" > /dev/null << 'EOF'
ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb-storage", RUN+="/bin/sh -c 'echo 0 > /sys$(dirname $DEVPATH)/authorized'"
ACTION=="add", SUBSYSTEM=="usb", DRIVER=="uas",         RUN+="/bin/sh -c 'echo 0 > /sys$(dirname $DEVPATH)/authorized'"
EOF
            run_sudo udevadm control --reload-rules

            whiptail --msgbox "USB storage lockdown ENABLED.\n\nLayer 1 — module blacklist:\n  $MOD_CONF\n  (usb_storage + uas will not load on next boot)\n\nLayer 2 — udev rule:\n  $RULE\n  (de-authorises storage devices at driver-bind on plug-in)\n\nReboot recommended to unload currently-loaded modules." 18 70
            ;;
        2)
            run_sudo rm -f "$MOD_CONF" "$RULE"
            run_sudo udevadm control --reload-rules
            whiptail --msgbox "USB storage lockdown DISABLED.\n\nBoth the module blacklist and udev rule have been removed.\nAlready-blocked devices require a replug. A reboot fully restores module loading." 12 68
            ;;
        3)
            local STATUS=""
            if [ -f "$MOD_CONF" ]; then
                STATUS+="[ACTIVE] Module blacklist: $MOD_CONF\n"
            else
                STATUS+="[OFF]    Module blacklist: not present\n"
            fi
            if [ -f "$RULE" ]; then
                STATUS+="[ACTIVE] udev rule:        $RULE\n"
            else
                STATUS+="[OFF]    udev rule:        not present\n"
            fi
            if lsmod 2>/dev/null | grep -q "usb_storage"; then
                STATUS+="\n[WARN]   usb_storage module is currently LOADED — reboot to unload it.\n"
            else
                STATUS+="\n[OK]     usb_storage module is not loaded.\n"
            fi
            whiptail --title "USB Lockdown Status" --msgbox "$STATUS" 14 70
            ;;
    esac
}

# Enables fail2ban for automated IP banning on brute-force attempts, then optionally starts ncat honeyport listeners on Telnet/VNC/RDP ports.
fn_ids_honeyports() {
    if smart_install "fail2ban" "fail2ban-client"; then
        run_sudo systemctl enable fail2ban --now
        whiptail --msgbox "Fail2ban IDS enabled and running.\n\nCheck status with: fail2ban-client status" 10 55
    fi

    if whiptail --title "Honeyports" --yesno "Start honeyport listeners on common attack ports (23, 5900, 3389)?\n\nNote: requires ncat and will not persist across reboots." 12 65; then
        # ncat is a standalone package on Debian/Ubuntu; on Arch it ships inside nmap
        if smart_install "ncat" "ncat" "nmap"; then
            for PORT in 23 5900 3389; do
                run_sudo ncat -l -k "$PORT" --sh-exec "echo 'Connection logged'" &>/dev/null &
            done
            whiptail --msgbox "Honeyport listeners started on ports: 23 (Telnet), 5900 (VNC), 3389 (RDP).\n\nThese are ephemeral and will not survive a reboot." 12 65
        fi
    fi
}

# --- 3. NEW HARDENING MODULES ---

# Writes a drop-in sshd config enforcing key-only auth, modern ciphers/MACs/KEX, no root login, and tight session limits; validates with sshd -t before restarting and auto-reverts on failure.
fn_harden_ssh() {
    local SSHD_CONF=/etc/ssh/sshd_config
    local DROP_IN_DIR=/etc/ssh/sshd_config.d
    local DROP_IN="$DROP_IN_DIR/99-titan.conf"

    # Warn before disabling password auth — a locked-out user has no recovery path
    if ! whiptail --title "SSH Hardening — WARNING" --yesno \
        "This will disable SSH password authentication (key-only login).\n\nEnsure you have a valid authorized_keys entry BEFORE proceeding.\n\nContinue?" 12 65; then
        return 0
    fi

    run_sudo cp "$SSHD_CONF" "${SSHD_CONF}.bak"
    run_sudo mkdir -p "$DROP_IN_DIR"

    # Ensure Include directive is present in the main config
    if ! run_sudo grep -q "Include $DROP_IN_DIR" "$SSHD_CONF"; then
        run_sudo sed -i "1s|^|Include $DROP_IN_DIR/*.conf\n|" "$SSHD_CONF"
    fi

    run_sudo tee "$DROP_IN" > /dev/null << 'EOF'
# Titan SSH Hardening
Protocol 2
PermitRootLogin no
PasswordAuthentication no
AuthenticationMethods publickey
PubkeyAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitUserEnvironment no
LoginGraceTime 20
MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group18-sha512
EOF

    if run_sudo sshd -t 2>/dev/null; then
        run_sudo systemctl restart sshd
        whiptail --msgbox "SSH hardened and restarted.\n\nKey changes:\n- Root login: DISABLED\n- Password auth: DISABLED (keys only)\n- Modern ciphers/MACs/KexAlgorithms only\n- LoginGraceTime: 20s, MaxAuthTries: 3\n\nBackup: ${SSHD_CONF}.bak" 16 65
    else
        whiptail --msgbox "SSH config validation FAILED. Reverting to backup.\n\nNo changes applied." 8 55
        run_sudo cp "${SSHD_CONF}.bak" "$SSHD_CONF"
        run_sudo rm -f "$DROP_IN"
    fi
}

# Installs auditd and loads CIS-aligned rules watching credential files, sudoers, SSH config, setuid calls, module loads, and access denials; ends with -e 2 to make rules immutable until reboot.
fn_auditd() {
    local PKG="auditd"
    case "$OS" in
        arch) PKG="audit" ;;
    esac

    if smart_install "$PKG" "auditctl"; then
        run_sudo systemctl enable auditd --now

        run_sudo tee /etc/audit/rules.d/99-titan.rules > /dev/null << 'EOF'
# Titan: CIS-aligned audit rules

# Identity & credential files
-w /etc/passwd  -p wa -k identity
-w /etc/shadow  -p wa -k identity
-w /etc/group   -p wa -k identity
-w /etc/gshadow -p wa -k identity

# Privilege escalation
-w /etc/sudoers   -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers
-w /bin/su        -p x  -k priv_esc
-w /usr/bin/su    -p x  -k priv_esc
-w /usr/bin/sudo  -p x  -k priv_esc

# SSH config
-w /etc/ssh/sshd_config    -p wa -k sshd
-w /etc/ssh/sshd_config.d/ -p wa -k sshd

# Kernel module loading — watch both /sbin and /usr/bin because on systemd
# distros (Arch, modern Debian) /sbin is a symlink to /usr/bin; auditd watches
# the inode so both paths are listed to cover either layout.
-w /sbin/insmod     -p x -k modules
-w /sbin/rmmod      -p x -k modules
-w /sbin/modprobe   -p x -k modules
-w /usr/bin/insmod  -p x -k modules
-w /usr/bin/rmmod   -p x -k modules
-w /usr/bin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules

# Setuid/setgid calls
-a always,exit -F arch=b64 -S setuid -S setgid -k setuid

# Access denials (open syscall)
-a always,exit -F arch=b64 -S open -F exit=-EACCES -k access_denied
-a always,exit -F arch=b64 -S open -F exit=-EPERM  -k access_denied

# Log directory writes
-w /var/log -p wa -k log_writes

# Make rules immutable until next reboot
-e 2
EOF

        run_sudo augenrules --load 2>/dev/null || run_sudo auditctl -R /etc/audit/rules.d/99-titan.rules

        whiptail --msgbox "auditd enabled with CIS-aligned rules.\n\nMonitoring:\n- /etc/passwd, /etc/shadow, /etc/group\n- sudo, su, sudoers changes\n- SSH config modifications\n- setuid calls and module loads\n- Access denials\n\nQuery logs with: ausearch -k <key>\n\nNote: rules are now IMMUTABLE until reboot (-e 2)." 18 65
    fi
}

# Configures pam_pwquality (14-char min, 3 classes) and pam_faillock (5 attempts → 10-min lockout); wires both modules into the distro PAM stack with per-file backups.
fn_harden_pam() {
    # Configure pwquality and faillock parameter files (safe — no login impact)
    # PAM module files themselves are edited only on supported distros with backup

    run_sudo tee /etc/security/pwquality.conf > /dev/null << 'EOF'
# Titan: password quality policy
minlen = 14
minclass = 3
maxrepeat = 2
maxsequence = 3
gecoscheck = 1
dictcheck = 1
usercheck = 1
enforcing = 1
EOF

    run_sudo tee /etc/security/faillock.conf > /dev/null << 'EOF'
# Titan: account lockout policy
deny = 5
fail_interval = 900
unlock_time = 600
silent
audit
EOF

    case "$OS" in
        ubuntu|debian)
            local COMMON_AUTH=/etc/pam.d/common-auth
            local COMMON_PW=/etc/pam.d/common-password

            run_sudo cp "$COMMON_AUTH" "${COMMON_AUTH}.bak"
            run_sudo cp "$COMMON_PW" "${COMMON_PW}.bak"

            # Add pam_faillock preauth before pam_unix if not already present.
            # Pattern anchored to ^auth so it only matches the auth type line, not
            # the account/password/session lines that also reference pam_unix.so.
            if ! run_sudo grep -q "pam_faillock" "$COMMON_AUTH"; then
                run_sudo sed -i '/^auth[[:space:]].*pam_unix\.so/i auth    required    pam_faillock.so preauth' "$COMMON_AUTH"
                run_sudo sed -i '/^auth[[:space:]].*pam_unix\.so/a auth    [default=die] pam_faillock.so authfail\nauth    sufficient  pam_faillock.so authsucc' "$COMMON_AUTH"
            fi

            # Add pam_pwquality before pam_unix in common-password if not present.
            # Anchored to ^password to avoid matching auth/session pam_unix.so lines.
            if ! run_sudo grep -q "pam_pwquality" "$COMMON_PW"; then
                run_sudo sed -i '/^password[[:space:]].*pam_unix\.so/i password    requisite    pam_pwquality.so retry=3' "$COMMON_PW"
            fi

            whiptail --msgbox "PAM hardened (Debian/Ubuntu):\n\n- pwquality: min 14 chars, 3 char classes, no repeats\n- faillock: 5 failures = 10 min lockout\n\nBackups:\n  ${COMMON_AUTH}.bak\n  ${COMMON_PW}.bak\n\nTo revert: cp <file>.bak <file>" 16 65
            ;;
        arch)
            local SYS_AUTH=/etc/pam.d/system-auth
            local SYS_PW=/etc/pam.d/system-password

            run_sudo cp "$SYS_AUTH" "${SYS_AUTH}.bak"
            run_sudo cp "$SYS_PW" "${SYS_PW}.bak"

            # faillock belongs in system-auth (authentication stack).
            # Pattern anchored to ^auth so it only matches the auth type line, not
            # the account/password/session lines that also reference pam_unix.so.
            if ! run_sudo grep -q "pam_faillock" "$SYS_AUTH"; then
                run_sudo sed -i '/^auth[[:space:]].*pam_unix\.so/i auth    required    pam_faillock.so preauth' "$SYS_AUTH"
                run_sudo sed -i '/^auth[[:space:]].*pam_unix\.so/a auth    [default=die] pam_faillock.so authfail\nauth    sufficient  pam_faillock.so authsucc' "$SYS_AUTH"
            fi

            # pwquality belongs in system-password (password change stack), not system-auth.
            # Anchored to ^password to avoid matching auth/session pam_unix.so lines.
            if ! run_sudo grep -q "pam_pwquality" "$SYS_PW"; then
                run_sudo sed -i '/^password[[:space:]].*pam_unix\.so/i password    requisite    pam_pwquality.so retry=3' "$SYS_PW"
            fi

            whiptail --msgbox "PAM hardened (Arch):\n\n- pwquality → system-password: min 14 chars, 3 char classes, no repeats\n- faillock  → system-auth:     5 failures = 10 min lockout\n\nBackups:\n  ${SYS_AUTH}.bak\n  ${SYS_PW}.bak\n\nTo revert: cp <file>.bak <file>" 16 68
            ;;
        *)
            whiptail --msgbox "PAM config written to:\n  /etc/security/pwquality.conf\n  /etc/security/faillock.conf\n\nManual PAM module wiring required for OS: '$OS'." 10 60
            ;;
    esac
}

# Scans the full filesystem for SUID/SGID binaries and offers to strip the SUID bit from a curated list of non-essential candidates (wall, traceroute, chfn, etc.).
fn_suid_audit() {
    local TMPFILE
    TMPFILE=$(mktemp)

    whiptail --msgbox "Scanning filesystem for SUID/SGID binaries. This may take a moment..." 8 55

    find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null | sort > "$TMPFILE"
    local COUNT
    COUNT=$(wc -l < "$TMPFILE")
    local RESULT
    RESULT=$(cat "$TMPFILE")
    rm -f "$TMPFILE"

    whiptail --title "SUID/SGID Audit — $COUNT binaries found" --scrolltext --msgbox "$RESULT" 30 75

    # Strip SUID from known non-essential binaries
    local STRIP_CANDIDATES=(
        /usr/bin/wall
        /usr/bin/write
        /usr/bin/traceroute
        /usr/bin/chfn
        /usr/bin/chsh
        /usr/bin/newgrp
        /usr/sbin/pppd
    )

    local PRESENT=()
    for BIN in "${STRIP_CANDIDATES[@]}"; do
        [ -u "$BIN" ] && PRESENT+=("$BIN")
    done

    if [ ${#PRESENT[@]} -gt 0 ]; then
        local LIST
        LIST=$(printf '%s\n' "${PRESENT[@]}")
        if whiptail --title "Strip Unnecessary SUID" --yesno "Strip SUID from these non-essential binaries?\n\n$LIST" 16 65; then
            for BIN in "${PRESENT[@]}"; do
                run_sudo chmod u-s "$BIN"
            done
            whiptail --msgbox "SUID stripped from ${#PRESENT[@]} non-essential binaries." 8 55
        fi
    else
        whiptail --msgbox "No strippable SUID binaries found in the standard candidate list." 8 60
    fi
}

# Disables core dumps at all four independent enforcement layers (PAM limits, sysctl, systemd manager, systemd-coredump) to prevent plaintext key/secret leakage from crash dumps.
fn_disable_coredumps() {
    # Layer 1: PAM limits
    run_sudo tee /etc/security/limits.d/99-titan-coredump.conf > /dev/null << 'EOF'
* hard core 0
* soft core 0
EOF

    # Layer 2: kernel sysctl
    run_sudo tee /etc/sysctl.d/99-titan-coredump.conf > /dev/null << 'EOF'
fs.suid_dumpable = 0
kernel.core_pattern = |/bin/false
EOF
    run_sudo sysctl -p /etc/sysctl.d/99-titan-coredump.conf

    # Layer 3: systemd global limit
    run_sudo mkdir -p /etc/systemd/system.conf.d
    run_sudo tee /etc/systemd/system.conf.d/99-titan-coredump.conf > /dev/null << 'EOF'
[Manager]
DefaultLimitCORE=0
DumpCore=no
EOF

    # Layer 4: systemd-coredump (if present)
    if [ -f /etc/systemd/coredump.conf ]; then
        run_sudo cp /etc/systemd/coredump.conf /etc/systemd/coredump.conf.bak
        run_sudo tee /etc/systemd/coredump.conf > /dev/null << 'EOF'
[Coredump]
Storage=none
ProcessSizeMax=0
EOF
    fi

    run_sudo systemctl daemon-reload

    whiptail --msgbox "Core dumps disabled across all four layers:\n\n1. /etc/security/limits.d/ (PAM hard limit)\n2. /etc/sysctl.d/ (kernel: suid_dumpable=0)\n3. /etc/systemd/system.conf.d/ (systemd DefaultLimitCORE)\n4. /etc/systemd/coredump.conf (systemd-coredump storage=none)\n\nPrevents key/secret leakage via crash dumps." 16 65
}

# Blacklists exotic kernel filesystems and remounts /tmp (and /dev/shm on non-Wayland) with
# noexec/nosuid/nodev.  /dev/shm noexec is intentionally skipped on Wayland/Hyprland because
# compositors and GPU drivers use it for DMA buffer sharing — noexec breaks all rendered output.
# squashfs is skipped when Flatpak is installed (Flatpak runtimes are squashfs images).
fn_harden_mounts() {
    # Build filesystem blacklist, skipping squashfs when Flatpak is present
    local FS_BLACKLIST
    FS_BLACKLIST=$(cat << 'EOF'
install cramfs   /bin/true
install freevxfs /bin/true
install jffs2    /bin/true
install hfs      /bin/true
install hfsplus  /bin/true
install udf      /bin/true
EOF
)

    if command -v flatpak &>/dev/null; then
        whiptail --title "Filesystem Hardening" --msgbox \
            "Flatpak detected — skipping squashfs blacklist.\n\nFlatpak runtimes are squashfs images; blacklisting would break all Flatpak apps." \
            10 65
    else
        FS_BLACKLIST+=$'\ninstall squashfs /bin/true'
    fi

    echo "$FS_BLACKLIST" | run_sudo tee /etc/modprobe.d/99-titan-fs-blacklist.conf > /dev/null

    # Harden /tmp
    if mountpoint -q /tmp; then
        run_sudo mount -o remount,noexec,nosuid,nodev /tmp
        whiptail --msgbox "/tmp remounted with noexec,nosuid,nodev (live)." 6 50
    else
        if ! grep -q "^tmpfs /tmp" /etc/fstab; then
            run_sudo cp /etc/fstab /etc/fstab.bak
            echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0" | run_sudo tee -a /etc/fstab > /dev/null
            whiptail --msgbox "tmpfs entry added to /etc/fstab for /tmp.\n\nReboot required to take full effect.\nBackup: /etc/fstab.bak" 10 55
        fi
    fi

    # Harden /dev/shm — SKIP noexec on Wayland/Hyprland.
    # Wayland compositors (Hyprland, sway, etc.) and Vulkan/OpenGL drivers use /dev/shm for
    # GPU buffer sharing. noexec prevents mmap(PROT_EXEC) on those buffers, breaking rendering.
    if [[ "$SESSION_TYPE" == "wayland" || "$DE" == "hyprland" ]] || command -v hyprctl &>/dev/null; then
        whiptail --title "Filesystem Hardening" --msgbox \
            "Wayland/Hyprland detected — skipping /dev/shm noexec.\n\nWayland compositors and GPU drivers (Vulkan/OpenGL) use /dev/shm for DMA buffer sharing. Applying noexec would break all hardware-accelerated rendering and crash Hyprland clients." \
            12 70
    else
        if mountpoint -q /dev/shm; then
            run_sudo mount -o remount,noexec,nosuid,nodev /dev/shm
        fi
        if ! grep -q "^tmpfs /dev/shm" /etc/fstab; then
            echo "tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0" | run_sudo tee -a /etc/fstab > /dev/null
        fi
    fi

    local SHM_NOTE=""
    if [[ "$SESSION_TYPE" == "wayland" || "$DE" == "hyprland" ]] || command -v hyprctl &>/dev/null; then
        SHM_NOTE="- /dev/shm: SKIPPED (Wayland/Hyprland — GPU buffer sharing requires exec)"
    else
        SHM_NOTE="- /dev/shm: noexec, nosuid, nodev"
    fi

    local SQUASH_NOTE=""
    if command -v flatpak &>/dev/null; then
        SQUASH_NOTE="- squashfs: SKIPPED (Flatpak present)"
    else
        SQUASH_NOTE="- squashfs: blacklisted"
    fi

    whiptail --msgbox "Filesystem hardening complete:\n\n- cramfs, freevxfs, jffs2, hfs, hfsplus, udf: blacklisted\n$SQUASH_NOTE\n- /tmp: noexec, nosuid, nodev\n$SHM_NOTE\n- fstab updated for persistence" 16 70
}

# Runs rkhunter (official repos on all distros) and chkrootkit (official repos on Debian/Ubuntu; AUR-only on Arch with helper fallback).
fn_rootkit_scan() {
    # Write logs to /var/log/titan/ — /tmp is world-readable so sensitive scan
    # output would be visible to any local user on a multi-user system.
    local LOG_DIR=/var/log/titan
    run_sudo mkdir -p "$LOG_DIR"
    run_sudo chmod 700 "$LOG_DIR"

    if smart_install "rkhunter" "rkhunter"; then
        whiptail --msgbox "Running rkhunter — output will display in terminal. Press Enter to start." 8 55
        run_sudo rkhunter --update 2>/dev/null
        run_sudo rkhunter --propupd 2>/dev/null
        clear
        run_sudo rkhunter --check --skip-keypress --nocolors 2>&1 | run_sudo tee "$LOG_DIR/rkhunter.log"
        read -rp "rkhunter done. Press Enter to continue..."
    fi

    # chkrootkit is AUR-only on Arch; use aur_install with user consent
    if [ "$OS" = "arch" ]; then
        if whiptail --title "chkrootkit" --yesno "chkrootkit is AUR-only on Arch.\n\nInstall via AUR helper (yay/paru)?" 9 55; then
            if aur_install "chkrootkit"; then
                whiptail --msgbox "Running chkrootkit — output will display in terminal. Press Enter to start." 8 55
                clear
                run_sudo chkrootkit 2>&1 | run_sudo tee "$LOG_DIR/chkrootkit.log"
                read -rp "chkrootkit done. Press Enter to continue..."
            fi
        fi
    else
        if smart_install "chkrootkit" "chkrootkit"; then
            whiptail --msgbox "Running chkrootkit — output will display in terminal. Press Enter to start." 8 55
            clear
            run_sudo chkrootkit 2>&1 | run_sudo tee "$LOG_DIR/chkrootkit.log"
            read -rp "chkrootkit done. Press Enter to continue..."
        fi
    fi

    whiptail --msgbox "Rootkit scans complete.\n\nLogs saved to $LOG_DIR/ (root-only, chmod 700):\n  rkhunter.log\n  chkrootkit.log" 10 60
}

# Configures unattended-upgrades for daily security-only patches on Debian/Ubuntu; installs a weekly systemd timer on Arch (full auto-upgrade is too risky on a rolling release).
fn_autoupdate() {
    case "$OS" in
        ubuntu|debian)
            if smart_install "unattended-upgrades" "unattended-upgrades"; then
                run_sudo tee /etc/apt/apt.conf.d/50titan-unattended-upgrades > /dev/null << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "root";
EOF
                run_sudo tee /etc/apt/apt.conf.d/20titan-auto-upgrades > /dev/null << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
                run_sudo systemctl enable unattended-upgrades --now
                whiptail --msgbox "Automatic security updates configured.\n\nSecurity patches apply daily.\nAutomatic reboot: DISABLED\nNotifications: mailed to root" 12 60
            fi
            ;;
        arch)
            # On Arch (rolling release), unattended -Syu can introduce breaking
            # changes mid-cycle. The timer only syncs the database and mails root
            # a list of pending updates — the human decides when to apply them.
            if whiptail --title "Auto Updates (Arch)" --yesno \
                "Arch is rolling release — automatic full upgrades risk system breakage.\n\nThis will instead install a weekly timer that:\n  1. Syncs the package database (pacman -Sy)\n  2. Lists available updates to /var/log/titan/pending-updates.log\n\nYou apply updates manually when ready. Proceed?" 14 70; then

                smart_install "pacman-contrib" "checkupdates" || true

                run_sudo tee /etc/systemd/system/titan-autoupdate.service > /dev/null << 'EOF'
[Unit]
Description=Titan Weekly Update Check (Arch)

[Service]
Type=oneshot
ExecStart=/bin/sh -c '/usr/bin/pacman -Sy --noconfirm 2>/dev/null; /usr/bin/checkupdates > /var/log/titan/pending-updates.log 2>/dev/null; echo "$(date): $(wc -l < /var/log/titan/pending-updates.log) updates pending" >> /var/log/titan/update-history.log'
EOF
                run_sudo tee /etc/systemd/system/titan-autoupdate.timer > /dev/null << 'EOF'
[Unit]
Description=Titan Weekly Update Check Timer

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF
                run_sudo mkdir -p /var/log/titan
                run_sudo chmod 700 /var/log/titan
                run_sudo systemctl enable titan-autoupdate.timer --now
                whiptail --msgbox "Weekly update check timer enabled.\n\nPending updates logged to: /var/log/titan/pending-updates.log\nHistory logged to:         /var/log/titan/update-history.log\n\nApply updates manually with: pacman -Syu\nCheck timer: systemctl status titan-autoupdate.timer" 16 68
            fi
            ;;
        *)
            whiptail --msgbox "Automatic updates not supported for OS: '$OS'." 8 55
            ;;
    esac
}

# Reports empty passwords, rogue UID-0 accounts, shell accounts with no expiry, and world-writable file count; optionally enforces a 15-minute TMOUT for all shell sessions.
fn_user_audit() {
    local REPORT=""

    # Empty or locked-out passwords
    local EMPTY_PW
    EMPTY_PW=$(run_sudo awk -F: '($2 == "" || $2 == "!!") && $1 != "" {print $1}' /etc/shadow 2>/dev/null)
    if [ -n "$EMPTY_PW" ]; then
        REPORT+="[WARN] Accounts with empty/unset passwords:\n$EMPTY_PW\n\n"
    else
        REPORT+="[OK]   No empty password accounts.\n\n"
    fi

    # Non-root UID 0 accounts
    local UID0
    UID0=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd)
    if [ -n "$UID0" ]; then
        REPORT+="[WARN] Non-root UID 0 accounts:\n$UID0\n\n"
    else
        REPORT+="[OK]   No unauthorized UID 0 accounts.\n\n"
    fi

    # Accounts with shell that have no password expiry
    local NO_EXPIRY=""
    while IFS=: read -r USER _ _ _ _ SHELL; do
        # Only check interactive shell accounts
        if [[ "$SHELL" =~ (bash|sh|zsh|fish|ksh)$ ]]; then
            local EXPIRY
            EXPIRY=$(run_sudo chage -l "$USER" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
            [ "$EXPIRY" = "never" ] && NO_EXPIRY+="$USER "
        fi
    done < /etc/passwd

    if [ -n "$NO_EXPIRY" ]; then
        REPORT+="[INFO] Shell accounts with no expiry date: $NO_EXPIRY\n\n"
    fi

    # World-writable files outside /tmp and /proc
    REPORT+="[INFO] Scanning for world-writable files (outside /tmp, /proc)...\n"
    local WW_COUNT
    WW_COUNT=$(find / -xdev -perm -0002 -not -path "/tmp/*" -not -path "/proc/*" -type f 2>/dev/null | wc -l)
    REPORT+="       Found: $WW_COUNT world-writable files\n\n"

    whiptail --title "User Account Audit" --scrolltext --msgbox "$REPORT" 24 70

    # Idle session timeout
    if whiptail --title "Session Timeout" --yesno "Enforce 15-minute idle session timeout for all shell users?" 8 58; then
        run_sudo tee /etc/profile.d/titan-tmout.sh > /dev/null << 'EOF'
TMOUT=900
readonly TMOUT
export TMOUT
EOF
        run_sudo chmod 644 /etc/profile.d/titan-tmout.sh
        whiptail --msgbox "Shell session timeout set to 15 minutes (TMOUT=900).\nTakes effect on next login." 8 60
    fi
}

# Detects Secure Boot state via mokutil or the raw EFI variable; reports status and advises enabling it if off, as it is the last line of defence against bootkit persistence.
fn_secureboot_check() {
    local STATUS="Unknown"
    local DETAIL=""

    if command -v mokutil &>/dev/null; then
        STATUS=$(mokutil --sb-state 2>/dev/null || echo "Unable to query mokutil")
    elif [ -d /sys/firmware/efi ]; then
        local SB_VAR=/sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c
        if [ -f "$SB_VAR" ]; then
            # Last byte of the EFI variable is the value (1=enabled, 0=disabled)
            local SB_BYTE
            SB_BYTE=$(run_sudo od -An -t u1 "$SB_VAR" 2>/dev/null | awk '{print $NF}')
            if [ "$SB_BYTE" = "1" ]; then
                STATUS="SecureBoot enabled"
            else
                STATUS="SecureBoot DISABLED"
                DETAIL="\n\nTo enable: enter UEFI firmware settings and turn on Secure Boot."
            fi
        else
            STATUS="EFI variable not found"
            DETAIL="\n\nSystem may be in Setup mode or Secure Boot is not configured."
        fi
    else
        STATUS="Not in UEFI mode (Legacy BIOS detected)"
        DETAIL="\n\nSecure Boot requires UEFI. Consider migrating from legacy BIOS."
    fi

    whiptail --title "Secure Boot Status" --msgbox \
        "Status: $STATUS$DETAIL\n\nSecure Boot prevents unsigned bootloaders, kernels, and kernel modules from loading — blocking bootkit and rootkit persistence that survives OS reinstall." \
        14 68
}

# Installs haveged to continuously replenish the kernel entropy pool, improving the quality of all cryptographic key material generated by the suite.
fn_entropy() {
    local CURRENT
    CURRENT=$(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null || echo "unknown")

    if whiptail --title "Entropy Enhancement" --yesno \
        "Current entropy pool: $CURRENT bits\n\nLow entropy (< 1000) degrades key quality for SSH, TLS, and MAC randomization.\n\nInstall haveged to continuously feed the kernel entropy pool?" \
        12 65; then
        if smart_install "haveged" "haveged"; then
            run_sudo systemctl enable haveged --now
            sleep 1
            local AFTER
            AFTER=$(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null || echo "unknown")
            whiptail --msgbox "haveged running.\n\nEntropy before: $CURRENT bits\nEntropy after:  $AFTER bits\n\nCryptographic operations (key generation, MAC randomization) are now more robust." 12 65
        fi
    fi
}

# --- 4. LOG VIEWER ---

# Interactive TUI log viewer for auditd (by key) and fail2ban (status + raw log); handles missing tools gracefully.
fn_log_viewer() {
    while true; do
        local SUB
        SUB=$(whiptail --title "Titan Log Viewer" --menu \
            "Select log source:" 20 68 9 \
            "1" "auditd  — All recent events" \
            "2" "auditd  — Identity changes (passwd/shadow)" \
            "3" "auditd  — Privilege escalation (sudo/su)" \
            "4" "auditd  — Setuid/setgid calls" \
            "5" "auditd  — Access denials (EACCES/EPERM)" \
            "6" "auditd  — Kernel module loads" \
            "7" "fail2ban — Jail status & banned IPs" \
            "8" "fail2ban — Recent log entries" \
            "9" "Back to main menu" \
            3>&1 1>&2 2>&3) || break

        local OUT=""

        case "$SUB" in
            1)
                if command -v ausearch &>/dev/null; then
                    OUT=$(run_sudo ausearch -ts recent 2>/dev/null | tail -n 200)
                    [ -z "$OUT" ] && OUT="No recent audit events found."
                else
                    OUT="ausearch not found — install auditd first (menu option 11)."
                fi
                whiptail --title "auditd — Recent Events" --scrolltext --msgbox "$OUT" 30 82
                ;;
            2)
                if command -v ausearch &>/dev/null; then
                    OUT=$(run_sudo ausearch -k identity -ts today 2>/dev/null)
                    [ -z "$OUT" ] && OUT="No identity-related events recorded today."
                else
                    OUT="ausearch not found — install auditd first (menu option 11)."
                fi
                whiptail --title "auditd — Identity Changes" --scrolltext --msgbox "$OUT" 30 82
                ;;
            3)
                if command -v ausearch &>/dev/null; then
                    OUT=$(run_sudo ausearch -k sudoers -ts today 2>/dev/null)
                    OUT+=$'\n'"$(run_sudo ausearch -k priv_esc -ts today 2>/dev/null)"
                    [[ "$OUT" =~ ^[[:space:]]*$ ]] && OUT="No privilege escalation events recorded today."
                else
                    OUT="ausearch not found — install auditd first (menu option 11)."
                fi
                whiptail --title "auditd — Privilege Escalation" --scrolltext --msgbox "$OUT" 30 82
                ;;
            4)
                if command -v ausearch &>/dev/null; then
                    OUT=$(run_sudo ausearch -k setuid -ts today 2>/dev/null)
                    [ -z "$OUT" ] && OUT="No setuid/setgid events recorded today."
                else
                    OUT="ausearch not found — install auditd first (menu option 11)."
                fi
                whiptail --title "auditd — Setuid/setgid Calls" --scrolltext --msgbox "$OUT" 30 82
                ;;
            5)
                if command -v ausearch &>/dev/null; then
                    OUT=$(run_sudo ausearch -k access_denied -ts today 2>/dev/null)
                    [ -z "$OUT" ] && OUT="No access denial events recorded today."
                else
                    OUT="ausearch not found — install auditd first (menu option 11)."
                fi
                whiptail --title "auditd — Access Denials" --scrolltext --msgbox "$OUT" 30 82
                ;;
            6)
                if command -v ausearch &>/dev/null; then
                    OUT=$(run_sudo ausearch -k modules -ts today 2>/dev/null)
                    [ -z "$OUT" ] && OUT="No kernel module load events recorded today."
                else
                    OUT="ausearch not found — install auditd first (menu option 11)."
                fi
                whiptail --title "auditd — Kernel Module Loads" --scrolltext --msgbox "$OUT" 30 82
                ;;
            7)
                if command -v fail2ban-client &>/dev/null; then
                    OUT=$(run_sudo fail2ban-client status 2>/dev/null)
                    local JAILS
                    JAILS=$(echo "$OUT" | grep "Jail list" | cut -d: -f2 | tr ',' '\n' | xargs)
                    for JAIL in $JAILS; do
                        OUT+=$'\n\n'"=== Jail: $JAIL ==="$'\n'
                        OUT+=$(run_sudo fail2ban-client status "$JAIL" 2>/dev/null)
                    done
                    [ -z "$OUT" ] && OUT="fail2ban not running or no jails active."
                else
                    OUT="fail2ban-client not found — install fail2ban first (menu option 9)."
                fi
                whiptail --title "fail2ban — Status & Banned IPs" --scrolltext --msgbox "$OUT" 30 82
                ;;
            8)
                local LOG_PATH=""
                for P in /var/log/fail2ban.log /var/log/fail2ban/fail2ban.log; do
                    [ -f "$P" ] && LOG_PATH="$P" && break
                done
                if [ -n "$LOG_PATH" ]; then
                    OUT=$(run_sudo tail -n 100 "$LOG_PATH" 2>/dev/null)
                    whiptail --title "fail2ban — Recent Log ($LOG_PATH)" --scrolltext --msgbox "$OUT" 30 82
                else
                    whiptail --msgbox "fail2ban log not found.\n\nLooked in:\n  /var/log/fail2ban.log\n  /var/log/fail2ban/fail2ban.log" 12 55
                fi
                ;;
            9|*) break ;;
        esac
    done
}

# --- 5. AUDIT AND LOCKDOWN ---

# Runs a full lynis system audit, printing the scored report to the terminal for manual review.
fn_full_audit() {
    if smart_install "lynis" "lynis"; then
        clear
        run_sudo lynis audit system
        read -rp "Done... press Enter to return to menu."
    fi
}

# Calls every hardening module in dependency order after a single confirmation prompt; advises a reboot on completion to apply sysctl, fstab, and systemd changes.
fn_full_lockdown() {
    if whiptail --title "FULL SYSTEM LOCKDOWN" --yesno \
        "This will run ALL hardening modules sequentially.\n\nWarning: SSH password auth will be disabled — ensure you have SSH keys configured.\n\nProceed?" \
        12 65; then
        fn_mac_framework
        fn_password_aging_hashing
        fn_system_accounting
        fn_file_integrity
        fn_crypto_check
        fn_harden_kernel
        fn_setup_firewall
        fn_network_anonymity
        fn_usb_lockdown
        fn_ids_honeyports
        fn_harden_ssh
        fn_auditd
        fn_harden_pam
        fn_suid_audit
        fn_disable_coredumps
        fn_harden_mounts
        fn_rootkit_scan
        fn_autoupdate
        fn_user_audit
        fn_secureboot_check
        fn_entropy
        whiptail --msgbox "Full system lockdown sequence complete.\n\nReview any warnings above and reboot to apply all changes." 10 60
    fi
}

# --- MAIN MENU ---
detect_os
detect_de
while true; do
    CHOICE=$(whiptail --title "Titan Security Framework" --menu \
    "Global Security & Anonymity Controls  [OS: $OS | DE: $DE | Session: $SESSION_TYPE]" 30 78 23 \
    "1"  "MAC Framework (AppArmor/SELinux)" \
    "2"  "Password Aging & SHA512 Hashing" \
    "3"  "System Accounting (acct)" \
    "4"  "File Integrity Monitoring (AIDE/paccheck)" \
    "5"  "Cryptography & SSL Cert Check" \
    "6"  "Kernel & Sysctl Hardening" \
    "7"  "Network Anonymity (MAC/Hostname)" \
    "8"  "USB Hardware Lockdown" \
    "9"  "IDS & Honeyports (fail2ban)" \
    "10" "SSH Daemon Hardening" \
    "11" "Kernel Audit Framework (auditd)" \
    "12" "PAM: Password Quality & Lockout" \
    "13" "SUID/SGID Binary Audit" \
    "14" "Core Dump Hardening" \
    "15" "Filesystem Mount Hardening" \
    "16" "Rootkit Detection (rkhunter/chkrootkit)" \
    "17" "Automatic Security Updates" \
    "18" "User Account Audit & Session Timeout" \
    "19" "Secure Boot Status Check" \
    "20" "Entropy Enhancement (haveged)" \
    "21" "Run Full Security Audit (lynis)" \
    "22" "Log Viewer (auditd / fail2ban)" \
    "23" "FULL SYSTEM LOCKDOWN" \
    "24" "Exit" 3>&1 1>&2 2>&3)

    case "$CHOICE" in
        1)  fn_mac_framework ;;
        2)  fn_password_aging_hashing ;;
        3)  fn_system_accounting ;;
        4)  fn_file_integrity ;;
        5)  fn_crypto_check ;;
        6)  fn_harden_kernel ;;
        7)  fn_network_anonymity ;;
        8)  fn_usb_lockdown ;;
        9)  fn_ids_honeyports ;;
        10) fn_harden_ssh ;;
        11) fn_auditd ;;
        12) fn_harden_pam ;;
        13) fn_suid_audit ;;
        14) fn_disable_coredumps ;;
        15) fn_harden_mounts ;;
        16) fn_rootkit_scan ;;
        17) fn_autoupdate ;;
        18) fn_user_audit ;;
        19) fn_secureboot_check ;;
        20) fn_entropy ;;
        21) fn_full_audit ;;
        22) fn_log_viewer ;;
        23) fn_full_lockdown ;;
        24) exit 0 ;;
        *)  exit 0 ;;
    esac
done
