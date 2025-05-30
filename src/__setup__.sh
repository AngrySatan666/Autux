#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'
Version='0.4.387'
Date='5.25.25'

# <!-- Global Variables ----->
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME="${HOME:-/data/data/com.termux/files/home}"
export VENV="${HOME}/VenV"

CACHE="${$HOME}/.cache"
STATE="{$CACHE}/autux.state"
export SCR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# <!-- Configure Cache ----->
MakeCache () {
    if [ ! -f "$STATE" ]; then
        mkdir -p "$CACHE"
        echo -n > "$STATE"
    fi
}

SetCache () {
    echo "$1=done" >> "$STATE"
}

Cache () {
    grep -q "^$1=done" "$CACHE_FILE" 2>/dev/null
}

# <!-- Configure Termux ----->
Repo () {
    cd $HOME
    if ! Cache "Repo-Set"; then
        if [ ! -L "$PREFIX/etc/termux/chosen_mirrors" ]; then
            Warn "Repo-Set Not Detected" "Executing..., You must manually choose your respective repo on the next screens"
            Timer 3
            termux-change-repo
            SetCache "Repo-Set"
            Info "Repo's Set"
        fi
    fi
    if ! Cache "Repo-Extras"; then
        if ! Cache "RepExt-x11"; then
            if ! pkg list-installed | grep -q 'x11-repo'; then
                Warn "Extra-Repo 'x11' Not Set, Installing..."
                pkg install -y x11-repo
                SetCache "RepExt-x11"
                Info "x11 Repo Installed"
            fi
        fi
        if ! Cache "RepExt-Sci"; then
            if ! pkg list-installed | grep -q 'science-repo'; then
                Warn "Extra-Repo 'science' Not Set, Installing..."
                pkg install -y science-repo
                SetCache "RepExt-Sci"
                Info "Science Repo Installed"
            fi
        fi
        if ! Cache "RepExt-Game"; then
            if ! pkg list-installed | grep -q 'game-repo'; then
                Warn "Extra-Repo 'game' Not Set, Installing..."
                pkg install -y game-repo
                SetCache "RepExt-Game"
                Info "Game Repo Installed"
            fi
        fi
        SetCache "Repo-Extras"
    fi
    if ! Cache "Repo-Up"; then
        Info "Updating All Packages"
        pkg update && pkg upgrade -y
        SetCache "Repo-Up"
        Info "Repo Selected and Packages Updated"
    fi
}

