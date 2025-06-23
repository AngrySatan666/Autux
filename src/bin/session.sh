#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'
BUGS=True

# <!-- [SS-0]: Metadata ----->
Version='0.2.1'
Date='6.16.25'
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
: "${CACHE:=$HOME/.cache/autux}"
: "${SETTINGS:=$HOME/.local/share/autux/settings}"
: "${SETTINGS_HASH_FILE:=$CACHE/settings.hash}"

# <!-- [SS-2]: SnippeType Functions ----->
# /2.1/ Console Debug
Error () {
    local C="\033[91m"
    local R="\033[0m"
    for txt in "$@"; do
        echo -e "${C}[ERROR] $txt${R}"
        echo ' '
        sleep 1
        exit 1
    done
}

Warn () {
    local C="\033[33m"
    local R="\033[0m"
    if [ "$BUGS" = "true" ]; then
        for txt in "$@"; do
            echo -e "${C}[WARN] $txt${R}"
            echo ' '
            sleep 1
        done
    fi
}

Info () {
    local C="\033[92m"
    local R="\033[0m"
    if [ "$BUGS" = "true" ]; then
        for txt in "$@"; do
            echo -e "${C}[INFO] $txt${R}"
            echo ' '
            sleep 1
        done
    fi
}
# /2.2/ Console Control
Input () {
    if [[ -n "${answer_count:-}" ]]; then
        for ((i = 1; i <= answer_count; i++)); do
            unset "answer$i"
        done
    fi
    answer_count=$#
    local i=1
    for txt in "$@"; do
        local C="\033[32m"
        local R="\033[0m"
        echo -ne "${C}[INPUT] $txt : ${R}"
        read "answer$i"
        echo ' '
        ((i++))
    done
}

Timer () {
    local C="\033[35m"
    local R="\033[0m"
    local seconds=$1
    while [ "$seconds" -gt 0 ]; do
        echo -ne "\r${C}[WAIT] Time left: ${seconds}s${R}"
        sleep 1
        ((seconds--))
    done
    echo -e "\r${C}[WAIT] Time left: 0s${R}"
    echo ' '
}

# <!-- [SS-3]: Automations ----->
# /3.1/ Export Variables
export VENV
export LX
export PX
export FPy
export FBash
# /3.2/ Add to PATH
export PATH="$LX:$PATH"
export PATH="$PX:$PATH"
# /3.3/ Copy All from FPy & FBash to PX and LX
cp -av "$FPy" "$PX"
cp -av "$FBash" "$LX"
# /3.4/ Set Execution for LX & PX
find "$LX" "$PX" -type f -exec chmod +x {} \;

# <!-- [SS-4]: History ----->
[ -f "$HOME/.lesshst" ] && rm -f "$HOME/.lesshst" || { Error "Failed to remove .lesshst"; Exit; }
: > "$HOME/.bash_history" || { Error "Failed to clear .bash_history"; Exit; }

