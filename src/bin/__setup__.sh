#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'
BUGS=True

# <!-- [SS-0]: Metadata ----->
Version='0.1.4'
Date='6.16.25'
Dev='AngrySatan666'

# <!-- [SS-1]: Global Variables ----->
    # /1.1/ Standard
: "${PREFIX:=/data/data/com.termux/files/usr}"
: "${HOME:=/data/data/com.termux/files/home}"
: "${TMPDIR:=$PREFIX/tmp}"
    # /1.2/ Autux Spec
: "${VENV:=$HOME/VenV}"
: "${CACHE:=$HOME/.cache/autux}"
: "${STATE:=$CACHE/build.state}"
: "${LX:=$HOME/.local/bin}"
: "${PX:=$VENV/scripts}"
: "${FPy:=$HOME/storage/shared/Termux/py}"
: "${FBash:=$HOME/storage/shared/Termux/bash}"
: "${SETTINGS:=$HOME/.local/share/autux/settings}"
: "${SETTINGS_HASH_FILE:=$CACHE/settings.hash}"
    # /1.3/ Source Routing
: "${SRC_DIR:="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"}"

# <!-- [SS-2]: SnippeType Functions ----->
    # /2.1/ Console Debug
Error () {
    local C="\033[91m"
    local R="\033[0m"
    for txt in "$@"; do
        echo -e "${C}[ERROR] $txt${R}"
        echo  ' '
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

PAK () {
    case "$1" in
        "tmx")
            Info "Installing Termux packages from TMX_Req.txt..."
            if [[ -f "$SRC_DIR/TMX_Req.txt" ]]; then
                grep -vE '^\s*#|^\s*$' "$SRC_DIR/TMX_Req.txt" | sed 's/[[:space:]]*$//' | xargs -r pkg install -y
                pkg update && pkg upgrade -y
                Info "Termux packages installed successfully."
            else
                Error "TMX_Req.txt not found in $SRC_DIR."
            fi
            ;;
        "pip")
            Info "Installing Python packages from PIP_Req.txt..."
            if [[ -f "$SRC_DIR/PIP_Req.txt" ]]; then
                grep -vE '^\s*#|^\s*$' "$SRC_DIR/PIP_Req.txt" | sed 's/[[:space:]]*$//' | xargs -r pip install
                Info "Python packages installed successfully."
            else
                Error "PIP_Req.txt not found in $SRC_DIR."
            fi
            ;;
        *)
            Warn "Unknown package type '$1'"
            ;;
    esac
}
    # /2.3/ Cache Config
SetCache () {
    echo "$1" >> "$STATE" || Error "Failed to write to state file $STATE"
}

Cache () {
    grep -q "^$1" "$STATE" 2>/dev/null
}
    # /2.4/ Scripting
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

