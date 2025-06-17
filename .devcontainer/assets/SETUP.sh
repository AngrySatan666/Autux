#!/usr/bin/env bash

# <!-- Metadata ----->
Version='0.5.588'
Date='6.10.25'
Dev='AngrySatan666'

set -euo pipefail
IFS=$'\n\t'

# <!-- Global Variables ----->
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME="${HOME:-/data/data/com.termux/files/home}"
export VENV="${HOME}/VenV"

CACHE="${HOME}/.cache"
STATE="${CACHE}/autux.state"
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

Exit () {
    Info "REBOOT REQUIRED"
    if Cache "PERMISSIONS"; then
        Warn "Rebooting"
        Timer 5
        if command -v adb >/dev/null 2>&1; then
            adb shell monkey -p com.termux 1 >/dev/null 2>&1
            kill -9 $$
        fi
    else
        Warn "Exiting Termux"
        Timer 5
        kill -9 $$
    fi
}

End () {
    local C="\033[96m"
    local R="\033[0m"
    echo ""
    echo "================================================================================================================================================================================="
    echo ""
    echo -e "${C}__SETUP__ has finished${R}"
    echo ""
    Exit
}

# <!-- Configure Cache ----->
MakeCache () {
    if [ ! -f "$STATE" ]; then
        mkdir -p "$CACHE" || { Error "Failed to create cache directory $CACHE"; Exit; }
        echo -n > "$STATE" || { Error "Failed to create state file $STATE"; Exit; }
    fi
}

SetCache () {
    echo "$1=done" >> "$STATE" || Error "Failed to write to state file $STATE"
}

Cache () {
    grep -q "^$1=done" "$STATE" 2>/dev/null
}