Storage () {
    if ! Cache "Dir-Access"
        if [ ! -d "$HOME/storage" ]; then
            Warn "Termux storage permission not granted." "You must manually allow storage permissions on the next screen"
            Timer 5
            termux-setup-storage
            Timer 5
            if [ -d "$HOME/storage" ]; then
                Info "Storage Access Detected" "Creating Termux Folder on Local Storage"
                mkdir -p "$HOME/storage/shared/Termux/bash"
                FBash="$HOME/storage/shared/Termux/bash"
                mkdir -p "$HOME/storage/shared/Termux/py"
                FPy="$HOME/storage/shared/Termux/py"
                SetCache "Dir-Access"
                Info "Folders and Variables Created"
            elif [ ! -d "$HOME/storage" ]; then
                Error "Storage Access not set Properly! Exiting"
                Timer 5
                Exit
            fi
        elif [ -d "$HOME/storage" ]; then
            Info "Storage Access Detected" "Creating Termux Folder on Local Storage"
            mkdir -p "$HOME/storage/shared/Termux/bash"
            FBash="$HOME/storage/shared/Termux/bash"
            mkdir -p "$HOME/storage/shared/Termux/py"
            FPy="$HOME/storage/shared/Termux/py"
            SetCache "Dir-Access"
            Info "Folders and Variables Created"
        fi
    fi
    if ! Cache "Dir-LocBin"
        if [ ! -d "$HOME/.local/bin" ]; then
            Info "Creating HOME Executable Directory"
            mkdir -p "$HOME/.local/bin"
            mkdir -p "$HOME/.local/share"
            export PATH="$HOME/.local/bin:$PATH"
            SetCache "Dir-LocBin"
            Info "Directories Created"
        fi
    fi
    if ! Cache "Dir-VenV"
        if [ ! -d "$VENV/scripts" ]; then
            Info "Creating the VenV/scripts Directory"
            mkdir -p "$VENV/scripts"
            VENV="$HOME/VenV"
            PX="$VENV/scripts"
            SetCache "Dir-VenV"
            Info "Folders and Variables Created"
        fi
    fi
    if ! Cache "Dir-Cfg"
        if [ ! -d "$HOME/.config/autux" ]; then
            Info "Creating settings.json"
            mkdir -p "$HOME/.config/autux"
            echo -n > "$HOME/.config/autux/settings.json"
            cp -v "$SCR_DIR/settings.json" "$HOME/.config/autux/settings.json" || Error "Failed to copy $SCR_DIR/settings.json"
            SetCache "Dir-Cfg"
            Info "Settings Created"
        fi
    fi
    if ! Cache "Dir-Docs"
        if [ ! -d "$PREFIX/share/doc/autux" ]; then
            Info "Creating documentation..."
            mkdir -p "$PREFIX/share/doc/autux"
            echo -n > "$PREFIX/share/doc/autux/LICENSE"
            echo -n > "$PREFIX/share/doc/autux/copyright"
            echo -n > "$PREFIX/share/doc/autux/README.md"
            cp -av "$SCR_DIR/doc/." "$PREFIX/share/doc/autux/" || Error "Failed to copy $SCR_DIR/doc/."
            echo -n > "$PREFIX/share/doc/autux/PIP_Req.txt"
            cp "$SCR_DIR/PIP_Req.txt" "$PREFIX/share/doc/autux/PIP_Req.txt"
            echo -n > "$PREFIX/share/doc/autux/TMX_Req.txt"
            cp "$SCR_DIR/TMX_Req.txt" "$PREFIX/share/doc/autux/TMX_Req.txt"
            echo -n > "$PREFIX/share/doc/autux/settings.json"
            cp "$SCR/settings.json" "$PREFIX/share/doc/autux/settings.json"
            SetCache "Dir-Docs"
            Info "Documentation created successfully."
        fi
    fi
    if ! Cache "Dir-Etc"
        if [ ! -d "$PREFIX/etc/autux" ]; then
            Info "Creating Service Script Source"
            mkdir -p "$PREFIX/etc/autux"
            echo -n > "$PREFIX/etc/autux/session"
            cp "$SCR_DIR/session.sh" "$PREFIX/etc/autux/session"
            echo -n > "$PREFIX/etc/autux/Autux"
            cp "$SCR_DIR/Autux.py" "$PREFIX/etc/autux/Autux"
            echo -n > "$PREFIX/etc/autux/sitecustomize.py"
            cp "$SCR_DIR/sitecustomize.py" "$PREFIX/etc/autux/sitecustomize.py"
            Info "Service Dir & Files Created"
            echo -n > "$PREFIX/etc/autux/__setup__"
            cp "$SCR_DIR/__setup__.sh" "$PREFIX/etc/autux/__setup__"
            SetCache "Dir-Etc"
        fi
    fi
    Info "Basic Storage Setup and Configuration Complete"
}