Exit () {
    Warn "REBOOT REQUIRED"
    Warn "Exiting Termux"
    Timer 5
    kill -9 $$
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

# <!-- [SS-3]: Setup Cache's ----->
CacheSet () {
    # /3.1/ Ensure Terminal at Home
    cd "$HOME" || { Error "Failed to cd to $HOME"; exit 1; }
    # /3.2/ Create Install Cache
    if [ ! -f "$STATE" ]; then
        mkdir -p "$CACHE" || { Error "Failed to Create Cache Directory '$HOME/.cache/autux'"; exit 1; }
        echo -n > "$STATE" || { Error "Failed to Create State File '$STATE'"; exit 1; }
        if [ ! -f "$STATE" ]; then
            Error "Cache State File not created"
        elif [ -f "$STATE" ]; then
            Info "Cache State File Created"
            SetCache "Cache Created"
        fi
    fi
}

# <!-- [SS-4]: Repo Selection ----->
Repo () {
    # /4.1/ Check for Repo Selection
    if ! Cache "Repo-Set"; then
        if [ ! -L "$PREFIX/etc/termux/chosen_mirrors" ]; then
            Warn "Repo-Set Not Detected" "Executing..." "You must manually choose your respective repo on the next screens"
            Timer 3
            if ! command -v termux-change-repo >/dev/null 2>&1; then
                Error "termux-change-repo not found"
            fi
            termux-change-repo || { Error "termux-change-repo failed"; exit 1; }
            Timer 5
            if [ ! -L "$PREFIX/etc/termux/chosen_mirrors" ]; then
                Error "Repo-Set not created"
            elif [ -L "$PREFIX/etc/termux/chosen_mirrors" ]; then
                SetCache "Repo-Set"
                Info "Repo-Set Successfully"
            fi
        elif [ -L "$PREFIX/etc/termux/chosen_mirrors" ]; then
            SetCache "Repo-Set"
            Info "Repo-Set Detected"
        fi
    fi
    # /4.2/ Check for Repo Extras
    if ! Cache "RepExt-x11"; then
        if ! pkg list-installed | grep -q 'x11-repo'; then
            Warn "Extra-Repo 'x11' Not Set, Installing..."
            pkg install -y x11-repo || { Error "Failed to install x11-repo"; exit 1; }
            if ! pkg list-installed | grep -q 'x11-repo'; then
                Error "x11-repo not installed"
            else
                SetCache "RepExt-x11"
                Info "x11 Repo Installed"
            fi
        elif pkg list-installed | grep -q 'x11-repo'; then
            SetCache "RepExt-x11"
            Info "x11 Repo Detected"
        fi
    fi
    # /4.3/ Update All pkg Packages
    if ! Cache "Repo-UpPkg"; then
        Info "Updating All Packages"
        pkg update && pkg upgrade -y || { Error "Failed to update packages"; exit 1; }
        SetCache "Repo-UpPkg"
        Info "pkg Packages Updated"
    fi
    # /4.4/ Update All apt Packages
    if ! Cache "Repo-UpApt"; then
        Info "Updating All apt Packages"
        apt update && apt upgrade -y || { Error "Failed to update apt packages"; exit 1; }
        SetCache "Repo-UpApt"
        Info "apt Packages Updated"
    fi
}

# <!-- [SS-5]: Storage Directory ----->
Storage () {
    # /5.1/ Docs Directory
    if ! Cache "Dir-Docs"; then
        if ! Cache "Dir-Docs/Dir"; then
            if [ ! -d "$PREFIX/share/doc/autux" ]; then
                Info "Creating Documentation..."
                mkdir -p "$PREFIX/share/doc/autux" || { Error "Failed to Create Documentation Directory"; exit 1; }
                if [ -d "$PREFIX/share/doc/autux" ]; then
                    SetCache "Dir-Docs/Dir"
                    Info "Documentation Directory Created"
                elif [ ! -d "$PREFIX/share/doc/autux" ]; then
                    Error "Documentation Directory not created"
                fi
            elif [ -d "$PREFIX/share/doc/autux" ]; then
                SetCache "Dir-Docs/Dir"
                Info "Documentation Directory Detected"
            fi
        fi
    # /5.2/ Documentation Files
        if ! Cache "Dir-Docs/Files"; then
            # /5.2.1/ Install Autux License
            if [ ! -f "$PREFIX/share/doc/autux/LICENSE" ]; then
                echo -n > "$PREFIX/share/doc/autux/LICENSE" || { Error "Failed to Create File doc/LICENSE"; exit 1; }
                cp "$SRC_DIR/doc/LICENSE" "$PREFIX/share/doc/autux/LICENSE" || { Error "Failed to copy $SRC_DIR/doc/LICENSE"; exit 1; }
            fi
            # /5.2.2/ Install Autux Copyright
            if [ ! -f "$PREFIX/share/doc/autux/copyright" ]; then
                echo -n > "$PREFIX/share/doc/autux/copyright" || { Error "Failed to Create File doc/copyright"; exit 1; }
                cp "$SRC_DIR/doc/copyright" "$PREFIX/share/doc/autux/copyright" || { Error "Failed to copy $SRC_DIR/doc/copyright"; exit 1; }
            fi
            # /5.2.3/ Install Autux ReadMe Doc
            if [ ! -f "$PREFIX/share/doc/autux/README.md" ]; then
                echo -n > "$PREFIX/share/doc/autux/README.md" || { Error "Failed to Create File doc/README.md"; exit 1; }
                cp "$SRC_DIR/doc/README.md" "$PREFIX/share/doc/autux/README.md" || { Error "Failed to copy $SRC_DIR/doc/README.md"; exit 1; }
            fi
            # /5.2.4/ Minimum Reqs Folder
            if [ ! -d "$PREFIX/share/doc/autux/reqs" ]; then
                mkdir -p "$PREFIX/share/doc/autux/reqs" || { Error "Failed to Create Directory doc/reqs"; exit 1; }
            fi
            # /5.2.5/ Install Py Reqs
            if [ ! -f "$PREFIX/share/doc/autux/PIP_Req.txt" ]; then
                echo -n > "$PREFIX/share/doc/autux/PIP_Req.txt" || { Error "Failed to Create File doc/PIP_Req.txt"; exit 1; }
                cp "$SRC_DIR/reqs/PIP_Req.txt" "$PREFIX/share/doc/autux/reqs/PIP_Req.txt" || { Error "Failed to copy $SRC_DIR/reqs/PIP_Req.txt"; exit 1; }
            fi
            # /5.2.6/ Install Termux Reqs
            if [ ! -f "$PREFIX/share/doc/autux/TMX_Req.txt" ]; then
                echo -n > "$PREFIX/share/doc/autux/TMX_Req.txt" || { Error "Failed to Create File doc/TMX_Req.txt"; exit 1; }
                cp "$SRC_DIR/reqs/TMX_Req.txt" "$PREFIX/share/doc/autux/reqs/TMX_Req.txt" || { Error "Failed to copy $SRC_DIR/reqs/TMX_Req.txt"; exit 1; }
            fi
            SetCache "Dir-Docs/Files"
            Info "Documentation Files Created Successfully."
        fi
    fi
    SetCache "Dir-Docs"
    Info "Documentation Directory Setup Complete"
    # /5.3/ Local Bin
    if ! Cache "Dir-LocBin"; then
        if [ ! -d "$HOME/.local/bin" ]; then
            Info "Creating HOME Executable Directory"
            mkdir -p "$HOME/.local/bin" || { Error "Failed to Create .local/bin"; exit 1; }
            mkdir -p "$HOME/.local/share" || { Error "Failed to Create .local/share"; exit 1; }
            export PATH="$HOME/.local/bin:$PATH" || { Error "Failed to Update PATH"; exit 1; }
        fi
        if [ ! -d "$HOME/.local/bin" ]; then
            Error "Local Bin Directory not created"
        elif [ -d "$HOME/.local/bin" ]; then
            SetCache "Dir-LocBin"
            Info "Local Bin Directory Created"
        fi
    fi
    # /5.4/ VenV
    if ! Cache "Dir-VenV"; then
        if [ ! -d "$VENV/scripts" ]; then
            Info "Creating the VenV/scripts Directory"
            mkdir -p "$VENV/scripts" || { Error "Failed to Create VenV/scripts"; exit 1; }
        fi
        if [ ! -d "$VENV/scripts" ]; then
            Error "VenV/scripts Directory not created"
        elif [ -d "$VENV/scripts" ]; then
            SetCache "Dir-VenV"
            Info "VenV/scripts Directory Created"
        fi
    fi
    # /5.5/ PATH Bin
    if ! Cache "Dir-Bin"; then
        Info "Creating Binaries"
        # /5.5.1/ Session
        if ! Cache "Dir-Bin-Session"; then
            if [ ! -f "$PREFIX/bin/session" ]; then
                echo -n > "$PREFIX/bin/session" || { Error "Failed to Create File bin/session"; exit 1; }
                cp "$SRC_DIR/session.sh" "$PREFIX/bin/session" || { Error "Failed to copy $SRC_DIR/session.sh"; exit 1; }
            fi
            if [ ! -f "$PREFIX/bin/session" ]; then
                Error "Session.sh not created"
            elif [ -f "$PREFIX/bin/session" ]; then
                SetCache "Dir-Bin-Session"
                Info "Session.sh Saved to Bin"
            fi
        fi
        # /5.5.2/ autux
        if ! Cache "Dir-Bin-Autux"; then
            if [ ! -f "$PREFIX/bin/autux" ]; then
                echo -n > "$PREFIX/bin/autux" || { Error "Failed to Create File bin/autux"; exit 1; }
                cp "$SRC_DIR/autux.py" "$PREFIX/bin/autux" || { Error "Failed to copy $SRC_DIR/autux.py"; exit 1; }
            fi
            if [ ! -f "$PREFIX/bin/autux" ]; then
                Error "autux not created"
            elif [ -f "$PREFIX/bin/autux" ]; then
                SetCache "Dir-Bin-Autux"
                Info "autux Saved to Bin"
            fi
        fi
        # /5.5.3/ __setup__
        if ! Cache "Dir-Bin-Setup"; then
            if [ ! -f "$PREFIX/bin/__setup__" ]; then
                echo -n > "$PREFIX/bin/__setup__" || { Error "Failed to Create File bin/__setup__"; exit 1; }
                cp "$SRC_DIR/__setup__.sh" "$PREFIX/bin/__setup__" || { Error "Failed to copy $SRC_DIR/__setup__.sh"; exit 1; }
            fi
            if [ ! -f "$PREFIX/bin/__setup__" ]; then
                Error "__setup__ not created"
            elif [ -f "$PREFIX/bin/__setup__" ]; then
                SetCache "Dir-Bin-Setup"
                Info "__setup__.sh Saved to Bin"
            fi
        fi
        # /5.5.4/ __permiss__
        if ! Cache "Dir-Bin-Permiss"; then
            if [ ! -f "$PREFIX/bin/__permiss__" ]; then
                echo -n > "$PREFIX/bin/__permiss__" || { Error "Failed to Create File bin/__permiss__"; exit 1; }
                cp "$SRC_DIR/__permiss__.sh" "$PREFIX/bin/__permiss__" || { Error "Failed to copy $SRC_DIR/__permiss__.sh"; exit 1; }
            fi
            if [ ! -f "$PREFIX/bin/__permiss__" ]; then
                Error "__permiss__ not created"
            elif [ -f "$PREFIX/bin/__permiss__" ]; then
                SetCache "Dir-Bin-Permiss"
                Info "__permiss__.sh Saved to Bin"
            fi
        fi
        SetCache "Dir-Bin"
        Info "Binaries Created"
    fi
    # /5.6/ Etc
    if ! Cache "Dir-Etc/autux"; then
        if [ ! -d "$PREFIX/etc/autux" ]; then
            mkdir -p "$PREFIX/etc/autux" || { Error "Failed to create $PREFIX/etc/autux"; Exit; }
        fi
        if [ ! -f "$PREFIX/etc/autux/autux.conf" ]; then
            echo -n > "$PREFIX/etc/autux/autux.conf" || { Error "Failed to Create File etc/autux/autux.conf"; Exit; }
            cp "$SRC_DIR/configs/autux.conf" "$PREFIX/etc/autux/autux.conf" || { Error "Failed to copy $SRC_DIR/configs/autux.conf"; Exit; }
        fi
        if [ ! -f "$PREFIX/etc/autux/autux.conf" ]; then
            Error "autux.conf not created"
        elif [ -f "$PREFIX/etc/autux/autux.conf" ]; then
            SetCache "Dir-Etc/autux"
            Info "autux.conf Saved to Etc"
        fi
    fi
    # /5.7/ Settings
    if ! Cache "Dir-Etc/Settings"; then
        if [ ! -d "$HOME/.local/share/autux" ]; then
            mkdir -p "$HOME/.local/share/autux" || { Error "Failed to create $HOME/.local/share/autux"; Exit; }
        fi
        if [ ! -f "$HOME/.local/share/autux/settings" ]; then
            echo -n > "$HOME/.local/share/autux/settings" || { Error "Failed to Create File .local/share/autux/settings"; Exit; }
            cp "$SRC_DIR/configs/settings.jsonc" "$HOME/.local/share/autux/settings" || { Error "Failed to copy $SRC_DIR/configs/settings"; Exit; }
        fi
        if [ ! -f "$HOME/.local/share/autux/settings" ]; then
            Error "settings not created"
        elif [ -f "$HOME/.local/share/autux/settings" ]; then
            SetCache "Dir-Etc/Settings"
            Info "settings Saved to Local Share"
        fi
    fi
    # /5.8/ Storage Access
    if ! Cache "Dir-Access"; then
        # /5.8.1/ Give Storage Access
        if [ ! -d "$HOME/storage" ]; then
            Warn "Termux storage permission not granted." "You must manually allow storage permissions on the next screen"
            Timer 5
            if ! command -v termux-setup-storage >/dev/null 2>&1; then
                Error "termux-setup-storage not found"
                exit 1
            fi
            termux-setup-storage || { Error "termux-setup-storage failed"; Exit; }
            Timer 5
        # /5.8.2/ Create Storage Directory
            if [ -d "$HOME/storage" ]; then
                Info "Storage Access Detected" "Creating Termux Folder on Local Storage"
                mkdir -p "$HOME/storage/shared/Termux/bash" || { Error "Failed to create bash folder"; exit 1; }
                mkdir -p "$HOME/storage/shared/Termux/py" || { Error "Failed to create py folder"; exit 1; }
                SetCache "Dir-Access"
                Info "Folders and Variables Created"
            elif [ ! -d "$HOME/storage" ]; then
                Error "Storage Access not detected" "This is REQUIRED for Autux to function properly"
            fi
        # /5.8.3/ Create Directory if Storage Access Detected
        elif [ -d "$HOME/storage" ]; then
            Info "Storage Access Detected" "Creating Termux Folder on Local Storage"
            if [ ! -d "$HOME/storage/shared/Termux/bash" ]; then
                mkdir -p "$HOME/storage/shared/Termux/bash" || { Error "Failed to create bash folder"; exit 1; }
            fi
            if [ ! -d "$HOME/storage/shared/Termux/py" ]; then
                mkdir -p "$HOME/storage/shared/Termux/py" || { Error "Failed to create py folder"; exit 1; }
            fi
        fi
        SetCache "Dir-Access"
        Info "Folders and Variables Created"
    fi
}

# <!-- [SS-6]: Dependency Install ----->
Depends () {
    # /6.1/ Install Termux Packages
    if ! Cache "Deps-Tmx"; then
        PAK "tmx"
        SetCache "Deps-Tmx"
    fi
    # /6.2/ Bash-Completion
    Bash-Complete () {
        # /6.2.1/ Check Bash-Completion Install
        if ! Cache "Deps-BashCom"; then
            if ! pkg list-installed | grep -qe 'bash-completion'; then
                Info "Installing Bash-Completion"
                pkg install bash-completion -y || { Error "Failed to install bash-completion"; Exit; }
                SetCache "Deps-ShCom"
                Info "Installation Complete"
            fi
        fi
        # /6.2.2/ Enable Bash-Completion
        if ! Cache "Deps-Bashrc"; then
            Info "Enabeling Bash-Completion with bash.bashrc"
            echo "[ -f \"$PREFIX/etc/bash_completion\" ] && . \"$PREFIX/etc/bash_completion\"" >> "$PREFIX/etc/bash.bashrc"
            SetCache "Deps-Bashrc"
            Info "bash.bashrc appended"
        fi
        # /6.2.3/ Check Bash-Completion Directory
        if ! Cache "Deps-BashDir"; then
            if [ ! -d "$PREFIX/share/bash-completion/completions" ]; then
                Warn "Completions Directory not found" "Creating"
                mkdir -p "$PREFIX/share/bash-completion/completions" || { Error "Failed to create completions dir"; Exit; }
                SetCache "Deps-BashDir"
                Info "Completions Folder created"
            fi
        fi
        # /6.2.4/ Autux Bash-Completion
        if ! Cache "Deps-ComBash"; then
            if [ ! -f "$PREFIX/share/bash-completion/completions/autux" ]; then
                Info "Creating Autux Completions in Completions Directory"
                echo -n > "$PREFIX/share/bash-completion/completions/autux" || { Error "Failed to create autux completion"; Exit; }
                cp -v "$SRC_DIR/comp/autux" "$PREFIX/share/bash-completion/completions/autux" || Error "Failed to copy $SRC_DIR/comp/autux"
                SetCache "Deps-ComBash"
                Info "Completions Set"
            fi
        fi
        Info "Bash-Completion Configured"
        SetCache "Deps-Bash"
    }
    # /6.3/ Ranger Deps
    Ranger () {
        # /6.3.1/ Check Ranger
        if ! Cache "Deps-Rng"; then
            if ! pkg list-installed | grep -qe 'ranger'; then
                Warn "Ranger not installed" "Installing now"
                pkg install ranger -y || { Error "Failed to install ranger"; Exit; }
                SetCache "Deps-Rng"
                Info "Ranger installed successfully"
            fi
        fi
        # /6.3.2/ Ranger Configs Directory
        if ! Cache "Deps-RngDir"; then
            Info "Configuring Ranger"
            if [ ! -d "$HOME/.config/ranger" ]; then
                Warn "Ranger config folder not found, creating it"
                mkdir -p "$HOME/.config/ranger" || { Error "Failed to create ranger config dir"; Exit; }
                SetCache "Deps-RngDir"
                Info "Ranger config folder created"
            fi
        fi
        # /6.3.3/ Check Ranger Config File
        if ! Cache "Deps-RngConf"; then
            export rc_file="$HOME/.config/ranger/rc.conf"
            if [ ! -f "$rc_file" ]; then
                Warn "Ranger Configs not found, Attempting to create rc.conf with ranger"
                if command -v ranger >/dev/null 2>&1; then
                    ranger --copy-config=rc || { Warn "ranger --copy-config=rc failed"; sleep 1; }
                    if [ -f "$rc_file" ]; then
                        Info "Ranger Configs Created Successfully"
                else
                    Warn "ranger --copy-config=rc failed" "Manually creating rc.conf"
                    echo "# Default Ranger configuration" > "$rc_file" || { Error "Failed to create rc.conf"; Exit; }
                fi
            fi
            SetCache "Deps-RngConf"
        fi
        # /6.3.4/ Set Ranger Configs Show Hidden
        if ! Cache "Deps-RSet"; then
            if [ -f "$rc_file" ]; then
                local target_line1="set show_hidden false"
                local new_line1="set show_hidden true"
                if grep -q "^$target_line1" "$rc_file"; then
                    Info "Editing target line present in rc.conf"
                    sed -i "s/^$target_line1.*/$new_line1/" "$rc_file" || { Error "Failed to edit rc.conf"; Exit; }
                elif grep -q "^$new_line1" "$rc_file"; then
                    Info "Target line already present in rc.conf"
                else
                    Info "Target line in rc.conf not found, adding it"
                    echo "$new_line1" >> "$rc_file" || { Error "Failed to add line to rc.conf"; Exit; }
                    Info "Added target line to existing rc.conf"
                fi
                SetCache "Deps-RSet"
            fi
        fi
        # /6.3.5/ Set Ranger Configs Viewmode
        if ! Cache "Deps-RSet2"; then
            local target_line2="set viewmode miller"
            local new_line2="# set viewmode miller"
            local target_line3="# set viewmode multipane"
            local new_line3="set viewmode multipane"
            if grep -q "^$target_line2" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line2.*/$new_line2/" "$rc_file" || { Error "Failed to edit rc.conf"; Exit; }
                sed -i "s/^$target_line3.*/$new_line3/" "$rc_file" || { Error "Failed to edit rc.conf"; Exit; }
            elif grep -q "^$new_line2" "$rc_file"; then
                if grep -q "^$new_line3" "$rc_file"; then
                    Info "Target line already present in rc.conf"
                fi
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line2" >> "$rc_file" || { Error "Failed to add line to rc.conf"; Exit; }
                echo "$new_line3" >> "$rc_file" || { Error "Failed to add line to rc.conf"; Exit; }
                Info "Added target line to existing rc.conf"
            fi
            SetCache "Deps-RSet2"
        fi
        # /6.3.6/ Set Ranger Configs Confirm on Delete
        if ! Cache "Deps-RSet4"; then
            local target_line4="set confirm_on_delete multiple"
            local new_line4="set confirm_on_delete always"
            if grep -q "^$target_line4" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line4.*/$new_line4/" "$rc_file" || { Error "Failed to edit rc.conf"; Exit; }
            elif grep -q "^$new_line4" "$rc_file"; then
                Info "Target line already present in rc.conf"
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line4" >> "$rc_file" || { Error "Failed to add line to rc.conf"; Exit; }
                Info "Added target line to existing rc.conf"
            fi
            SetCache "Deps-RSet4"
        fi
        # /6.3.7/ Set Ranger Configs Draw Borders
        if ! Cache "Deps-RSet5"; then
            local target_line5="set draw_borders none"
            local new_line5="set draw_borders both"
            if grep -q "^$target_line5" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line5.*/$new_line5/" "$rc_file" || { Error "Failed to edit rc.conf"; Exit; }
            elif grep -q "^$new_line5" "$rc_file"; then
                Info "Target line already present in rc.conf"
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line5" >> "$rc_file" || { Error "Failed to add line to rc.conf"; Exit; }
                Info "Added target line to existing rc.conf"
            fi
            SetCache "Deps-RSet5"
        fi
        # /6.3.8/ Set Ranger Configs Autoupdate Cumulative Size
        if ! Cache "Deps-RSet6"; then
            local target_line6="set autoupdate_cumulative_size false"
            local new_line6="set autoupdate_cumulative_size true"
            if grep -q "^$target_line6" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line6.*/$new_line6/" "$rc_file" || { Error "Failed to edit rc.conf"; Exit; }
            elif grep -q "^$new_line6" "$rc_file"; then
                Info "Target line already present in rc.conf"
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line6" >> "$rc_file" || { Error "Failed to add line to rc.conf"; Exit; }
                Info "Added target line to existing rc.conf"
            fi
            SetCache "Deps-RSet6"
        fi
        # /6.3.9/ Set Ranger Configs Wrap Scroll
        if ! Cache "Deps-RSet7"; then
            local target_line7="set wrap_scroll false"
            local new_line7="set wrap_scroll true"
            if grep -q "^$target_line7" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line7.*/$new_line7/" "$rc_file" || { Error "Failed to edit rc.conf"; Exit; }
            elif grep -q "^$new_line7" "$rc_file"; then
                Info "Target line already present in rc.conf"
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line7" >> "$rc_file" || { Error "Failed to add line to rc.conf"; Exit; }
                Info "Added target line to existing rc.conf"
            fi
            SetCache "Deps-RSet7"
        fi
        # /6.3.10/ Set Ranger Configs Colorscheme
        if ! Cache "Deps-RSet8"; then
            local target_line8="set colorscheme default"
            local new_line8="set colorscheme snow"
            if grep -q "^$target_line8" "$rc_file"; then
                Info "Editing target line present in rc.conf"
                sed -i "s/^$target_line8.*/$new_line8/" "$rc_file" || { Error "Failed to edit rc.conf"; Exit; }
            elif grep -q "^$new_line8" "$rc_file"; then
                Info "Target line already present in rc.conf"
            else
                Info "Target line in rc.conf not found, adding it"
                echo "$new_line8" >> "$rc_file" || { Error "Failed to add line to rc.conf"; Exit; }
                Info "Added target line to existing rc.conf"
            fi
            SetCache "Deps-RSet8"
        fi
        # /6.3.11/ Set Ranger Configs Ranger/Share
        if ! Cache "Deps-RngShare"; then
            if [ ! -d "$HOME/.local/share/ranger" ]; then
                Warn "Rangers Local configs folder not found" "Manually Creating Ranger Configs file"
                mkdir -p "$HOME/.local/share/ranger" || { Error "Failed to create ranger local share dir"; Exit; }
                Info "Ranger Local Configs folder created"
            fi
            SetCache "Deps-RngShare"
        fi
        # /6.3.12/ Set Ranger Configs Ranger/Bookmarks
        if ! Cache "Deps-RngBook"; then
            if [ ! -f "$HOME/.local/share/ranger/bookmarks" ]; then
                Warn "bookmarks file not found"
                Info "Creating Bookmarks file"
                echo "':/data/data" > "$HOME/.local/share/ranger/bookmarks" || { Error "Failed to create bookmarks file"; Exit; }
                Info "Bookmarks file created"
            fi
            SetCache "Deps-RngBook"
        fi
        # /6.3.13/ Set Ranger Configs Add Bookmarks
        if ! Cache "Deps-RngRead"; then
            if [ -f "$HOME/.local/share/ranger/bookmarks" ]; then
                Info "Including Locations to Bookmarks File"
                echo "':$VENV/scripts" >> "$HOME/.local/share/ranger/bookmarks" || { Error "Failed to add VenV/scripts to bookmarks"; Exit; }
                echo "':$HOME/.local/bin" >> "$HOME/.local/share/ranger/bookmarks" || { Error "Failed to add .local/bin to bookmarks"; Exit; }
                echo "':$HOME/storage/shared/Termux" >> "$HOME/.local/share/ranger/bookmarks" || { Error "Failed to add Termux to bookmarks"; Exit; }
                Info "Bookmarks Set Successfully"
            fi
            SetCache "Deps-RngRead"
        fi
        # /6.3.14/ Set Ranger Configs Ranger/History
        if ! Cache "Deps-RngHist"; then
            if [ ! -f "$HOME/.local/share/ranger/history" ]; then
                Info "Creating Local History Config File"
                echo -n > "$HOME/.local/share/ranger/history" || { Error "Failed to create history file"; Exit; }
                Info "History Config Created"
            fi
            SetCache "Deps-RngHist"
        fi
        # /6.3.15/ Set Ranger Configs Ranger/Tagged
        if ! Cache "Deps-RngTag"; then
            if [ ! -f "$HOME/.local/share/ranger/tagged" ]; then
                Info "Creating Local Tagged Config File"
                echo -n > "$HOME/.local/share/ranger/tagged" || { Error "Failed to create tagged file"; Exit; }
                Info "Tagged Config Created"
            fi
            SetCache "Deps-RngTag"
        fi
        # /6.3.16/ Set Ranger Configs Ranger/GLOBAL
        if ! Cache "Deps-RGlobal"; then
            if ! grep -q "RANGER_LOAD_DEFAULT_RC" "$PREFIX/etc/bash.bashrc"; then
                echo 'export RANGER_LOAD_DEFAULT_RC=FALSE' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to set RANGER_LOAD_DEFAULT_RC"; Exit; }
                Info "Set RANGER_LOAD_DEFAULT_RC=FALSE in bash.bashrc"
            fi
            SetCache "Deps-RGlobal"
        fi
        Info "Ranger Fully Configured"
        SetCache "Deps-Ranger"
    }
    # /6.4/ Run Termux Deps
    if ! Cache "Deps-Bash"; then
        Bash-Complete
    fi
    if ! Cache "Deps-Ranger"; then
        Ranger
    fi
}

# <!-- [SS-7]: Configure Bash.BashRC ----->
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
        echo '## Autux Configs ##' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to append comment to bash.bashrc"; Exit; }
    # /7.3/ Session
        if ! Cache "Bash-Session"; then
            if ! grep -q 'session.sh' "$PREFIX/etc/bash.bashrc"; then
                echo 'bash "$PREFIX/bin/session"' >> "$PREFIX/etc/bash.bashrc" || { Error "Failed to append session.sh to bash.bashrc"; Exit; }
            fi
            SetCache "Bash-Session"
            Info "Autux Configs set in Bash.Bashrc"
        fi
    # /7.4/ Source Bash.Bashrc
    if [ -f "$PREFIX/etc/bash.bashrc" ]; then
        set +u
        source "$PREFIX/etc/bash.bashrc"
        set -u
    fi
    # /7.5/ Ensure for Cache
    if [ -f "$PREFIX/etc/bash.bashrc" ]; then
        SetCache "Bash-Echo"
        Info "Bash.Bashrc Configured Successfully"
    elif [ ! -f "$PREFIX/etc/bash.bashrc" ]; then
        Error "Bash.Bashrc not found after configuration"
    fi
}

