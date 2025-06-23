#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'
BUGS=True

# <!-- [SS-0]: Metadata ----->
Version='0.1.3'
Date='5.29.25'
Dev='AngrySatan666'

# <!-- [SS-1]: Global Variables ----->
# /1.1/ Standard
: "${PREFIX:=/data/data/com.termux/files/usr}"
: "${HOME:=/data/data/com.termux/files/home}"
: "${TMPDIR:=$PREFIX/tmp}"
# /1.2/ Autux Spec
: "${VENV:=$HOME/VenV}"
: "${LX:=$HOME/.local/bin}"
: "${PX:=$VENV/scripts}"
: "${FPy:=$HOME/storage/shared/Termux/py}"
: "${FBash:=$HOME/storage/shared/Termux/bash}"
: "${SETTINGS:=$HOME/.local/share/autux/settings}"
: "${CACHE:=$HOME/.cache/autux}"
: "${STATE:=$CACHE/autux.permiss}"
: "${SETTINGS_HASH_FILE:=$CACHE/settings.hash}"

# <!-- [SS-2]: Configure Cache ----->
makkecache () {
    if [ ! -f "$STATE" ]; then
        mkdir -p "$CACHE" || { Error "Failed to create cache directory $CACHE"; Exit; }
        echo -n > "$STATE" || { Error "Failed to create state file $STATE"; Exit; }
    fi
}

setcache () {
    echo "$1" >> "$STATE" || Error "Failed to write to state file $STATE"
}

cache () {
    grep -q "^$1" "$STATE" 2>/dev/null
}

# <!-- [SS-3]: Attempt Permissions ----->
Permiss () {
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
                for perm in "${perms[@]}"; do
                    if attempt_permission "$perm"; then
                        setcache "${perm}-Pass"
                        awk -v perm="$perm" '
                            BEGIN {added=0}
                            /^\[perms\.granted\]/ {print; getline; while($0 !~ /^\[/ && $0 != "") {print; getline}; print perm " = true"; added=1}
                            {if(!added) print}
                        ' "$PREFIX/etc/autux/autux.conf" > "$PREFIX/etc/autux/autux.conf.tmp" && mv "$PREFIX/etc/autux/autux.conf.tmp" "$PREFIX/etc/autux/autux.conf"
                    else
                        setcache "${perm}-Fail"
                        awk -v perm="$perm" '
                            BEGIN {added=0}
                            /^\[perms\.denied\]/ {print; getline; while($0 !~ /^\[/ && $0 != "") {print; getline}; print perm " = false"; added=1}
                            {if(!added) print}
                        ' "$PREFIX/etc/autux/autux.conf" > "$PREFIX/etc/autux/autux.conf.tmp" && mv "$PREFIX/etc/autux/autux.conf.tmp" "$PREFIX/etc/autux/autux.conf"
                    fi
                done
            fi
        fi
        setcache "Grants"
    fi
}

# <!-- Attempt Always Wireless Debugging
port () {
    if ! cache "5555"; then
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
setup