# <!-- [SS-5]: Set Adb ----->
SetAdb () {
    # /5.1/ Check Usb Debugging
    Debug () {
        if ! Cache "Full-UsbDebug"; then
            Info "Full Install selected, proceeding with ADB setup."
            Input "Is USB Debugging enabled? *if you are unsure enter n* (y/n)"
            if [[ $answer1 =~ ^[Yy]$ ]]; then
                SetCache "Full-UsbDebug"
                export full_debug=true
                Info "USB Debugging is enabled, proceeding with ADB setup."
            elif [[ $answer1 =~ ^[Nn]$ ]]; then
                Warn "USB Debugging is not enabled. Please enable it in Developer Options."
                echo 'To Enable USB Debugging, go to Settings > About Phone > Tap Build Number 7 times'
                echo 'Go back to settings and find Developer Options > Usb Debugging > Enable '
                Timer 5
                Input "Was USB Debugging enabled? (y/n)"
                if [[ $answer1 =~ ^[Yy]$ ]]; then
                    SetCache "Full-UsbDebug"
                    export full_debug=true
                    Info "USB Debugging is now enabled, proceeding with ADB setup."
                elif [[ $answer1 =~ ^[Nn]$ ]]; then
                    Warn "USB Debugging is still not enabled. Please enable it in Developer Options."
                    export full_debug=false
                fi
            fi
        elif Cache "Full-UsbDebug"; then
            Input "Is USB Debugging enabled? (y/n)"
            if [[ $answer1 =~ ^[Yy]$ ]]; then
                export full_debug=true
                Info "USB Debugging is already enabled, proceeding with ADB setup."
            fi
        fi
    }
    # /5.2/ Check Usb Mode
    UsbMode () {
        if ! Cache "Full-UsbMode"; then
            Input "Is the default USB mode set to File Transfer? *if you are unsure enter n* (y/n)"
            if [[ $answer1 =~ ^[Yy]$ ]]; then
                Info "Default USB mode is set to File Transfer, proceeding with ADB setup."
                export full_usbmode=true
            elif [[ $answer1 =~ ^[Nn]$ ]]; then
                Warn "Default USB mode is not set to File Transfer. Please change it in Developer Options."
                echo 'To Change USB Mode, go to Settings > Developer Options > Default USB Configuration > Select File Transfer'
                Timer 5
                Input "Is the default USB mode set to File Transfer? (y/n)"
                if [[ $answer1 =~ ^[Yy]$ ]]; then
                    export full_usbmode=true
                    Info "Default USB mode is now set to File Transfer, proceeding with ADB setup."
                elif [[ $answer1 =~ ^[Nn]$ ]]; then
                    Warn "Default USB mode is still not set to File Transfer. Please change it in Developer Options."
                    export full_usbmode=false
                fi
            fi
        elif Cache "Full-UsbMode"; then
            export full_usbmode=true
            Info "Default USB mode is already set to File Transfer, proceeding with ADB setup."
        fi
    }
    # /5.3/ Check if PC Connected
    Pc () {
        Input "Is your PC connected to the device via USB? (y/n)"
        if [[ $answer1 =~ ^[Nn]$ ]]; then
            Warn "PC is not connected to the device via USB."
            echo 'Connect your PC to the device via USB and ensure USB Debugging is enabled.'
            Timer 5
            Input "Is your PC connected to the device via USB? (y/n)"
            if [[ $answer1 =~ ^[Nn]$ ]]; then
                Warn "PC is still not connected to the device via USB"
                export full_conn=false
            elif [[ $answer1 =~ ^[Yy]$ ]]; then
                export full_conn=true
                Info "PC is now connected to the device via USB, proceeding with ADB setup."
            fi
        elif [[ $answer1 =~ ^[Yy]$ ]]; then
            export full_conn=true
            Info "PC is connected to the device via USB, proceeding with ADB setup."
        fi
    }
    # /5.4/ Check if ADB is Installed
    PcAdb () {
        Input "Is ADB installed on your PC? (y/n) "
        if [[ $answer1 =~ ^[Nn]$ ]]; then
            Warn "ADB is not installed on your PC."
            echo 'Please install ADB on your PC before proceeding.'
            echo 'You can download ADB from https://developer.android.com/studio/releases/platform-tools'
            Timer 5
            Input "Is ADB installed on your PC? (y/n)"
            if [[ $answer1 =~ ^[Nn]$ ]]; then
                Warn "ADB is still not installed on your PC."
                export full_adb=false
            elif [[ $answer1 =~ ^[Yy]$ ]]; then
                export full_adb=true
                Info "ADB is now installed on your PC, proceeding with ADB setup."
            fi
        elif [[ $answer1 =~ ^[Yy]$ ]]; then
            export full_adb=true
            Info "ADB is already installed on your PC, proceeding with ADB setup."
        fi
    }
    # /5.5/ Connect ADB
    SetFull () {
        echo "Open a Terminal on Your PC and Run the Command: adb devices"
        Input "Does your device appear in the list of connected devices? (y/n) "
        if [[ $answer1 =~ ^[Yy]$ ]]; then
            echo "On your PC Terminal, Run the Command: adb tcpip 5555"
            Input "Did the command run successfully? (y/n) "
            if [[ $answer1 =~ ^[Yy]$ ]]; then
                echo "On your PC Terminal, Run the Command: adb shell ip -o -4 addr show wlan0"
                Input "Enter the IP Address shown in the output after 'inlet' *eg. 192.168.1.420* : "
                export DEVICE_IP="$answer1"
                Input "Is this correct? IP: "$DEVICE_IP" (y/n) "
                if [[ $answer1 =~ ^[Yy]$ ]]; then
                    echo "On your PC Terminal, Run the Command: adb tcpip 5555 "
                    Input "Did the command run successfully? (y/n) "
                    if [[ $answer1 =~ ^[Yy]$ ]]; then
                        Info "Termux Attempting ADB Connection"
                        adb connect "$DEVICE_IP":5555 || { Error "Failed to connect to ADB"; Exit; }
                        if adb shell getprop service.adb.tcp.port | grep -q '5555'; then
                            Info "ADB Connection Successful"
                            export full_adb_conn=true
                            tmpfile=$(mktemp)
                            jq --arg ip "$DEVICE_IP" '.IP |= (if index($ip) then . else . + [$ip] end)' "$HOME/.local/share/autux/settings" > "$tmpfile" && mv "$tmpfile" "$HOME/.local/share/autux/settings"
                            SetCache "Full-Complete"
                        else
                            Warn "ADB Connection Failed" "Please check your PC connection and try again."
                            export full_adb_conn=false
                        fi
                    elif [[ $answer1 =~ ^[Nn]$ ]]; then
                        Warn "Command failed, please check your PC connection and try again."
                    fi
                fi
            elif [[ $answer1 =~ ^[Nn]$ ]]; then
                Warn "Device not found, please check your USB connection and try again."
            fi
        fi
    }
    # /5.6/ Runnit
    if ! Cache "Full-Complete"; then
        local full_adb=false
        local full_debug=false
        local full_usbmode=false
        local full_conn=false
        local full_adb_conn=false
        Input "Do you want to Fully-Install Autux? *if yes, a USB3.0 to PC Connection is required* (y/n)"
        if [[ $answer1 =~ ^[Yy]$ ]]; then
            Debug
            if [[ $full_debug == true ]]; then
                UsbMode
            fi
            if [[ $full_usbmode == true && $full_debug == true ]]; then
                Pc
            fi
            if [[ $full_conn == true && $full_usbmode == true && $full_debug == true ]]; then
                PcAdb
            fi
            if [[ $full_adb == true && $full_conn == true && $full_usbmode == true && $full_debug == true ]]; then
                SetFull
            fi
        elif [[ $answer1 =~ ^[Nn]$ ]]; then
            Warn "Full Install not selected" "Skipping ADB setup"
            echo 'You can run this setup again later with the command: __setup__'
        fi
        if adb shell getprop service.adb.tcp.port | grep -q '5555'; then
            Info "ADB Connection Successful"
            SetCache "Full-Complete"
        else
            Warn "ADB Connection Failed" "Please check your PC connection and try again."
        fi
    fi
}