# <!-- [SS-8]: Set Terminal Configs ----->
IDE () {
    # /8.1/ Set Termux Properties
    if ! Cache "IDE-Prop"; then
        Info "Setting termux.properties settings..."
        # /8.1.1/ If termux.properties exists, sed edit
        if [ -f "$HOME/.termux/termux.properties" ]; then
            sed -i "s/^# allow-external-apps =.*/allow-external-apps = true/" "$HOME/.termux/termux.properties" || { Error "Failed to edit termux.properties"; Exit; }
            sed -i "s/^# terminal-cursor-blink-rate =.*/terminal-cursor-blink-rate = 750/" "$HOME/.termux/termux.properties" || { Error "Failed to edit termux.properties"; Exit; }
            sed -i "s/^# terminal-cursor-style =.*/terminal-cursor-style = block/" "$HOME/.termux/termux.properties" || { Error "Failed to edit termux.properties"; Exit; }
            sed -i "s/^# default-working-directory =.*/default-working-directory = "$HOME/VenV/scripts"/" "$HOME/.termux/termux.properties" || { Error "Failed to edit termux.properties"; Exit; }
            sed -i "s/^# shortcut.create-session =.*/shortcut.create-session = ctrl + t/" "$HOME/.termux/termux.properties" || { Error "Failed to edit termux.properties"; Exit; }
        # /8.1.2/ If termux.properties does not exist, echo create it
        elif [ ! -f "$HOME/.termux/termux.properties" ]; then
            mkdir -p "$HOME/.termux"
            echo -n > "$HOME/.termux/termux.properties" || { Error "Failed to create termux.properties"; Exit; }
            echo "allow-external-apps = true" >> "$HOME/.termux/termux.properties" || { Error "Failed to create termux.properties"; Exit; }
            echo "terminal-cursor-blink-rate = 750" >> "$HOME/.termux/termux.properties" || { Error "Failed to set terminal-cursor-blink-rate"; Exit; }
            echo "terminal-cursor-style = block" >> "$HOME/.termux/termux.properties" || { Error "Failed to set terminal-cursor-style"; Exit; }
            echo "bell-character = vibrate" >> "$HOME/.termux/termux.properties" || { Error "Failed to set bell-character"; Exit; }
            echo "default-working-directory = $HOME/VenV/scripts" >> "$HOME/.termux/termux.properties" || { Error "Failed to set default-working-directory"; Exit; }
            echo "shortcut.create-session = ctrl + t" >> "$HOME/.termux/termux.properties" || { Error "Failed to set shortcut.create-session"; Exit; }
        fi
    fi
    # /8.2/ Reload Settings
    if [ -f "$HOME/.termux/termux.properties" ]; then
        set +u
        termux-reload-settings || { Error "Failed to reload termux settings"; Exit; }
        set -u
    fi
    # /8.3/ Ensure for Cache
    if [ ! -f "$HOME/.termux/termux.properties" ]; then
        Error "termux.properties not found after reload"
    elif [ -f "$HOME/.termux/termux.properties" ]; then
        SetCache "PyV-Inst"
        Info "Termux Properties Set Successfully"
    fi
}

