#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'
Version='0.4.392'
Date='5.29.25'

# <!-- Global Variables ----->
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME="${HOME:-/data/data/com.termux/files/home}"
export VENV="${HOME}/VenV"

CACHE="${HOME}/.cache"
STATE="${CACHE}/autux-perms.state"
export SCR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# <!-- Configure Cache ----->
makkecache () {
    if [ ! -f "$STATE" ]; then
        mkdir -p "$CACHE" || { Error "Failed to create cache directory $CACHE"; Exit; }
        echo -n > "$STATE" || { Error "Failed to create state file $STATE"; Exit; }
    fi
}

setcache () {
    echo "$1=done" >> "$STATE" || Error "Failed to write to state file $STATE"
}

cache () {
    grep -q "^$1=done" "$STATE" 2>/dev/null
}

# <!-- Attempt Permissions ----->
Permiss () {
    if command -v getprop >/dev/null 2>&1; then
        USB_DEBUG=$(getprop persist.sys.usb.config | grep -q 'adb' && echo "on" || echo "off")
        if [ "$USB_DEBUG" = "on" ]; then
            Info "USB Debugging is ON"
        else
            Warn "USB Debugging is OFF"
        fi
    else
        Warn "getprop not available; cannot check USB debugging."
    fi
    if command -v getprop >/dev/null 2>&1; then
        ADB_TCP_PORT=$(getprop service.adb.tcp.port)
        : "${ADB_TCP_PORT:=}"
        if [ "$ADB_TCP_PORT" = "5555" ]; then
            Info "Wireless Debugging (ADB over TCP/IP) is ON (port 5555)"
        else
            Warn "Wireless Debugging is OFF"
        fi
    else
        Warn "getprop not available; cannot check wireless debugging."
    fi
    if ! cache "Grants"
        if [ "$USB_DEBUG" = "on" ]; then
            if [ "$ADB_TCP_PORT" = "5555" ]; then
                Info "Granting Termux Extra Permissions"
                perms=(
                    # Known to Accept #
                    READ_PHONE_STATE
                    READ_EXTERNAL_STORAGE
                    WRITE_EXTERNAL_STORAGE
                    WRITE_SECURE_SETTINGS
                    SYSTEM_ALERT_WINDOW
                    PACKAGE_USAGE_STATS

                    # Unkown Acceptance #
                    WRITE_SETTINGS
                    READ_CONTACTS
                    WRITE_CONTACTS
                    GET_ACCOUNTS
                    READ_SMS
                    RECEIVE_SMS
                    SEND_SMS
                    WRITE_SMS
                    CALL_PHONE
                    ANSWER_PHONE_CALLS
                    PROCESS_OUTGOING_CALLS
                    ADD_VOICEMAIL
                    USE_SIP
                    RECEIVE_MMS
                    RECEIVE_WAP_PUSH
                    MANAGE_EXTERNAL_STORAGE
                    ACCESS_FINE_LOCATION
                    ACCESS_COARSE_LOCATION
                    ACCESS_BACKGROUND_LOCATION
                    CAMERA
                    RECORD_AUDIO
                    CAPTURE_AUDIO_OUTPUT
                    MODIFY_AUDIO_SETTINGS
                    BLUETOOTH
                    BLUETOOTH_ADMIN
                    BLUETOOTH_CONNECT
                    BLUETOOTH_SCAN
                    BLUETOOTH_ADVERTISE
                    NFC
                    CHANGE_WIFI_STATE
                    ACCESS_WIFI_STATE
                    CHANGE_NETWORK_STATE
                    ACCESS_NETWORK_STATE
                    INTERNET
                    REQUEST_INSTALL_PACKAGES
                    WAKE_LOCK
                    FOREGROUND_SERVICE
                    BODY_SENSORS
                    BODY_SENSORS_BACKGROUND
                    ACTIVITY_RECOGNITION
                    VIBRATE
                    READ_CALENDAR
                    WRITE_CALENDAR
                    READ_CALL_LOG
                    WRITE_CALL_LOG
                    PROCESS_OUTGOING_CALLS
                    REQUEST_DELETE_PACKAGES
                    PACKAGE_USAGE_STATS
                    INSTALL_PACKAGES
                    DELETE_PACKAGES
                    GET_ACCOUNTS
                    MANAGE_ACCOUNTS
                    AUTHENTICATE_ACCOUNTS
                    USE_CREDENTIALS
                    ACCESS_NOTIFICATION_POLICY
                    READ_PROFILE
                    WRITE_PROFILE
                    READ_SOCIAL_STREAM
                    WRITE_SOCIAL_STREAM
                    READ_USER_DICTIONARY
                    WRITE_USER_DICTIONARY
                    READ_SYNC_SETTINGS
                    WRITE_SYNC_SETTINGS
                    READ_SYNC_STATS
                    READ_CLIPBOARD
                    WRITE_CLIPBOARD
                    ACCESS_SENSORS
                    ACCESS_CHECKIN_PROPERTIES
                    ACCESS_LOCATION_EXTRA_COMMANDS
                    ACCESS_MOCK_LOCATION
                    ACCESS_SURFACE_FLINGER
                    ACCESS_VR_MANAGER
                    BATTERY_STATS
                    BIND_ACCESSIBILITY_SERVICE
                    BIND_AUTOFILL_SERVICE
                    BIND_DEVICE_ADMIN
                    BIND_NOTIFICATION_LISTENER_SERVICE
                    BIND_PRINT_SERVICE
                    BIND_VPN_SERVICE
                    BIND_WALLPAPER
                    BROADCAST_PACKAGE_REMOVED
                    BROADCAST_SMS
                    BROADCAST_WAP_PUSH
                    CHANGE_CONFIGURATION
                    CLEAR_APP_CACHE
                    DISABLE_KEYGUARD
                    EXPAND_STATUS_BAR
                    GET_PACKAGE_SIZE
                    INSTALL_SHORTCUT
                    KILL_BACKGROUND_PROCESSES
                    MODIFY_PHONE_STATE
                    MOUNT_FORMAT_FILESYSTEMS
                    MOUNT_UNMOUNT_FILESYSTEMS
                    PERSISTENT_ACTIVITY
                    READ_LOGS
                    REBOOT
                    RECEIVE_BOOT_COMPLETED
                    REORDER_TASKS
                    REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                    REQUEST_PASSWORD_COMPLEXITY
                    RESTART_PACKAGES
                    SET_ALARM
                    SET_ALWAYS_FINISH
                    SET_ANIMATION_SCALE
                    SET_DEBUG_APP
                    SET_PREFERRED_APPLICATIONS
                    SET_PROCESS_LIMIT
                    SET_TIME
                    SET_TIME_ZONE
                    SET_WALLPAPER
                    SET_WALLPAPER_HINTS
                    SIGNAL_PERSISTENT_PROCESSES
                    STATUS_BAR
                    SYSTEM_OVERLAY_WINDOW
                    TRANSMIT_IR
                    UNINSTALL_SHORTCUT
                    UPDATE_DEVICE_STATS
                    USE_BIOMETRIC USE_FINGERPRINT
                    WRITE_APN_SETTINGS
                    WRITE_GSERVICES
                    WRITE_MEDIA_STORAGE
                    WRITE_OWNER_DATA
                    WRITE_SETTINGS
                    WRITE_SYNC_SETTINGS
                )
                {
                    for perm in "${perms[@]}"; do
                        if ! cache "$perm"; do
                            echo -ne "\033[36m[PERM] Granting: android.permission.${perm} ...\033[0m "
                            if adb shell pm grant com.termux android.permission.${perm} 2>/dev/null; then
                                echo -e "\033[32m[SUCCESS]\033[0m"
                                jq --arg p "$perm" '.perms.granted += [$p]' "$SCR_DIR/settings.json" > "$SCR_DIR/settings.json.tmp" && mv "$SCR_DIR/settings.json.tmp" "$SCR_DIR/settings.json"
                                setcache "$perm" && setcache "${perm}-Pass"
                            else
                                echo -e "\033[31m[FAILED]\033[0m"
                                jq --arg p "$perm" '.perms.failed += [$p]' "$SCR_DIR/settings.json" > "$SCR_DIR/settings.json.tmp" && mv "$SCR_DIR/settings.json.tmp" "$SCR_DIR/settings.json"
                                all_success=0
                                setcache "$perm" && setcache "${perm}-Fail"
                            fi
                        fi
                    done
                } || {
                    Error "An error occurred during permission granting."
                    return 1
                }
            fi
        fi
        setcache "Grants"
    fi
}

# <!-- Attempt Always Wireless Debugging
port () {
    if ! cache "5555"
        Info "Ensuring Wireless Debugging (ADB over TCP/IP) stays enabled on port 5555"
        adb shell setprop service.adb.tcp.port 5555
        adb shell stop adbd
        adb shell start adbd
        Info "Wireless Debugging *~should* now remain enabled until reboot"
        if [ "$all_success" -eq 1 ]; then
            Info "All permissions granted successfully!"
        else
            Warn "Some permissions could not be granted. Check the output above or settings.json for details."
        fi
    fi
    setcache "5555"
}

# <!-- RUNNIT ----->
setup () {
    if ! cache "Grants"; then
        Permiss
    fi
    port

}