# <!-- [SS-6]: Attempt Persist ----->
Port () {
    if ! Cache "5555"; then
        Info "Ensuring Wireless Debugging (ADB over TCP/IP) stays enabled on port 5555"
        adb shell setprop service.adb.tcp.port 5555
        adb shell stop adbd
        adb shell start adbd
        Info "Wireless Debugging *~should* now remain enabled until reboot"
        if [ "${all_success:-1}" -eq 1 ]; then
            Info "All permissions granted successfully!"
        else
            Warn "Some permissions could not be granted. Check the output above or settings.json for details."
        fi
    fi
    SetCache "5555"
}

# <!-- [SS-7]: Auto Connect ----->
Attempt () {
    # /7.1/ Try all IPs from settings for ADB connection
    SETTINGS="$HOME/.local/share/autux/setting"
    if [ -f "$SETTINGS" ]; then
        IP_LIST=$(jq -r '.IP[] | select(length > 0)' "$SETTINGS")
        export success=false
        for ip in $IP_LIST; do
            Info "Trying to connect to $ip:5555 via ADB..."
            adb connect "$ip:5555" >/dev/null 2>&1
            if adb devices | grep -q "connected to $ip:5555"; then
                Info "Successfully connected to $ip:5555"
                export DEVICE_IP="$ip"
                export success=true
                break
            else
                Warn "Failed to connect to $ip:5555"
            fi
        done
        if [ "$success" = false ]; then
            Warn "Could not connect to any IPs listed in settings."
            Input "Manually Connect Now? (y/n)"
            if [[ $answer1 =~ ^[Yy]$ ]]; then
                SetAdb
            fi
        fi
        if [ "$success" = true ]; then
            Info "ADB connection established with $DEVICE_IP"
            export DEVICE_IP
            Port
        else
            Error "Failed to connect to any IPs listed in settings."
        fi
    else
        Warn "Settings file not found: $SETTINGS"
    fi
}