# <!-- [SS-9]: Setup the PyVenV ----->
PyVenV () {
    # /9.1/ Check Python Install
    if ! Cache "PyV-Inst"; then
        # /9.1.1/ Check for Python3 is Installed
        if ! pkg list-packages | grep -q 'python'; then
            if ! python3 -V >/dev/null 2>&1; then
                if ! pkg list-packages | grep -q 'python3'; then
                    Warn "Python Not Installed" "Installing"
                    pkg install python -y || { Error "Failed to install python"; Exit; }
                    Info "Python Installed"
                fi
            fi
        fi
        # /9.1.2/ Ensure for Cache
        if pkg list-packages | grep -q 'python'; then
            SetCache "PyV-Inst"
            Info "Python Installed Successfully"
        else
            Error "Python not installed, exiting"
        fi
    fi
    # /9.2/ Ensure VenV Directory
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
    # /9.3/ Ensure Virtual Environment
    if ! Cache "PyV-Bin"; then
        if [ ! -f "$VENV/bin/activate" ]; then
            Info "Attempting to create the VenV at $VENV"
            python3 -m venv "$VENV" --prompt "VenV" || { Error "Failed to create venv"; Exit; }
            Info "PyVenV Built"
        fi
        SetCache "PyV-Bin"
    fi
    # /9.4/ Activate the Venv
    if ! Cache "PyV-Act"; then
        if [ -f "$VENV/bin/activate" ]; then
            Info "Activating to update PIP"
            set +u
            cd "$PX" || { Error "Failed to change directory to $VENV/scripts"; Exit; }
            source "$VENV/bin/activate" || { Error "Failed to activate venv"; Exit; }
            python3 -m pip install --upgrade pip wheel setuptools || { Error "Failed to upgrade pip/wheel/setuptools"; Exit; }
            Info "PIP SETUPTOOLS & WHEEL Updated"
            set -u
        fi
        SetCache "PyV-Act"
    fi
    # /9.5/ Install Dependencies
    if ! Cache "PyV-Req"; then
        Warn "Installing Deps"
        PAK "pip"
        Info "Python venv created and dependencies installed."
        SetCache "PyV-Req"
    fi
    # /9.6/ Configure VenV Bin
    if ! Cache "PyV-BinRX"; then
        if [ -f "$VENV/bin/activate" ]; then
            Info "Editing PyVenV bin"
            {
                echo ' '
                echo '## Autux Configs ##'
                echo 'bash "$PREFIX/bin/session"'
            } >> "$VENV/bin/activate" || { Error "Failed to append to venv activate"; Exit; }
            Info "VenV bin/activate configured"
        fi
    fi
    # /9.7/ Source VenV Bin
    if [ -f "$VENV/bin/activate" ]; then
        set +u
        source "$VENV/bin/activate"
        set -u
    fi
    # /9.8/ Deactivate VenV
    if [ -n "${VIRTUAL_ENV-}" ]; then
        Info "Deactivating Python virtual environment"
        deactivate || Warn "deactivate command not found or already deactivated"
        cd $HOME || { Error "Failed to change directory to HOME"; Exit; }
    fi
    # /9.9/ Ensure for Cache
    if [ ! -f "$VENV/bin/activate" ]; then
        Error "venv/bin/activate not found after configuration"
    elif [ -f "$VENV/bin/activate" ]; then
        SetCache "PyV-BinRX"
        Info "VenV Activation Set Successfully"
    fi
}