# <!-- Install Packages ----->
Depends () {
    if ! Cache "Deps-Tmx"; then
        PAK "tmx"
        SetCache "Deps-Tmx"
    Bash-Complete () {
        if ! Cache "Deps-BashCom"; then
            if ! pkg list-installed | grep -qe 'bash-completion'; then
                Info "Installing Bash-Completion"
                pkg install bash-completion -y
                SetCache "Deps-ShCom"
                Info "Installation Complete"
            fi
        fi
        if ! Cache "Deps-Bashrc"; then
            Info "Enabeling Bash-Completion with bash.bashrc"
            echo "[ -f "$PREFIX/etc/bash_completion" ] && ./$PREFIX/etc/bash_completion" >> "$PREFIX/etc/bash.bashrc"
            SetCache "Deps-Bashrc"
            Info "bash.bashrc appended"
        fi
        if ! Cache "Deps-BashDir"; then
            if [ ! -d "$PREFIX/share/bash-completion/completions" ]; then
                Warn "Completions Directory not found" "Creating"
                mkdir -p "$PREFIX/share/bash-completion/completions"
                SetCache "Deps-BashDir"
                Info "Completions Folder created"
            fi
        fi
        if ! Cache "Deps-ComBash"; then
            if [ ! -f "$PREFIX/share/bash-competion/completions/autux" ]; then
                Info "Creating Autux Completions in Completions Directory"
                echo -n > "$PREFIX/share/bash-completion/completions/autux"
                cp -v "$SCR_DIR/autux" "$PREFIX/share/bash-completion/completions/autux" || Error "Failed to copy $SCR_DIR/autux"
                SetCache "Deps-ComBash"
                Info "Completions Set"
            fi
        fi
        Info "Bash-Completion Configured"
        SetCache "Deps-Bash"
    }
    Ranger () {
        if ! Cache "Deps-Rng"
            if ! pkg list-installed | grep -qe 'ranger'; then
                Warn "Ranger not installed" "Installing now"
                pkg install ranger -y
                SetCache "Deps-Rng"
                Info "Ranger installed successfully"
            fi
        fi
        if ! Cache "Deps-RngDir"
            Info "Configuring Ranger"
            if [ ! -d "$HOME/.config/ranger" ]; then
                Warn "Ranger config folder not found, creating it"
                mkdir -p "$HOME/.config/ranger"
                SetCache "Deps-RngDir"
                Info "Ranger config folder created"
            fi
        fi
        if ! Cache "Deps-RngConf"; then
            export rc_file="$HOME/.config/ranger/rc.conf"
            if [ ! -f "$rc_file" ]; then
                Warn "Ranger Configs not found, Attempting to create rc.conf with ranger"
                ranger --copy-config=rc
                if [ -f "$rc_file" ]; then
                    Info "Ranger Configs Created Successfully"
                else
                    Warn "ranger --copy-config=rc failed" "Manually creating rc.conf"
                    echo "# Default Ranger configuration" > "$rc_file"
            fi
            SetCache "Deps-RngConf"
        fi
        if ! Cache "Deps-RSet"; then
            if [ -f "$rc_file" ]; then
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
            SetCache "Deps-RSet"
        fi
        if ! Cache "Deps-RSet2"; then
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
            SetCache "Deps-RSet2"
        fi
        if ! Cachce "Deps-RSet4"
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
            SetCache "Deps-RSet4"
        fi
        if ! Cache "Deps-RSet5"; then
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
            SetCache "Deps-RSet5"
        fi
        if ! Cache "Deps-RSet6"; then
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
            SetCache "Deps-RSet6"
        fi
        if ! Cache "Deps-RSet7"; then
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
            SetCache "Deps-RSet7"
        fi
        if ! Cache "Deps-RSet8"; then
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
            SetCache "Deps-RSet8"
        fi
        if ! Cache "Deps-RngShare"; then
            if [ ! -d "$HOME/.local/share/ranger" ]; then
                Warn "Rangers Local configs folder not found" "Manually Creating Ranger Configs file"
                mkdir -p "$HOME/.local/share/ranger"
                Info "Ranger Local Configs folder created"
            fi
            SetCache "Deps-RngShare"
        fi
        if ! Cache "Deps-RngBook"; then
            if [ ! -f "$HOME/.local/share/ranger/bookmarks" ]; then
                Warn "bookmarks file not found"
                Info "Creating Bookmarks file"
                echo "':/data/data" > "$HOME/.local/share/ranger/bookmarks"
                Info "Bookmarks file created"
            fi
            SetCache "Deps-RngBook"
        fi
        if ! Cache "Deps-RngRead"; then
            if [ -f "$HOME/.local/share/ranger/bookmarks" ]; then
                Info "Including Locations to Bookmarks File"
                echo "':$VENV/scripts" >> "$HOME/.local/share/ranger/bookmarks"
                echo "':$HOME/.local/bin" >> "$HOME/.local/share/ranger/bookmarks"
                echo "':$HOME/storage/shared/Termux" >> "$HOME/.local/share/ranger/bookmarks"
                Info "Bookmarks Set Successfully"
            fi
            SetCache "Deps-RngRead"
        fi
        if ! Cache "Deps-RngHist"; then
            if [ ! -f "$HOME/.local/share/ranger/history" ]; then
                Info "Creating Local History Config File"
                echo -n > "$HOME/.local/share/ranger/history"
                Info "History Config Created"
            fi
            SetCache "Deps-RngHist"; then
        fi
        if ! Cache "Deps-RngTag"; then
            if [ ! -f "$HOME/.local/share/ranger/tagged" ]; then
                Info "Creating Local Tagged Config File"
                echo -n > "$HOME/.local/share/ranger/tagged"
                Info "Tagged Config Created"
            fi
            SetCache "Deps-RngTag"
        fi
        if ! Cache "Deps-RGlobal"
            if ! grep -q "RANGER_LOAD_DEFAULT_RC" "$PREFIX/etc/bash.bashrc"; then
                echo 'export RANGER_LOAD_DEFAULT_RC=FALSE' >> "$PREFIX/etc/bash.bashrc"
                Info "Set RANGER_LOAD_DEFAULT_RC=FALSE in bash.bashrc"
            fi
            SetCache "Deps-RGlobal"
        fi
        Info "Ranger Fully Configured"
        SetCache "Deps-Ranger"
    }
    if ! Cache "Deps-Bash"; then
        Bash-Complete
    fi
    if ! Cache "Deps-Ranger"; then
        Ranger
    fi
}

