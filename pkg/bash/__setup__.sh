#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
Version='0.4.97'
Date='5/7/25'

# Global Variables
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME="${HOME:-/data/data/com.termux/files/home}"
VENV="${PREFIX%/usr}/PyEnv"
export VENV
PS1="${PS1:-'\[\e[0;31m\]\w\[\e[0m\] \[\e[0;32m\]\$\[\e[0m\] '}"
export PS1

# <!-- Snippet Functions ----->
Start () {
    local C="\033[96m"
    local Cx="\033[94m"
    local R="\033[0m"
    clear
    echo "" && echo ""
    echo -e "${C}Version: $Version   Date: $Date${R}"
    sleep 2
    echo "================================================================================================================================================================================="
    echo ""
    echo -e "${Cx}[INFO] __SETUP__ Starting...${R}"
    echo ""
    sleep 2
}

Error () {
    for txt in "$@"; do
        local C="\033[91m"
        local R="\033[0m"
        echo -e "${C}[ERROR] $txt${R}"
        echo ""
        sleep 1
    done
}

Warn () {
    for txt in "$@"; do
        local C="\033[33m"
        local R="\033[0m"
        echo -e "${C}[WARN] $txt${R}"
        echo ""
        sleep 1
    done
}

Info () {
    for txt in "$@"; do
        local C="\033[94m"
        local R="\033[0m"
        echo -e "${C}[INFO] $txt${R}"
        echo ""
        sleep 1
    done
}

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
        echo ""
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
    echo ""
}

End () {
    local C="\033[96m"
    local R="\033[0m"
    echo ""
    echo "================================================================================================================================================================================="
    echo ""
    echo -e "${C}__SETUP__ has finished${R}"
    echo ""
    Input "Press enter to exit and clear"
    clear
}

DIR () {
    at=$(pwd)
    if [ "$at" != "$1" ]; then
        if [ -d "$1" ]; then
            cd "$1" || Error "Failed to change directory to '$1'."
        else
            Error "Directory '$1' does not exist."
        fi
    fi
}

PAK () {
    local pat="$HOME/storage/documents/scripts/bash"
    case "$1" in
        "deb")
            Info "Installing Debian packages from DEB_Req.txt..."
            if [[ -f "$pat/DEB_Req.txt" ]]; then
                grep -vE '^\s*#|^\s*$' "$pat/DEB_Req.txt" | sed 's/[[:space:]]*$//' | xargs -r apt install -y
                Info "Debian packages installed successfully."
            else
                Error "DEB_Req.txt not found in $pat."
            fi
            ;;
        "tmx")
            Info "Installing Termux packages from TMX_Req.txt..."
            if [[ -f "$pat/TMX_Req.txt" ]]; then
                grep -vE '^\s*#|^\s*$' "$pat/TMX_Req.txt" | sed 's/[[:space:]]*$//' | xargs -r pkg install -y
                Info "Termux packages installed successfully."
            else
                Error "TMX_Req.txt not found in $pat."
            fi
            ;;
        "ubu")
            Info "Installing Ubuntu packages from UBU_Req.txt..."
            if [[ -f "$pat/UBU_Req.txt" ]]; then
                grep -vE '^\s*#|^\s*$' "$pat/UBU_Req.txt" | sed 's/[[:space:]]*$//' | xargs -r apt install -y
                Info "Ubuntu packages installed successfully."
            else
                Error "UBU_Req.txt not found in $pat."
            fi
            ;;
        "pip")
            Info "Installing Python packages from PIP_Req.txt..."
            if [[ -f "$pat/PIP_Req.txt" ]]; then
                grep -vE '^\s*#|^\s*$' "$pat/PIP_Req.txt" | sed 's/[[:space:]]*$//' | xargs -r pip install
                Info "Python packages installed successfully."
            else
                Error "PIP_Req.txt not found in $pat."
            fi
            ;;
        *)
            Warn "Unknown package type '$1'"
    esac
}