# <!-- [SS-7]: MOTD ----->
Motd () {
    # /6.1/ ReSet MOTD
    echo 'Welcome to Autux!' > "$PREFIX/etc/motd" || { Error "Failed to set MOTD"; Exit; }
    # /6.2/ Check ADB Access
    if adb shell getprop service.adb.tcp.port | grep -q '5555'; then
        if [ -f "$SETTINGS" ]; then
            session_attempt=$(jq -r '.["session.attempt"] // false' "$SETTINGS")
            if [ "$session_attempt" = "true" ]; then
                Attempt
                if success; then
                    echo "ADB Access ENABLED for $DEVICE_IP" >> "$PREFIX/etc/motd" || { Error "Failed to set MOTD"; Exit; }
                else
                    echo 'ADB Access DISABLED' >> "$PREFIX/etc/motd" || { Error "Failed to set MOTD"; Exit; }
                fi
            fi
        fi
    else
        echo 'ADB Access DISABLED' >> "$PREFIX/etc/motd" || { Error "Failed to set MOTD"; Exit; }
    fi
}

# <!-- [SS-8]: Settings ----->
apply_settings() {
    # /8.1/ Alias ls
    ls_show_all=$(jq -r '.["alias.ls.ShowAll"] // false' "$SETTINGS")
    if [ "$ls_show_all" = "true" ]; then
        alias ls='ls -a'
    fi
    # /8.2/ Alias coms enabled
    coms_enabled=$(jq -r '.["alias.coms.enabled"] // false' "$SETTINGS")
    if [ "$coms_enabled" = "true" ]; then
        mapfile -t coms < <(jq -c '.["alias.coms"][]' "$SETTINGS")
        for entry in "${coms[@]}"; do
            key=$(echo "$entry" | jq -r 'keys[0]')
            pkg=$(echo "$entry" | jq -r '.[]')
            if [ -n "$key" ] && [ -n "$pkg" ]; then
                alias "$key"="adb shell monkey -p $pkg 1"
            fi
        done
    fi
}

Settings() {
    if [ ! -f "$SETTINGS" ]; then
        Warn "Settings file not found: $SETTINGS"
        return
    fi
    current_hash=$(sha256sum "$SETTINGS" | awk '{print $1}')
    last_hash=""
    if [ -f "$SETTINGS_HASH_FILE" ]; then
        last_hash=$(cat "$SETTINGS_HASH_FILE")
    fi
    if [ "$current_hash" != "$last_hash" ]; then
        Info "Settings changed, applying updates..."
        apply_settings
        echo "$current_hash" > "$SETTINGS_HASH_FILE"
    else
        Info "Settings unchanged, skipping enforcement."
    fi
}

# <!-- [SS-9]: Autux,py Handovers ----->
NewIP () {
    if [ -f "$SETTINGS" ]; then
        Input "Enter a new IP address to add to settings (or press Enter to skip): "
        addr=$answer1
        Input "Is $addr correct? (y/n) "
        if [[ $answer1 =~ ^[Yy]$ ]]; then
            jq --arg ip "$addr" '.IP |= (if index($ip) then . else . + [$ip] end)' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
            Info "New IP address $addr added to settings."
        else
            Info "No new IP address entered, skipping."
        fi
    else
        Warn "Settings file not found: $SETTINGS"
    fi
}

NewCom () {
    if [ -f "$SETTINGS" ]; then
        Input "Enter a new command alias (e.g., 'myapp') to add to settings: "
        alias_name=$answer1
        Input "Enter the package name for $alias_name (e.g., 'com.example.myapp'): "
        package_name=$answer1
        if [ -n "$alias_name" ] && [ -n "$package_name" ]; then
            jq --arg key "$alias_name" --arg pkg "$package_name" '.["alias.coms"] += [{($key): $pkg}]' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
            Info "New command alias $alias_name added for package $package_name."
        else
            Warn "Invalid input, skipping command alias addition."
        fi
    else
        Warn "Settings file not found: $SETTINGS"
    fi
}

# <!-- [SS-10]: Main ----->
if [ "${1-}" = "--updatesettings" ]; then
    Settings
elif [ "${1-}" = "--newip" ]; then
    NewIP
    Settings
elif [ "${1-}" = "--newcom" ]; then
    NewCom
    Settings
else
    Motd
    Settings
fi