# <!-- Configure Bash.Bash ---->
Bash () {
    if ! Cache "Bash-Prompt"; then
        Info "Setting Prompt-DirTrim..."
        if grep -q '^PROMPT_DIRTRIM=' "$PREFIX/etc/bash.bashrc"; then
            sed -i 's/^PROMPT_DIRTRIM=.*/PROMPT_DIRTRIM=0/' "$PREFIX/etc/bash.bashrc"
        else
            echo 'PROMPT_DIRTRIM=0' >> "$PREFIX/etc/bash.bashrc"
        fi
        SetCache "Bash-Prompt"
    fi
    if ! Cache "Bash-Echo"; then
        Info "Setting Autux Configs..."
        echo '## Autux Configs ##' >> "$PREFIX/etc/bash.bashrc"
        echo 'if command -v jq >/dev/null 2>&1; then' >> "$PREFIX/etc/bash.bashrc"
        echo '    export FBash="$(jq -r '.Storage.bashFolder' "$HOME/.config/autux/settings.json")"' >> "$PREFIX/etc/bash.bashrc"
        echo '    export FPy="$(jq -r '.Storage.pyFolder' "$HOME/.config/autux/settings.json")"' >> "$PREFIX/etc/bash.bashrc"
        echo 'else' >> "$PREFIX/etc/bash.bashrc"
        echo '    export FBash="$(grep -oP '"'"'bashFolder":\s*"\K[^"]+'"'"' "$HOME/.config/autux/settings.json")"' >> "$PREFIX/etc/bash.bashrc"
        echo '    export FPy="$(grep -oP '"'"'pyFolder":\s*"\K[^"]+'"'"' "$HOME/.config/autux/settings.json")"' >> "$PREFIX/etc/bash.bashrc"
        echo 'fi' >> "$PREFIX/etc/bash.bashrc"
        echo 'export LX="$HOME/.local/bin"' >> "$PREFIX/etc/bash.bashrc"
        echo 'export PX="$HOME/VenV/scripts"' >> "$PREFIX/etc/bash.bashrc"
        echo 'export VENV="$HOME/VenV"' >> "$PREFIX/etc/bash.bashrc"
        echo 'cp -av "$FPy" "$HOME/VenV/scripts"' >> "$PREFIX/etc/bash.bashrc"
        echo 'cp -av "$FBash" "$HOME/.local/bin"' >> "$PREFIX/etc/bash.bashrc"
        echo 'export PATH="$LX:$PATH"' >> "$PREFIX/etc/bash.bashrc"
        echo 'export PATH="$PX:$PATH"' >> "$PREFIX/etc/bash.bashrc"
        echo 'export PATH="$PREFIX/etc/autux:$PATH"' >> "$PREFIX/etc/bash.bashrc"
        echo 'find "$LX" "$PX" "$PREFIX/etc/autux" -type f -exec chmod +x {} \;' >> "$PREFIX/etc/bash.bashrc"
        echo 'export adbsh="None"' >> "$PREFIX/etc/bash.bashrc"
        echo 'Welcome to Autux!' > "$PREFIX/etc/motd"
        [ -f "$HOME/.lesshst" ] && rm -f "$HOME/.lesshst"
        : > "$HOME/.bash_history"
        set +u
        source "$PREFIX/etc/bash.bashrc"
        Info "bash.bashrc Set Successfully"
        set -u
        Info "Autux Configs set in Bash.Bashrc"
    fi
    SetCache "Bash-Echo"
}

