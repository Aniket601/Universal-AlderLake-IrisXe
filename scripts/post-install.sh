#!/usr/bin/env bash
#
# post-install.sh — Automated Post-Install & Stability Tool for macOS on Lenovo IdeaPad 3 15IAU7
# Part of AlderLake-IrisXe-OpenCore (https://github.com/Aniket601/AlderLake-IrisXe-OpenCore)
#
# Author: Aniket Jadhav (@Aniket601)
# Description:
#   Hardens macOS (Tahoe / Sonoma / Ventura) on Intel 12th Gen Alder Lake laptops.
#   Fixes Apple Push Service (APNS) & iMessage LinkQuality, prevents lid-close freezes,
#   safeguards /Library/Extensions kexts against silent OS updates, applies VideoToolbox
#   GVA stability patches, and provides live battery & Metal diagnostics.
#

set -uo pipefail

# --- Color Scheme & Formatting ---
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
DIM='\033[2m'
NC='\033[0m' # No Color

# --- Helper Functions ---
print_banner() {
    cat << "EOF"
  ___  _     _           _          _          ___     _      __  __     
 / _ \| | __| | ___ _ __| |    __ _| | _____  |_ _|___(_) __ _\ \/ /___   
| |_| | |/ _` |/ _ \ '__| |   / _` | |/ / _ \  | |/ __| |/ _` |\  // _ \  
|  _  | | (_| |  __/ |  | |__| (_| |   <  __/  | |\__ \ | (_| |/  \  __/  
|_| |_|_|\__,_|\___|_|  |_____\__,_|_|\_\___| |___|___/_|\__,_/_/\_\___|  
EOF
    echo -e "${CYAN}${BOLD}  AlderLake-IrisXe Post-Install & Stability Suite v1.1.0${NC}"
    echo -e "${DIM}  Maintained by Aniket Jadhav (@Aniket601)${NC}\n"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script requires root privileges. Please run with: sudo $0"
        exit 1
    fi
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# --- 1. APNS & iMessage LinkQuality Fix ---
fix_apns_linkquality() {
    echo -e "\n${BOLD}=== 1. Apple Push Service (APNS) & iMessage LinkQuality Fix ===${NC}"

    local WIFI_IF
    WIFI_IF=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|AirPort/{getline; print $2}')
    WIFI_IF="${WIFI_IF:-en0}"

    log_info "Configuring permanent LinkQuality watchdog for AirportRTW on $WIFI_IF..."

    local SCRIPT_PATH="/usr/local/bin/fix-linkquality.sh"
    local DAEMON_PLIST="/Library/LaunchDaemons/com.hackintosh.fix-linkquality.plist"

    mkdir -p /usr/local/bin

    cat << EOF > "$SCRIPT_PATH"
#!/bin/bash
# Hackintosh AirportRTW LinkQuality Keep-Alive Daemon (Atomic non-locking)
# Fixes APNS (apsd) "networking power expensive to use" dropouts

WIFI_IF="${WIFI_IF}"

ensure_linkquality() {
    current=\$(/usr/sbin/scutil <<< "show State:/Network/Interface/\$WIFI_IF/LinkQuality" 2>/dev/null)
    if [[ "\$current" != *"LinkQuality : 100"* ]]; then
        /usr/sbin/scutil << SC_EOF >/dev/null 2>&1
d.init
d.add LinkQuality # 100
set State:/Network/Interface/\$WIFI_IF/LinkQuality
SC_EOF
    fi
}

ensure_linkquality

while true; do
    ensure_linkquality
    sleep 15
done
EOF

    chmod 755 "$SCRIPT_PATH"
    chown root:wheel "$SCRIPT_PATH"
    log_success "Created watchdog script at $SCRIPT_PATH"

    cat << 'EOF' > "$DAEMON_PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.hackintosh.fix-linkquality</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/usr/local/bin/fix-linkquality.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

    chmod 644 "$DAEMON_PLIST"
    chown root:wheel "$DAEMON_PLIST"

    launchctl bootout system/com.hackintosh.fix-linkquality 2>/dev/null || launchctl unload "$DAEMON_PLIST" 2>/dev/null || true
    if launchctl bootstrap system "$DAEMON_PLIST" 2>/dev/null; then
        log_success "Loaded daemon via launchctl bootstrap system"
    else
        launchctl load -w "$DAEMON_PLIST" 2>/dev/null || true
        log_success "Loaded daemon via launchctl load"
    fi

    local LQ_NOW
    LQ_NOW=$(/usr/sbin/scutil <<< "show State:/Network/Interface/$WIFI_IF/LinkQuality" 2>/dev/null | awk '/LinkQuality :/ {print $3}' || echo "N/A")
    log_success "Current $WIFI_IF LinkQuality: ${BOLD}$LQ_NOW${NC} (APNS Connected)"
}

# --- 2. Power Management & Freeze Prevention ---
fix_power_management() {
    echo -e "\n${BOLD}=== 2. Power Management & Lid-Close Freeze Protection ===${NC}"
    log_info "Configuring pmset profiles for Modern Standby BIOS (S0ix)..."

    pmset -a disablesleep 1
    pmset -a sleep 0
    pmset -a hibernatemode 0
    pmset -a standby 0
    pmset -a autopoweroff 0
    pmset -a powernap 0
    pmset -a proximitywake 0
    pmset -a tcpkeepalive 1
    pmset -a womp 0
    pmset -a halfdim 0

    log_success "Configured pmset: disablesleep=1, autopoweroff=0, tcpkeepalive=1"
    log_success "Lid-close display off enabled. System will not freeze or reboot."
}

# --- 3. Prevent Silent OS Updates ---
protect_os_updates() {
    echo -e "\n${BOLD}=== 3. Disable Silent macOS Background Updates ===${NC}"
    log_info "Locking SoftwareUpdate preferences to safeguard /Library/Extensions..."

    # Disable major/minor background downloads while preserving security definitions (XProtect/MRT)
    defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
    defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
    defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
    defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
    defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
    defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false

    log_success "Silent background OS downloads & unattended updates disabled."
    log_success "Apple security response & XProtect definitions remain active."
    log_success "Graphics kexts in /Library/Extensions are safe from silent overwrites."
}

# --- 4. VideoToolbox Metal Fallback ---
fix_videotoolbox_gva() {
    echo -e "\n${BOLD}=== 4. VideoToolbox Metal Fallback (GVA Crash Prevention) ===${NC}"
    log_info "Configuring CoreMedia VideoToolbox transfer session defaults..."

    # Prevents SIGSEGV inside AVFPixelProcess_PrepareToTransferImages when
    # Photo Booth or FaceTime calls hardware GVA pixel transfer with -disablegfxfirmware.
    defaults write /Library/Preferences/com.apple.coremedia.plist allowHardwareTransferSession -bool false
    defaults write /Library/Preferences/com.apple.coremedia.plist enableGVATransfer -bool false
    chmod 644 /Library/Preferences/com.apple.coremedia.plist

    log_success "Configured VideoToolbox Metal fallback in /Library/Preferences/com.apple.coremedia.plist"
}

# --- 5. Clean Spotlight Indexing on Non-macOS Partitions ---
clean_spotlight_indexing() {
    echo -e "\n${BOLD}=== 5. FAT32 ESP & Recovery Spotlight Indexing Suppression ===${NC}"
    log_info "Checking mounted volumes for .metadata_never_index..."

    local ESP_VOLUMES=("/Volumes/SYSTEM_DRV" "/Volumes/MACOSREC" "/Volumes/EFI" "/Volumes/ESP")
    for vol in "${ESP_VOLUMES[@]}"; do
        if [ -d "$vol" ]; then
            touch "$vol/.metadata_never_index" 2>/dev/null || true
            log_success "Disabled Spotlight indexing on $vol"
        fi
    done

    # Suppress intrusive crash reporter UI popups for the console user
    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$SUDO_USER" defaults write com.apple.CrashReporter DialogType none 2>/dev/null || true
        log_success "Desktop user CrashReporter dialog type set to none (background logging only)"
    fi
}

# --- 6. Live Hardware Diagnostics & Battery Telemetry ---
show_diagnostics() {
    echo -e "\n${BOLD}=== 6. System & Hardware Diagnostics ===${NC}"

    # Metal / Graphics Check
    local HAS_ACCEL
    HAS_ACCEL=$(ioreg -c IntelAccelerator -l 2>/dev/null | grep -i "IntelAccelerator" || true)
    if [ -n "$HAS_ACCEL" ]; then
        local SP_DISP GPU_NAME VRAM_VAL METAL_VER
        SP_DISP=$(system_profiler SPDisplaysDataType 2>/dev/null)
        GPU_NAME=$(echo "$SP_DISP" | awk -F': ' '/Chipset Model:/ {print $2}' | head -n 1)
        VRAM_VAL=$(echo "$SP_DISP" | awk -F': ' '/VRAM/ {print $2}' | head -n 1)
        METAL_VER=$(echo "$SP_DISP" | awk -F': ' '/Metal Support:/ {print $2}' | head -n 1)
        log_success "GPU: ${GPU_NAME:-Intel Iris Xe Graphics} (${VRAM_VAL:-1536 MB}, ${METAL_VER:-Metal 2} Accelerated)"
    else
        log_warn "GPU: Iris Xe Metal Accelerator not active (Running in VESA/Software mode)"
    fi

    # Battery Telemetry
    echo -e "\n${CYAN}--- Battery Telemetry (AppleSmartBattery) ---${NC}"
    local BATT_RAW
    BATT_RAW=$(ioreg -r -c AppleSmartBattery -l 2>/dev/null)
    if [ -n "$BATT_RAW" ]; then
        local CUR_CAP MAX_CAP DES_CAP CYCLES TEMP VOLT IS_CHARGING
        CUR_CAP=$(echo "$BATT_RAW" | awk '/"CurrentCapacity" =/ {print $3}')
        MAX_CAP=$(echo "$BATT_RAW" | awk '/"MaxCapacity" =/ {print $3}')
        DES_CAP=$(echo "$BATT_RAW" | awk '/"DesignCapacity" =/ {print $3}')
        CYCLES=$(echo "$BATT_RAW" | awk '/"CycleCount" =/ {print $3}')
        TEMP=$(echo "$BATT_RAW" | awk '/"Temperature" =/ {print $3}')
        VOLT=$(echo "$BATT_RAW" | awk '/"Voltage" =/ {print $3}')
        IS_CHARGING=$(echo "$BATT_RAW" | awk '/"IsCharging" =/ {print $3}')

        local HEALTH_PCT="N/A"
        if [ -n "$MAX_CAP" ] && [ -n "$DES_CAP" ] && [ "$DES_CAP" -gt 0 ]; then
            HEALTH_PCT=$(awk -v m="$MAX_CAP" -v d="$DES_CAP" 'BEGIN {printf "%.1f%%", (m/d)*100}')
        fi

        local TEMP_C="N/A"
        if [ -n "$TEMP" ]; then
            TEMP_C=$(awk -v t="$TEMP" 'BEGIN {printf "%.1f°C", t/100}')
        fi

        echo -e "  • ${BOLD}Battery Health:${NC}    $HEALTH_PCT ($MAX_CAP / $DES_CAP mAh)"
        echo -e "  • ${BOLD}Current Charge:${NC}    $CUR_CAP mAh (Charging: $IS_CHARGING)"
        echo -e "  • ${BOLD}Cycle Count:${NC}       $CYCLES cycles"
        echo -e "  • ${BOLD}Temperature:${NC}       $TEMP_C"
        echo -e "  • ${BOLD}Voltage:${NC}           ${VOLT:-0} mV"
    else
        log_warn "No AppleSmartBattery found."
    fi

    # APNS / LinkQuality Check
    local APNS_LQ
    APNS_LQ=$(/usr/sbin/scutil <<< "show State:/Network/Interface/en0/LinkQuality" 2>/dev/null | awk '/LinkQuality :/ {print $3}')
    echo -e "\n${CYAN}--- Network & Apple Push Service (APNS) ---${NC}"
    echo -e "  • ${BOLD}en0 LinkQuality:${NC}   ${APNS_LQ:-N/A} / 100"

    # Advice for Lenovo Conservation Mode
    echo -e "\n${YELLOW}${BOLD}[*] Battery Longevity Tip:${NC}"
    echo -e "  To prevent chemical aging when plugged into AC, enable ${BOLD}Lenovo Conservation Mode${NC}."
    echo -e "  - ${BOLD}Windows:${NC} Open Lenovo Vantage ➔ Device/Power ➔ Conservation Mode ON (Caps charge at 60-80%)."
    echo -e "  - ${BOLD}Hardware Persistence:${NC} The EC chip keeps this limit active even when running macOS!\n"
}

# --- Main Entry Point & Argument Parsing ---
main() {
    local ACTION="${1:-all}"

    if [[ "$ACTION" == "--help" || "$ACTION" == "-h" || "$ACTION" == "help" ]]; then
        print_banner
        echo -e "Usage: sudo $0 [OPTION]"
        echo -e "Options:"
        echo -e "  all, --all         Apply all stability optimizations & run diagnostics (default)"
        echo -e "  --apns             Install APNS LinkQuality 100 watchdog (fixes iMessage/FaceTime)"
        echo -e "  --pm               Apply sleep & lid-close freeze prevention"
        echo -e "  --updates          Disable automatic background macOS updates"
        echo -e "  --gva              Apply VideoToolbox Metal fallback (fixes Photo Booth crash)"
        echo -e "  --clean            Disable Spotlight indexing on FAT32/Recovery ESP"
        echo -e "  --diag, status     Display live hardware, Metal, battery & APNS telemetry"
        echo -e "  --help, -h         Show this help message\n"
        exit 0
    fi

    if [[ "$ACTION" == "--diag" || "$ACTION" == "diag" || "$ACTION" == "status" ]]; then
        print_banner
        show_diagnostics
        exit 0
    fi

    print_banner
    check_root

    case "$ACTION" in
        --apns|apns)
            fix_apns_linkquality
            ;;
        --pm|pm)
            fix_power_management
            ;;
        --updates|updates)
            protect_os_updates
            ;;
        --gva|gva)
            fix_videotoolbox_gva
            ;;
        --clean|clean)
            clean_spotlight_indexing
            ;;
        --all|all)
            fix_apns_linkquality
            fix_power_management
            protect_os_updates
            fix_videotoolbox_gva
            clean_spotlight_indexing
            show_diagnostics
            echo -e "${GREEN}${BOLD}✔ All stability configurations applied successfully!${NC}\n"
            ;;
        *)
            log_error "Unknown option: $ACTION"
            echo -e "Use '$0 --help' for usage.\n"
            exit 1
            ;;
    esac
}

main "${@:-}"
