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

# <!-- [SS-5]: ADB Access ----->
Access () {
    # /5.1/ Check For USB Connection

}

# <!-- [SS-6]: MOTD ----->
Motd () {
    # /6.1/ ReSet MOTD
    echo 'Welcome to Autux!' > "$PREFIX/etc/motd" || { Error "Failed to set MOTD"; Exit; }
    # /6.2/ Check ADB Access
    if adb shell getprop service.adb.tcp.port | grep -q '5555'; then
        echo 'ADB Access ENABLED' >> "$PREFIX/etc/motd" || { Error "Failed to set MOTD"; Exit; }
    else
        Access
    fi
}