# <!-- Configure Termux ----->
Repo () {
    cd "$HOME" || { Error "Failed to cd to $HOME"; Exit; }
    if ! Cache "Repo-Set"; then
        if [ ! -L "$PREFIX/etc/termux/chosen_mirrors" ]; then
            Warn "Repo-Set Not Detected" "Executing..., You must manually choose your respective repo on the next screens"
            Timer 3
            if ! command -v termux-change-repo >/dev/null 2>&1; then
                Error "termux-change-repo not found"
                Exit
            fi
            termux-change-repo || { Error "termux-change-repo failed"; Exit; }
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
    if ! Cache "Dir-Access"; then
        if [ ! -d "$HOME/storage" ]; then
            Warn "Termux storage permission not granted." "You must manually allow storage permissions on the next screen"
            Timer 5
            if ! command -v termux-setup-storage >/dev/null 2>&1; then
                Error "termux-setup-storage not found"
                Exit
            fi
            termux-setup-storage || { Error "termux-setup-storage failed"; Exit; }
            Timer 5
            if [ -d "$HOME/storage" ]; then
                Info "Storage Access Detected" "Creating Termux Folder on Local Storage"
                mkdir -p "$HOME/storage/shared/Termux/bash" || { Error "Failed to create bash folder"; Exit; }
                FBash="$HOME/storage/shared/Termux/bash"
                mkdir -p "$HOME/storage/shared/Termux/py" || { Error "Failed to create py folder"; Exit; }
                FPy="$HOME/storage/shared/Termux/py"
                SetCache "Dir-Access"
                Info "Folders and Variables Created"
            else
                Error "Storage Access not set Properly! Exiting"
                Timer 5
                Exit
            fi
        else
            Info "Storage Access Detected" "Creating Termux Folder on Local Storage"
            mkdir -p "$HOME/storage/shared/Termux/bash" || { Error "Failed to create bash folder"; Exit; }
            FBash="$HOME/storage/shared/Termux/bash"
            mkdir -p "$HOME/storage/shared/Termux/py" || { Error "Failed to create py folder"; Exit; }
            FPy="$HOME/storage/shared/Termux/py"
            SetCache "Dir-Access"
            Info "Folders and Variables Created"
        fi
    fi
    if ! Cache "Dir-LocBin"; then
        if [ ! -d "$HOME/.local/bin" ]; then
            Info "Creating HOME Executable Directory"
            mkdir -p "$HOME/.local/bin" || { Error "Failed to create .local/bin"; Exit; }
            mkdir -p "$HOME/.local/share" || { Error "Failed to create .local/share"; Exit; }
            export PATH="$HOME/.local/bin:$PATH"
            SetCache "Dir-LocBin"
            Info "Directories Created"
        fi
    fi
    if ! Cache "Dir-VenV"; then
        if [ ! -d "$VENV/scripts" ]; then
            Info "Creating the VenV/scripts Directory"
            mkdir -p "$VENV/scripts" || { Error "Failed to create VenV/scripts"; Exit; }
            VENV="$HOME/VenV"
            PX="$VENV/scripts"
            SetCache "Dir-VenV"
            Info "Folders and Variables Created"
        fi
    fi
    if ! Cache "Dir-Cfg"; then
        if [ ! -d "$HOME/.config/autux" ]; then
            Info "Creating settings.json"
            mkdir -p "$HOME/.config/autux" || { Error "Failed to create config directory"; Exit; }
            echo -n > "$HOME/.config/autux/settings.json" || { Error "Failed to create settings.json"; Exit; }
            cp -v "$SCR_DIR/settings.json" "$HOME/.config/autux/settings.json" || Error "Failed to copy $SCR_DIR/settings.json"
            SetCache "Dir-Cfg"
            Info "Settings Created"
        fi
    fi
    if ! Cache "Dir-Docs"; then
        if [ ! -d "$PREFIX/share/doc/autux" ]; then
            Info "Creating documentation..."
            mkdir -p "$PREFIX/share/doc/autux" || { Error "Failed to create documentation directory"; Exit; }
            echo -n > "$PREFIX/share/doc/autux/LICENSE"
            echo -n > "$PREFIX/share/doc/autux/copyright"
            echo -n > "$PREFIX/share/doc/autux/README.md"
            cp -av "$SCR_DIR/doc/." "$PREFIX/share/doc/autux/" || Error "Failed to copy $SCR_DIR/doc/."
            echo -n > "$PREFIX/share/doc/autux/PIP_Req.txt"
            cp "$SCR_DIR/PIP_Req.txt" "$PREFIX/share/doc/autux/PIP_Req.txt"
            echo -n > "$PREFIX/share/doc/autux/TMX_Req.txt"
            cp "$SCR_DIR/TMX_Req.txt" "$PREFIX/share/doc/autux/TMX_Req.txt"
            echo -n > "$PREFIX/share/doc/autux/settings.json"
            cp "$SCR_DIR/settings.json" "$PREFIX/share/doc/autux/settings.json"
            SetCache "Dir-Docs"
            Info "Documentation created successfully."
        fi
    fi
    if ! Cache "Dir-Etc"; then
        if [ ! -d "$PREFIX/etc/autux" ]; then
            Info "Creating Service Script Source"
            mkdir -p "$PREFIX/etc/autux" || { Error "Failed to create service script source directory"; Exit; }
            echo -n > "$PREFIX/etc/autux/session"
            cp "$SCR_DIR/session.sh" "$PREFIX/etc/autux/session"
            echo -n > "$PREFIX/etc/autux/autux"
            cp "$SCR_DIR/autux.py" "$PREFIX/etc/autux/autux"
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
    fi
    Bash-Complete () {
        if ! Cache "Deps-BashCom"; then
            if ! pkg list-installed | grep -qe 'bash-completion'; then
                Info "Installing Bash-Completion"
                pkg install bash-completion -y || { Error "Failed to install bash-completion"; Exit; }
                SetCache "Deps-ShCom"
                Info "Installation Complete"
            fi
        fi
        if ! Cache "Deps-Bashrc"; then
            Info "Enabeling Bash-Completion with bash.bashrc"
            echo "[ -f \"$PREFIX/etc/bash_completion\" ] && . \"$PREFIX/etc/bash_completion\"" >> "$PREFIX/etc/bash.bashrc"
            SetCache "Deps-Bashrc"
            Info "bash.bashrc appended"
        fi
        if ! Cache "Deps-BashDir"; then
            if [ ! -d "$PREFIX/share/bash-completion/completions" ]; then
                Warn "Completions Directory not found" "Creating"
                mkdir -p "$PREFIX/share/bash-completion/completions" || { Error "Failed to create completions dir"; Exit; }
                SetCache "Deps-BashDir"
                Info "Completions Folder created"
            fi
        fi
        if ! Cache "Deps-ComBash"; then
            if [ ! -f "$PREFIX/share/bash-completion/completions/autux" ]; then
                Info "Creating Autux Completions in Completions Directory"
                echo -n > "$PREFIX/share/bash-completion/completions/autux" || { Error "Failed to create autux completion"; Exit; }
                cp -v "$SCR_DIR/autux" "$PREFIX/share/bash-completion/completions/autux" || Error "Failed to copy $SCR_DIR/autux"
                SetCache "Deps-ComBash"
                Info "Completions Set"
            fi
        fi
        Info "Bash-Completion Configured"
        SetCache "Deps-Bash"
    }
    Ranger () {
        if ! Cache "Deps-Rng"; then
            if ! pkg list-installed | grep -qe 'ranger'; then
                Warn "Ranger not installed" "Installing now"
                pkg install ranger -y || { Error "Failed to install ranger"; Exit; }
                SetCache "Deps-Rng"
                Info "Ranger installed successfully"
            fi
        fi
        if ! Cache "Deps-RngDir"; then
            Info "Configuring Ranger"
            if [ ! -d "$HOME/.config/ranger" ]; then
                Warn "Ranger config folder not found, creating it"
                mkdir -p "$HOME/.config/ranger" || { Error "Failed to create ranger config dir"; Exit; }
                SetCache "Deps-RngDir"
                Info "Ranger config folder created"
            fi
        fi
        if ! Cache "Deps-RngConf"; then
            export rc_file="$HOME/.config/ranger/rc.conf"
            if [ ! -f "$rc_file" ]; then
                Warn "Ranger Configs not found, Attempting to create rc.conf with ranger"
                if command -v ranger >/dev/null 2>&1; then
                    ranger --copy-config=rc || Warn "ranger --copy-config=rc failed"
                fi
                if [ -f "$rc_file" ]; then
                    Info "Ranger Configs Created Successfully"
                else
                    Warn "ranger --copy-config=rc failed" "Manually creating rc.conf"
                    echo "# Default Ranger configuration" > "$rc_file" || { Error "Failed to create rc.conf"; Exit; }
                fi
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
        if ! Cache "Deps-RSet4"; then
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
                mkdir -p "$HOME/.local/share/ranger" || { Error "Failed to create ranger local share dir"; Exit; }
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
            SetCache "Deps-RngHist"
        fi
        if ! Cache "Deps-RngTag"; then
            if [ ! -f "$HOME/.local/share/ranger/tagged" ]; then
                Info "Creating Local Tagged Config File"
                echo -n > "$HOME/.local/share/ranger/tagged"
                Info "Tagged Config Created"
            fi
            SetCache "Deps-RngTag"
        fi
        if ! Cache "Deps-RGlobal"; then
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
        echo '    export FBash="$(jq -r ''.Storage.bashFolder'' "$HOME/.config/autux/settings.json")"' >> "$PREFIX/etc/bash.bashrc"
        echo '    export FPy="$(jq -r ''.Storage.pyFolder'' "$HOME/.config/autux/settings.json")"' >> "$PREFIX/etc/bash.bashrc"
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
        echo 'alias ls="ls -a"'
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
            sed -i "s/^# default-working-directory =.*/default-working-directory = "$HOME/VenV"/" "$HOME/.termux/termux.properties"
            sed -i "s/^# shortcut.create-session =.*/shortcut.create-session = ctrl + t/" "$HOME/.termux/termux.properties"
        elif [ ! -f "$HOME/.termux/termux.properties" ]; then
            mkdir -p "$HOME/.termux"
            echo "allow-external-apps = true" > "$HOME/.termux/termux.properties"
            echo "terminal-cursor-blink-rate = 750" >> "$HOME/.termux/termux.properties"
            echo "terminal-cursor-style = block" >> "$HOME/.termux/termux.properties"
            echo "bell-character = vibrate" >> "$HOME/.termux/termux.properties"
            echo "default-working-directory = $HOME/VenV" >> "$HOME/.termux/termux.properties"
            echo "shortcut.create-session = ctrl + t" >> "$HOME/.termux/termux.properties"
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
                    pkg install python -y || { Error "Failed to install python"; Exit; }
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
            mkdir -p "$VENV/scripts" || { Error "Failed to create venv/scripts"; Exit; }
            export PATH="$VENV/scripts:$PATH"
            Info "Folder made and exported to PATH"
        fi
        SetCache "PyV-Venv"
    fi
    if ! Cache "PyV-Bin"; then
        if [ ! -f "$VENV/bin/activate" ]; then
            Info "Attempting to create the VenV at $VENV"
            python3 -m venv "$VENV" --prompt "VenV" || { Error "Failed to create venv"; Exit; }
            Info "PyVenV Built"
        fi
        SetCache "PyV-Bin"
    fi
    if ! Cache "PyV-Act"; then
        if [ -f "$VENV/bin/activate" ]; then
            Info "Activating to update PIP"
            set +u
            source "$VENV/bin/activate"
            python3 -m pip install --upgrade pip wheel setuptools || { Error "Failed to upgrade pip/wheel/setuptools"; Exit; }
            Info "PIP SETUPTOOLS & WHEEL Updated"
            set -u
        fi
        SetCache "PyV-Act"
    fi
    if ! Cache "PyV-Req"; then
        Warn "Installing Deps"
        PAK "pip"
        Info "Python venv created and dependencies installed."
        SetCache "PyV-Req"
    fi
    if ! Cache "PyV-BinRX"; then
        if [ -f "$VENV/bin/activate" ]; then
            Info "Editing PyVenV bin"
            {
                echo ' '
                echo '## Autux Configs ##'
                echo 'if command -v jq >/dev/null 2>&1; then'
                echo '    export FBash="$(jq -r ''.Storage.bashFolder'' "$HOME/.config/autux/settings.json")"'
                echo '    export FPy="$(jq -r ''.Storage.pyFolder'' "$HOME/.config/autux/settings.json")"'
                echo 'else'
                echo '    export FBash="$(grep -oP '"'"'bashFolder":\s*"\K[^"]+'"'"' "$HOME/.config/autux/settings.json")"'
                echo '    export FPy="$(grep -oP '"'"'pyFolder":\s*"\K[^"]+'"'"' "$HOME/.config/autux/settings.json")"'
                echo 'fi'
                echo 'export LX="$HOME/.local/bin"'
                echo 'export PX="$HOME/VenV/scripts"'
                echo 'export VENV="$HOME/VenV"'
                echo 'cp -av "$FPy" "$PX"'
                echo 'cp -av "$FBash" "$LX"'
                echo 'export PATH="$LX:$PATH"'
                echo 'export PATH="$PX:$PATH"'
                echo 'export PATH="$PREFIX/etc/autux:$PATH"'
                echo 'find "$LX" "$PX" "$PREFIX/etc/autux" -type f -exec chmod +x {} \;'
                echo 'cd "$PX"'
            } >> "$VENV/bin/activate" || Error "Failed to append to venv activate"
            Info "VenV bin/activate configured"
        fi
        SetCache "PyV-BinRX"
    fi
    set +u
    if [ -f "$VENV/bin/activate" ]; then
        source "$VENV/bin/activate"
        Info "VenV Activation Set Successfully"
    fi
    set -u
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
    End
}

# <!-- Run ----->
Setup


## DFepracted ##

Bash () {
    # /7.1/ Dir Trim
    if ! Cache "Bash-Prompt"; then
        Info "Setting Prompt-DirTrim..."
        if grep -q '^PROMPT_DIRTRIM=' "$PREFIX/etc/bash.bashrc"; then
            sed -i 's/^PROMPT_DIRTRIM=.*/PROMPT_DIRTRIM=0/' "$PREFIX/etc/bash.bashrc" || { Error "Failed to set PROMPT_DIRTRIM"; Exit; }
        else
            echo 'PROMPT_DIRTRIM=0' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to append PROMPT_DIRTRIM"; Exit; }
        fi
        SetCache "Bash-Prompt"
    fi
    # /7.2/ Config Bash.Bash
    if ! Cache "Bash-Echo"; then
        Info "Setting Autux Configs..."
        echo ' ' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to append newline to bash.bashrc"; Exit; }
    # /7.3/ Export Variables
        echo 'export FPy="$HOME/storage/shared/Termux/py"' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to add FPy to bash.bashrc"; Exit; }
        echo 'export FBash="$HOME/storage/shared/Termux/bash"' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to add FBash to bash.bashrc"; Exit; }
        echo 'export LX="$HOME/.local/bin"' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to add LX to bash.bashrc"; Exit; }
        echo 'export PX="$HOME/VenV/scripts"' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to add PX to bash.bashrc"; Exit; }
        echo 'export VENV="$HOME/VenV"' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to add VENV to bash.bashrc"; Exit; }
    # /7.4/ Copy All from pyFolder & bashFolder
        echo 'cp -av "$FPy" "$HOME/VenV/scripts"' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to add copy command for FPy"; Exit; }
        echo 'cp -av "$FBash" "$HOME/.local/bin"' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to add copy command for FBash"; Exit; }
    # /7.5/ Add to PATH
        echo 'export PATH="$LX:$PATH"' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to add LX to PATH"; Exit; }
        echo 'export PATH="$PX:$PATH"' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to add PX to PATH"; Exit; }
    # /7.6/ Set Execution for PX and LX
        echo 'find "$LX" "$PX" "$PREFIX/etc/autux" -type f -exec chmod +x {} \;' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to add execution command for PX and LX"; Exit; }
    # /7.7/ Set History
        [ -f "$HOME/.lesshst" ] && rm -f "$HOME/.lesshst" || { Error "Failed to remove .lesshst"; Exit; }
        : > "$HOME/.bash_history" || { Error "Failed to clear .bash_history"; Exit; }
    # /7.8/ Set MOTD
        Set MOTD & History
        echo 'Welcome to Autux!' > "$PREFIX/etc/motd" || { Error "Failed to set MOTD"; Exit; }
    # /7.9/ Source Bash.Bashrc
        set +u
        source "$PREFIX/etc/bash.bashrc"
        Info "bash.bashrc Set Successfully"
        set -u
        Info "Autux Configs set in Bash.Bashrc"
    fi
    SetCache "Bash-Echo"
}