# <!-- Set Terminal Configs ----->
IDE () {
    if ! Cache "IDE-Prop"; then
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
        SetCache "IDE-Prop"
    fi
    set +u
    termux-reload-settings
    set -u
}

# <!-- Setup the PyVenV ----->
PyVenV () {
    if ! Cache "PyV-Inst"; then
        if ! pkg list-packages | grep -q 'python'; then
            if ! python3 -V >/dev/null 2>&1; then
                if ! pkg list-packages | grep -q 'python3'; then
                    Warn "Python Not Installed" "Installing"
                    pkg install python -y
                    Info "Python Installed"
                fi
            fi
        fi
        SetCache "PyV-Inst"
    fi
    if ! Cache "PyV-Venv"; then
        if [[ -d "$VENV" ]]; then
            Info "Python venv folder exists"
        elif [ ! -d "$VENV" ]; then
            Info "Creating Python venv folder"
            mkdir -p "$VENV/scripts"
            export PATH="$VENV/scripts:$PATH"
            Info "Folder made and exported to PATH"
        fi
        SetCache "PyV-Venv"
    fi
    if ! Cache "PyV-Bin"; then
        if [ ! -f "$VENV/bin/activate" ]; then
            Info "Attempting to create the VenV at $VENV"
            python3 -m venv "$VENV" --prompt "VenV"
            Info "PyVenV Built"
        fi
        SetCache "PyV-Bin"
    fi
    if ! Cache "PyV-Act"; then
        if [ -f "$VENV/bin/activate" ]; then
            Info "Activating to update PIP"
            set +u
            source "$VENV/bin/activate"
            python3 -m pip install --upgrade pip wheel setuptools
            Info "PIP SETUPTOOLS & WHEEL Updated"
        fi
    fi
    if ! Cache "PyV-Req"; then
        Warn "Installing Deps"
        PAK "pip"
        Info "Python venv created and dependencies installed."
        SetCache "PyV-Req"
    fi
    if ! Cache "PyV-Site"; then
        Info "Editing PyVenV Site-Packages"
        PYVER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        if [ -n "$PYVER" ]; then
            mkdir -p "$VENV/lib/python$PYVER/site-packages"
            echo -n > "$VENV/lib/python$PYVER/site-packages/sitecustomize.py"
            cp "$SCR_DIR/sitecustomize.py" "$VENV/lib/python$PYVER/site-packages/sitecustomize.py"
        fi
        SetCache "PyV-Site"
        Info "PyVenV Site-Packages edited"
    if ! Cache "PyV-BinRX"; then
        if [ -f "$VENV/bin/activate" ]; then
            Info "Editing PyVenV bin"
            echo ' ' >> "$VENV/bin/activate"
            echo '## Autux Configs ##' >> "$VENV/bin/activate"
            echo 'if command -v jq >/dev/null 2>&1; then' >> "$VENV/bin/activate"
            echo '    export FBash="$(jq -r ''.Storage.bashFolder'' "$HOME/.config/autux/settings.json")"' >> "$VENV/bin/activate"
            echo '    export FPy="$(jq -r ''.Storage.pyFolder'' "$HOME/.config/autux/settings.json")"' >> "$VENV/bin/activate"
            echo 'else' >> "$VENV/bin/activate"
            echo '    export FBash="$(grep -oP '"'"'bashFolder":\s*"\K[^"]+'"'"' "$HOME/.config/autux/settings.json")"' >> "$VENV/bin/activate"
            echo '    export FPy="$(grep -oP '"'"'pyFolder":\s*"\K[^"]+'"'"' "$HOME/.config/autux/settings.json")"' >> "$VENV/bin/activate"
            echo 'fi' >> "$VENV/bin/activate"
            echo 'export LX="$HOME/.local/bin"' >> "$VENV/bin/activate"
            echo 'export PX="$HOME/VenV/scripts"' >> "$VENV/bin/activate"
            echo 'export VENV="$HOME/VenV"' >> "$VENV/bin/activate"
            echo 'cp -av "$FPy" "$PX"' >> "$VENV/bin/activate"
            echo 'cp -av "$FBash" "$LX"' >> "$VENV/bin/activate"
            echo 'export PATH="$LX:$PATH"' >> "$VENV/bin/activate"
            echo 'export PATH="$PX:$PATH"' >> "$VENV/bin/activate"
            echo 'export PATH="$PREFIX/etc/autux:$PATH"' >> "$VENV/bin/activate"
            echo 'find "$LX" "$PX" "$PREFIX/etc/autux" -type f -exec chmod +x {} \;' >> "$VENV/bin/activate"
            echo 'cd "$PX"' >> "$VENV/bin/activate"
            Info "VenV bin/activate configured"
        fi
        SetCache "PyV-BinRX"
    set +u
    source "$VENV/bin/activate"
    Info "VenV Activation Set Successfully"
    set -u
}

