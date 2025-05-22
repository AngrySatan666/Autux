#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'
Version='0.4.106'
Date='5.20.25'

# <!-- Global Variables ----->
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME="${HOME:-/data/data/com.termux/files/home}"
export VENV="${HOME}/VenV"

SCR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCR_DIR="${SCR}"

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
    echo "$SCR_DIR/"*
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

PAK () {
    case "$1" in
        "tmx")
            Info "Installing Termux packages from TMX_Req.txt..."
            if [[ -f "$SCR_DIR/TMX_Req.txt" ]]; then
                grep -vE '^\s*#|^\s*$' "$SCR_DIR/TMX_Req.txt" | sed 's/[[:space:]]*$//' | xargs -r pkg install -y
                pkg update && pkg upgrade -y
                Info "Termux packages installed successfully."
            else
                Error "TMX_Req.txt not found in $SCR_DIR."
            fi
            ;;
        "pip")
            Info "Installing Python packages from PIP_Req.txt..."
            if [[ -f "$SCR_DIR/PIP_Req.txt" ]]; then
                grep -vE '^\s*#|^\s*$' "$SCR_DIR/PIP_Req.txt" | sed 's/[[:space:]]*$//' | xargs -r pip install
                Info "Python packages installed successfully."
            else
                Error "PIP_Req.txt not found in $SCR_DIR."
            fi
            ;;
        *)
            Warn "Unknown package type '$1'"
    esac
}

# <!-- Configure Termux ----->
Repo () {
    cd $HOME
    if pkg list-installed | grep -qe 'x11-repo||science-repo||game-repo'; then
        Info "Repositories already configured"
    else
        Warn "Repositories not selected, installing repo pkgs"
        Warn "You must manually choose your respective repo on the next screens"
        Timer 5
        termux-change-repo
        Input "Press ENTER to continue..."
        pkg update -y
        pkg install -y x11-repo science-repo game-repo
        pkg update -y
        Info "Updating all pkgs"
        pkg update && pkg upgrade -y
        Info "Repo Selected and Packages Updated"
    fi
}

Storage () {
    if [ ! -d "$HOME/storage" ]; then
        Warn "Termux storage permission not granted." "You must manually allow storage permissions on the next screen"
        Timer 5
        termux-setup-storage
        Input "Press ENTER to continue..."
        Info "Checking Storage Access"
        if [ -d "$HOME/storage" ]; then
            Info "Storage Access Detected" "Creating Termux folder on local storage"
            mkdir -p "$HOME/storage/shared/Termux/bash"
            FBash="$HOME/storage/shared/Termux/bash"
            mkdir -p "$HOME/storage/shared/Termux/py"
            FPy="$HOME/storage/shared/Termux/py"
            Info "Folders and Variables Created"
        elif [ ! -d "$HOME/storage" ]; then
            Error "Storage Access not set Properly! Exiting"
            Timer 5
            Exit
        fi
    elif [ -d "$HOME/storage" ]; then
        Info "Storage Access Detected" "Creating Termux folder on local storage"
        mkdir -p "$HOME/storage/shared/Termux/bash"
        FBash="$HOME/storage/shared/Termux/bash"
        mkdir -p "$HOME/storage/shared/Termux/py"
        FPy="$HOME/storage/shared/Termux/py"
        Info "Folders and Variables Created"
    fi
    Info "Creating Termux Folders"
    if [ ! -d "$HOME/.local/bin" ]; then
        mkdir -p "$HOME/.local/bin"
        mkdir -p "$HOME/.local/share"
    fi
    if [ ! -d "$VENV/scripts" ]; then
        mkdir -p "$VENV/scripts"
    fi
    if [ ! -d "$HOME/.config/autux" ]; then
        mkdir -p "$HOME/.config/autux"
        echo -n > "$HOME/.config/autux/settings.json"
        cp -v "$SCR_DIR/settings.json" "$HOME/.config/autux/settings.json" || Error "Failed to copy $SCR_DIR/settings.json"
    fi
    if [ ! -d "$PREFIX/share/doc/autux" ]; then
        Info "Creating documentation..."
        mkdir -p "$PREFIX/share/doc/autux"
        echo -n > "$PREFIX/share/doc/autux/LICENSE"
        echo -n > "$PREFIX/share/doc/autux/copyright"
        echo -n > "$PREFIX/share/doc/autux/README.md"
        cp -av "$SCR_DIR/doc/." "$PREFIX/share/doc/autux/" || Error "Failed to copy $SCR_DIR/doc/."
        Info "Documentation created successfully."
    fi
    if [ ! -d "$PREFIX/etc/autux" ]; then
        mkdir -p "$PREFIX/etc/autux"
        echo -n > "$PREFIX/etc/autux/session"
        cp "$SCR_DIR/session.sh" "$PREFIX/etc/autux/session"
    fi
    Info "Folder Creation Complete"
}