# <!-- [SS-10]: Set Adb ----->
SetAdb () {
    # /10.1/ Check Usb Debugging
    Debug () {
        if ! Cache "Full-UsbDebug"
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
    # /10.2/ Check Usb Mode
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
    # /10.3/ Check if PC Connected
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
            if [[ $answer1 =~ ^[Yy]$ ]]; then
                export full_conn=true
                Info "PC is now connected to the device via USB, proceeding with ADB setup."
            fi
        elif [[ $answer1 =~ ^[Yy]$ ]]; then
            export full_conn=true
            Info "PC is connected to the device via USB, proceeding with ADB setup."
        fi
    }
    # /10.4/ Check if ADB is Installed
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
    # /10.5/ Connect ADB
    SetAdb () {
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
        elif [[ $answer1 =~ ^[Nn]$ ]]; then
            Warn "Device not found, please check your USB connection and try again."
        fi
    }
    # /10.6/ Try to persist
    Port () {
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
    # /10.7/ Runnit
    if ! Cache "Full-Complete"; then
        local full_adb=false
        local full_debug=false
        local full_usbmode=false
        local full_conn=false
        local full_adb_conn=false
        Input "Do you want to Fully-Install Autux? *if yes, a USB3.0 to PC Connection is required* (y/n)"
        if [[ $answer1 =~ ^[Yy]$ ]]; then
            # /10.6.1/ Check USB Debugging
            Debug
            # /10.6.2/ Check default USB Mode
            if [[ $full_debug == true ]]; then
                UsbMode
            fi
            # /10.6.3/ Check if PC Connected
            if [[ $full_usbmode == true && $full_debug == true ]]; then
                Pc
            fi
            # /10.6.4/ Check if ADB is Installed
            if [[ $full_conn == true && $full_usbmode == true && $full_debug == true ]]; then
                PcAdb
            fi
            # /10.6.5/ Connect ADB
            if [[ $full_adb == true && $full_conn == true && $full_usbmode == true && $full_debug == true ]]; then
                SetAdb
            fi
        elif [[ $answer1 =~ ^[Nn]$ ]]; then
            Warn "Full Install not selected" "Skipping ADB setup"
            echo 'You can run this setup again later with the command: __setup__'
        fi
        # /10.6.6/ Ensure for Cache
        if if adb shell getprop service.adb.tcp.port | grep -q '5555'; then
            Info "ADB Connection Successful"
            Port
            SetCache "Full-Complete"
        else
            Warn "ADB Connection Failed" "Please check your PC connection and try again."
        fi
    fi
}

# <!-- [SS-10]: Main ----->
Setup () {
    Start
    CacheSet
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
    if ! Cache "Adb"; then
        SetAdb
        SetCache "Adb"
    fi
    End
}

# <!-- [SS-11]: Run ----->
Setup