Permiss () {
     # Check USB debugging (ADB)
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
    # Check Wireless debugging (ADB over TCP/IP)
    if command -v getprop >/dev/null 2>&1; then
        ADB_TCP_PORT=$(getprop service.adb.tcp.port)
        if [ "$ADB_TCP_PORT" = "5555" ]; then
            Info "Wireless Debugging (ADB over TCP/IP) is ON (port 5555)"
        else
            Warn "Wireless Debugging is OFF"
        fi
    else
        Warn "getprop not available; cannot check wireless debugging."
    fi
    if [ "$USB_DEBUG" = "on" ]; then
        if [ "$ADB_TCP_PORT" = "5555" ]; then
            Info "Ensuring Wireless Debugging (ADB over TCP/IP) stays enabled on port 5555"
            adb shell setprop service.adb.tcp.port 5555
            adb shell stop adbd
            adb shell start adbd
            Info "Wireless Debugging should now remain enabled until reboot"
            Info "Granting Termux Extra Permissions"
            local all_success=1
            perms=(
                # Contacts/SMS/Phone
                READ_CONTACTS WRITE_CONTACTS GET_ACCOUNTS
                READ_SMS RECEIVE_SMS SEND_SMS WRITE_SMS
                READ_PHONE_STATE CALL_PHONE ANSWER_PHONE_CALLS
                PROCESS_OUTGOING_CALLS ADD_VOICEMAIL USE_SIP
                RECEIVE_MMS RECEIVE_WAP_PUSH
                # Storage/Files
                READ_EXTERNAL_STORAGE WRITE_EXTERNAL_STORAGE MANAGE_EXTERNAL_STORAGE
                # Location
                ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION ACCESS_BACKGROUND_LOCATION
                # Camera/Microphone/Media
                CAMERA RECORD_AUDIO CAPTURE_AUDIO_OUTPUT
                MODIFY_AUDIO_SETTINGS
                # Bluetooth/NFC/WiFi
                BLUETOOTH BLUETOOTH_ADMIN BLUETOOTH_CONNECT BLUETOOTH_SCAN BLUETOOTH_ADVERTISE
                NFC
                CHANGE_WIFI_STATE ACCESS_WIFI_STATE
                CHANGE_NETWORK_STATE ACCESS_NETWORK_STATE
                INTERNET
                # System/Settings
                WRITE_SETTINGS WRITE_SECURE_SETTINGS
                SYSTEM_ALERT_WINDOW REQUEST_INSTALL_PACKAGES
                WAKE_LOCK
                FOREGROUND_SERVICE
                # Sensors/Hardware
                BODY_SENSORS BODY_SENSORS_BACKGROUND
                ACTIVITY_RECOGNITION
                VIBRATE
                # Calendar
                READ_CALENDAR WRITE_CALENDAR
                # Call logs
                READ_CALL_LOG WRITE_CALL_LOG PROCESS_OUTGOING_CALLS
                # Package/Apps
                REQUEST_DELETE_PACKAGES PACKAGE_USAGE_STATS INSTALL_PACKAGES DELETE_PACKAGES
                # Device/Accounts
                GET_ACCOUNTS MANAGE_ACCOUNTS AUTHENTICATE_ACCOUNTS USE_CREDENTIALS
                # Others
                ACCESS_NOTIFICATION_POLICY
                READ_PROFILE WRITE_PROFILE
                READ_SOCIAL_STREAM WRITE_SOCIAL_STREAM
                READ_USER_DICTIONARY WRITE_USER_DICTIONARY
                READ_SYNC_SETTINGS WRITE_SYNC_SETTINGS
                READ_SYNC_STATS
                # Clipboard
                READ_CLIPBOARD WRITE_CLIPBOARD
                # Sensors
                ACCESS_SENSORS
                # Others (rarely used, but included for completeness)
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
                    echo -ne "\033[36m[PERM] Granting: android.permission.${perm} ...\033[0m "
                    if adb shell pm grant com.termux android.permission.${perm} 2>/dev/null; then
                        echo -e "\033[32m[SUCCESS]\033[0m"
                        jq --arg p "$perm" '.perms.granted += [$p]' "$SCR_DIR/settings.json" > "$SCR_DIR/settings.json.tmp" && mv "$SCR_DIR/settings.json.tmp" "$SCR_DIR/settings.json"
                    else
                        echo -e "\033[31m[FAILED]\033[0m"
                        jq --arg p "$perm" '.perms.failed += [$p]' "$SCR_DIR/settings.json" > "$SCR_DIR/settings.json.tmp" && mv "$SCR_DIR/settings.json.tmp" "$SCR_DIR/settings.json"
                        all_success=0
                    fi
                done
            } || {
                Error "An error occurred during permission granting."
                return 1
            }
            if [ "$all_success" -eq 1 ]; then
                Info "All permissions granted successfully!"
            else
                Warn "Some permissions could not be granted. Check the output above or settings.json for details."
            fi
        fi
    fi
}

Setup () {
    Start
    MakeCache
    if ! Cache "Repo"; then
        Repo
        SetCache "Repo"
    fi
    if ! Cache "Dir"; then
        Storage
        SetCache "Dir"
    fi
    if ! Cache "Deps"; then
        Depends
        SetCache "Deps"
    fi
    if ! Cache "Bash"; then
        Bash
        SetCache "Bash"
    fi
    if ! Cache "IDE"; then
        IDE
        SetCache "IDE"
    fi
    if ! Cache "PyV"; then
        PyVenV
        SetCache "PyV"
    fi
    if ! Cache "Perms"; then
        Permiss
    fi
    End
}

# <!-- Run ----->
Setup