# <!-- Install Packages ----->
Depends () {
    PAK "tmx"
    Bash-Complete () {
        if ! pkg list-installed | grep -qe 'bash-completion'; then
            pkg install bash-completion -y
        fi
        echo "[ -f "$PREFIX/etc/bash_completion" ] && ./$PREFIX/etc/bash_completion" >> "$PREFIX/etc/bash.bashrc"
        if [ ! -d "$PREFIX/share/bash-completion/completions" ]; then
            Warn "Completions not found" "Creating"
            mkdir -p "$PREFIX/share/bash-completion/completions"
            Info "Completions Folder created"
        fi
        if [ ! -f "$PREFIX/share/bash-competion/completions/autux" ]; then
            echo -n > "$PREFIX/share/bash-completion/completions/autux"
            cp -v "$SCR_DIR/autux" "$PREFIX/share/bash-completion/completions/autux" || Error "Failed to copy $SCR_DIR/autux"
        fi
        Info "Bash-Completion Configured"
    }
    Ranger () {
        if ! pkg list-installed | grep -qe 'ranger'; then
            Warn "Ranger not installed, Installing now"
            pkg install ranger -y
            Info "Ranger installed successfully"
        fi
        Info "Configuring Ranger"
        if [ ! -d "$HOME/.config/ranger" ]; then
            Warn "Ranger config folder not found, creating it"
            mkdir -p "$HOME/.config/ranger"
            Info "Ranger config folder created"
        fi
        if [ ! -f "$rc_file" ]; then
            Warn "Ranger Configs not found, Attempting to create rc.conf with ranger"
            ranger --copy-config=rc
            if [ -f "$rc_file" ]; then
                Info "Ranger Configs Created Successfully"
            else
                Warn "ranger --copy-config=rc failed" "Manually creating rc.conf"
                echo "# Default Ranger configuration" > "$rc_file"
            fi
        fi
        if [ -f "$rc_file" ]; then
            local rc_file="$HOME/.config/ranger/rc.conf"
            local target_line1="set show_hidden false"
            local new_line1="set show_hidden true"
            if grep -q "^$target_line1" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line1.*/$new_line1/" "$rc_file"
            elif grep -q "^$new_line1" "$rc_file"; then
                Info "Target line already present in rc.conf"
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line1" >> "$rc_file"
                Info "Added target line to existing rc.conf"
            fi
            local target_line2="set viewmode miller"
            local new_line2="# set viewmode miller"
            local target_line3="# set viewmode multipane"
            local new_line3="set viewmode multipane"
            if grep -q "^$target_line2" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line2.*/$new_line2/" "$rc_file"
                sed -i "s/^$target_line3.*/$new_line3/" "$rc_file"
            elif grep -q "^$new_line2" "$rc_file"; then
                if grep -q "^$new_line3" "$rc_file"; then
                    Info "Target line already present in rc.conf"
                fi
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line2" >> "$rc_file"
                echo "$new_line3" >> "$rc_file"
                Info "Added target line to existing rc.conf"
            fi
            local target_line4="set confirm_on_delete multiple"
            local new_line4="set confirm_on_delete always"
            if grep -q "^$target_line4" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line4.*/$new_line4/" "$rc_file"
            elif grep -q "^$new_line4" "$rc_file"; then
                Info "Target line already present in rc.conf"
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line4" >> "$rc_file"
                Info "Added target line to existing rc.conf"
            fi
            local target_line5="set draw_borders none"
            local new_line5="set draw_borders both"
            if grep -q "^$target_line5" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line5.*/$new_line5/" "$rc_file"
            elif grep -q "^$new_line5" "$rc_file"; then
                Info "Target line already present in rc.conf"
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line5" >> "$rc_file"
                Info "Added target line to existing rc.conf"
            fi
            local target_line6="set autoupdate_cumulative_size false"
            local new_line6="set autoupdate_cumulative_size true"
            if grep -q "^$target_line6" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line6.*/$new_line6/" "$rc_file"
            elif grep -q "^$new_line6" "$rc_file"; then
                Info "Target line already present in rc.conf"
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line6" >> "$rc_file"
                Info "Added target line to existing rc.conf"
            fi
            local target_line7="set wrap_scroll false"
            local new_line7="set wrap_scroll true"
            if grep -q "^$target_line7" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line7.*/$new_line7/" "$rc_file"
            elif grep -q "^$new_line7" "$rc_file"; then
                Info "Target line already present in rc.conf"
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line7" >> "$rc_file"
                Info "Added target line to existing rc.conf"
            fi
            local target_line8="set colorscheme default"
            local new_line8="set colorscheme snow"
            if grep -q "^$target_line8" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line8.*/$new_line8/" "$rc_file"
            elif grep -q "^$new_line8" "$rc_file"; then
                Info "Target line already present in rc.conf"
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line8" >> "$rc_file"
                Info "Added target line to existing rc.conf"
            fi
        fi
        # Share/boomarks/history/tagged #
        if [ ! -d "$HOME/.local/share/ranger" ]; then
            Warn "Rangers Local configs folder not found" "Creating"
            mkdir -p "$HOME/.local/share/ranger"
        fi
        if [ ! -f "$HOME/.local/share/ranger/bookmarks" ]; then
            echo "':/data/data" > "$HOME/.local/share/ranger/bookmarks"
        fi
        if [ -f "$HOME/.local/share/ranger/bookmarks" ]; then
            echo "':$VENV/scripts" >> "$HOME/.local/share/ranger/bookmarks"
            echo "':$HOME/.local/bin" >> "$HOME/.local/share/ranger/bookmarks"
            echo "':$HOME/storage/shared/Termux" >> "$HOME/.local/share/ranger/bookmarks"
        fi
        if [ ! -f "$HOME/.local/share/ranger/history" ]; then
            echo -n > "$HOME/.local/share/ranger/history"
        fi
        if [ ! -f "$HOME/.local/share/ranger/tagged" ]; then
            echo -n > "$HOME/.local/share/ranger/tagged"
        fi
        Info "Ranger Fully Configured"
    }
    Bash-Complete
    Ranger
}