# <!-- Configure Termux ----->
Setup () {
    Repo() {
        Info "Selecting Repositories..."
        pkg update -y
        pkg install -y x11-repo science-repo game-repo
        pkg update -y
        Info "Repositories configured."
        Info "You must manually choose North America Repos on the next screen"
        Timer 5
        termux-change-repo
        Input "Press ENTER to continue..."
        Info "You must manually allow all permissions on the following screens"
        Timer 5
    }

Bash () {
        Bash_Bashrc () {
            Info "Setting bash.bashrc..."
            sed -i 's/^PROMPT_DIRTRIM=.*/PROMPT_DIRTRIM=0/' "$PREFIX/etc/bash.bashrc"
            FIXED_PS1="PS1='\[\e[0;31m\]\w\[\e[0m\] \[\e[0;32m\]\$\[\e[0m\] ' "
            if grep -q '^PS1=' "$PREFIX/etc/bash.bashrc"; then
                sed -i "s|^PS1=.*|$FIXED_PS1|g" "$PREFIX/etc/bash.bashrc"
            else
                echo "$FIXED_PS1" >> "$PREFIX/etc/bash.bashrc"
            fi
            echo "Welcome to Termux!" > "$PREFIX/etc/motd"
            echo "chmod +x \"$HOME/.local/bin\"/* 2>/dev/null" >> "$PREFIX/etc/bash.bashrc"
            echo 'find "$HOME/storage/documents/scripts/bash" -type f -exec cp {} "$HOME/.local/bin" \;' >> "$PREFIX/etc/bash.bashrc"
            echo 'find "$HOME/storage/documents/scripts/py" -type f -exec cp {} "$VENV/local/scripts" \;' >> "$PREFIX/etc/bash.bashrc"
            source "$PREFIX/etc/bash.bashrc"
            Info "bash.bashrc Set Successfully"
        }
    
        Bashrc () {
            Info "Setting up ~/.bashrc…"
            echo 'export FX="$HOME/storage/documents/scripts"' >> "$HOME/.bashrc"
            echo 'export TROOT="${PREFIX%/usr}"' >> "$HOME/.bashrc"
            echo 'export VENV="$TROOT/PyEnv"' >> "$HOME/.bashrc"
            mkdir -p "$HOME/.local/bin" "$HOME/.local/share/" "$HOME/.config"
            [ -f "$HOME/.lesshst" ] && rm -f "$HOME/.lesshst"
            : > "$HOME/.bash_history"
            if ! grep -qxF 'export PATH=$HOME/.local/bin:$PATH' "$HOME/.bashrc"; then
                echo 'export PATH=$HOME/.local/bin:$PATH' >> "$HOME/.bashrc"
            fi
            source "$HOME/.bashrc"
            Info "~/.bashrc updated successfully"
        }

    Bashrc
    Bash_Bashrc
}

    IDE () {
        Settings () {
            Info "Setting termux.properties settings..."
            if [ -f "$HOME/.termux/termux.properties" ]; then
                sed -i "s/^# allow-external-apps =.*/allow-external-apps = true/" "$HOME/.termux/termux.properties"
                sed -i "s/^# terminal-cursor-blink-rate =.*/terminal-cursor-blink-rate = 750/" "$HOME/.termux/termux.properties"
                sed -i "s/^# terminal-cursor-style =.*/terminal-cursor-style = block/" "$HOME/.termux/termux.properties"
            else
                mkdir -p "$HOME/.termux"
                echo "allow-external-apps = true" > "$HOME/.termux/termux.properties"
                echo "terminal-cursor-blink-rate = 750" >> "$HOME/.termux/termux.properties"
                echo "terminal-cursor-style = block" >> "$HOME/.termux/termux.properties"
                echo "bell-character = vibrate" >> "$HOME/.termux/termux.properties"
            fi
            termux-reload-settings
            Info "termux.properties Set Successfully"
        }
        SetFont () {
            if [ ! -f "$HOME/.termux/colors.properties" ]; then
                echo -n "$HOME/.termux/colors.properties"
            fi
            Info "Setting Color Scheme and Font..."
            echo "# Using default color theme." > "$HOME/.termux/colors.properties"
            termux-reload-settings
            Info "Color scheme set successfully."
        }
        
        Settings
        # SetFont
    }

    Packages () {
        Ranger () {
            Info "Configuring Ranger"
            mkdir -p "$HOME/.config/ranger"
            local rc_file="$HOME/.config/ranger/rc.conf"
            local target_line="set show_hidden True"
            if [ -f "$rc_file" ]; then
                if grep -q "^$target_line" "$rc_file"; then
                    Info "Target line already present in rc.conf"
                else
                    echo "$target_line" >> "$rc_file"
                    Info "Added target line to existing rc.conf"
                fi
            else
                Info "Attempting to create rc.conf with ranger --copy-config=rc"
                ranger --copy-config=rc
                if [ -f "$rc_file" ]; then
                    if grep -q "^$target_line" "$rc_file"; then
                        Info "Target line already present in newly created rc.conf"
                    else
                        echo "$target_line" >> "$rc_file"
                        Info "Added target line to newly created rc.conf"
                    fi
                else
                    Warn "ranger --copy-config=rc failed, manually creating rc.conf"
                    echo "# Default Ranger configuration" > "$rc_file"
                    echo "$target_line" >> "$rc_file"
                    Info "Manually created rc.conf and added target line"
                fi
            fi
        }

        PAK "tmx"
        Ranger
    }

    PyEnv () {
        Set () {
            if [[ -d "$VENV" ]]; then
                Info "Python virtual environment already exists at $VENV"
            else
                pkg install -y python
                python3 -m venv "$VENV" --prompt "VenV"
                cd "$VENV"
                source bin/activate
                python3 -m pip install --upgrade pip wheel setuptools
                PAK "pip"
                Info "Python virtual environment created and dependencies installed."
            fi
        }
        BinAct () {
            Info "Editing PyEnv bin"
            cd "$VENV/bin"
        }
        EddyEnv () {
            Info "Editing source PyEnv"
            mkdir -p "$VENV/lib/python3.12/site-packages"
        }

        Set
        BinAct
        EddyEnv
    }

    # Repo
    IDE
    Packages
    PyEnv

}


# <!-- Run ----->
Setup