# <!-- Configure Bash && Bash.Bash ---->
Bash () {
    # <!-- $PREFIX/etc/bash.bashrc ----->
    Info "Setting bash.bashrc..."
    if [ -f "$PREFIX/etc/bash.bashrc" ]; then
        if grep -q '^PROMPT_DIRTRIM=' "$PREFIX/etc/bash.bashrc"; then
            sed -i 's/^PROMPT_DIRTRIM=.*/PROMPT_DIRTRIM=0/' "$PREFIX/etc/bash.bashrc"
        else
            echo 'PROMPT_DIRTRIM=0' >> "$PREFIX/etc/bash.bashrc"
        fi
    fi
    echo "SETAUT="$HOME/.config/autux/settings.json"" >> "$PREFIX/etc/bash.bashrc"
    echo "if command -v jq >/dev/null 2>&1; then" >> "$PREFIX/etc/bash.bashrc"
    echo "export FBash="$(jq -r '.Storage.bashFolder' "$SETAUT")"" >> "$PREFIX/etc/bash.bashrc"
    echo "export FPy="$(jq -r '.Storage.pyFolder' "$SETAUT")"" >> "$PREFIX/etc/bash.bashrc"
    echo "else" >> "$PREFIX/etc/bash.bashrc"
    echo "export FBash="$(grep -oP '"bashFolder":\\s*"\\K[^"]+' "$SETAUT")"" >> "$PREFIX/etc/bash.bashrc"
    echo "export FPy="$(grep -oP '"pyFolder":\\s*"\\K[^"]+' "$SETAUT")"" >> "$PREFIX/etc/bash.bashrc"
    echo "fi" >> "$PREFIX/etc/bash.bashrc"
    echo "export LX="$HOME/.local/bin"" >> "$PREFIX/etc/bash.bashrc"
    echo "export PX="$HOME/VenV/scripts"" >> "$PREFIX/etc/bash.bashrc"
    echo "cp -av "$FPy" "$PX""
    echo "cp -av "$FBash" "$LX""
    echo "Welcome to Autux!" > "$PREFIX/etc/motd"
    [ -f "$HOME/.lesshst" ] && rm -f "$HOME/.lesshst"
    : > "$HOME/.bash_history"
    source "$PREFIX/etc/bash.bashrc"
    Info "bash.bashrc Set Successfully"
}

# <!-- Set Terminal Configs ----->
IDE () {
    # <!-- Set Properties ---->
    Info "Setting termux.properties settings..."
    if [ -f "$HOME/.termux/termux.properties" ]; then
        sed -i "s/^# allow-external-apps =.*/allow-external-apps = true/" "$HOME/.termux/termux.properties"
        sed -i "s/^# terminal-cursor-blink-rate =.*/terminal-cursor-blink-rate = 750/" "$HOME/.termux/termux.properties"
        sed -i "s/^# terminal-cursor-style =.*/terminal-cursor-style = block/" "$HOME/.termux/termux.properties"
    elif [ ! -f "$HOME/.termux/termux.properties" ]; then
        mkdir -p "$HOME/.termux"
        echo "allow-external-apps = true" > "$HOME/.termux/termux.properties"
        echo "terminal-cursor-blink-rate = 750" >> "$HOME/.termux/termux.properties"
        echo "terminal-cursor-style = block" >> "$HOME/.termux/termux.properties"
        echo "bell-character = vibrate" >> "$HOME/.termux/termux.properties"
    fi
    Info "termux.properties Set Successfully"
    # <!-- Set Font ----->
    Info "Setting Color Scheme and Font..."
    if [ ! -f "$HOME/.termux/colors.properties" ]; then
        echo -n > "$HOME/.termux/colors.properties"
        echo "# Using default color theme." > "$HOME/.termux/colors.properties"
        Info "Color scheme set to default successfully."
    fi
    termux-reload-settings
}

# <!-- Setup the PyVenV ----->
PyVenV () {
    # <!-- Create the Env ----->
    if ! pkg list-packages | grep -qe 'python'; then
        pkg install python -y
    fi
    if [[ -d "$VENV" ]]; then
        Info "Python venv folder already exists" "Converting to venv"
    elif [ ! -d "$VENV" ]; then
        Info "Creating Python venv folder" "Converting to venv"
        mkdir -p "$VENV/scripts"
        export PATH="$VENV/scripts:$PATH"
    fi
    python3 -m venv "$VENV" --prompt "VenV"
    Info "PyVenV Built, activating to install dependencies"
    source "$VENV/bin/activate"
    python3 -m pip install --upgrade pip wheel setuptools
    PAK "pip"
    Info "Python venv created and dependencies installed."
    # <!-- Set Site.customize ----->
    Info "Editing PyVenV Site-Packages"
    PYVER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    if [ -n "$PYVER" ]; then
        mkdir -p "$VENV/lib/python$PYVER/site-packages"
        cp -r "$SCR_DIR/py" "$VENV/lib/python$PYVER/site-packages/"
        "$VENV/bin/pip" install -e "$SCR_DIR/site.customize"
    fi
    Info "PyVenV Site-Packages edited"
    # <!-- Edit bin/activate ----->
    Info "Editing PyVenV bin"
    echo "cp -av "$FPy" "$PX""
    echo "cp -av "$FBash" "$LX""
}

Setup () {
    Start
    Repo
    Storage
    Depends
    Bash
    IDE
    PyVenV
    End
}

# <!-- Run ----->
echo "$SCR_DIR"
Setup
