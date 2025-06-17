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
    # /1.3/ Routing
: "${SRC_DIR:="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"}"

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
            if [ ! -f "$PREFIX/share/doc/autux/LICENSE" ]; then
                echo -n > "$PREFIX/share/doc/autux/LICENSE" || { Error "Failed to Create File doc/LICENSE"; exit 1; }
                cp "$SRC_DIR/doc/LICENSE" "$PREFIX/share/doc/autux/LICENSE" || { Error "Failed to copy $SRC_DIR/doc/LICENSE"; exit 1; }
            fi
            if [ ! -f "$PREFIX/share/doc/autux/copyright" ]; then
                echo -n > "$PREFIX/share/doc/autux/copyright" || { Error "Failed to Create File doc/copyright"; exit 1; }
                cp "$SRC_DIR/doc/copyright" "$PREFIX/share/doc/autux/copyright" || { Error "Failed to copy $SRC_DIR/doc/copyright"; exit 1; }
            fi
            if [ ! -f "$PREFIX/share/doc/autux/README.md" ]; then
                echo -n > "$PREFIX/share/doc/autux/README.md" || { Error "Failed to Create File doc/README.md"; exit 1; }
                cp "$SRC_DIR/doc/README.md" "$PREFIX/share/doc/autux/README.md" || { Error "Failed to copy $SRC_DIR/doc/README.md"; exit 1; }
            fi
            if [ ! -f "$PREFIX/share/doc/autux/PIP_Req.txt" ]; then
                echo -n > "$PREFIX/share/doc/autux/PIP_Req.txt" || { Error "Failed to Create File doc/PIP_Req.txt"; exit 1; }
                cp "$SRC_DIR/PIP_Req.txt" "$PREFIX/share/doc/autux/PIP_Req.txt" || { Error "Failed to copy $SRC_DIR/PIP_Req.txt"; exit 1; }
            fi
            if [ ! -f "$PREFIX/share/doc/autux/TMX_Req.txt" ]; then
                echo -n > "$PREFIX/share/doc/autux/TMX_Req.txt" || { Error "Failed to Create File doc/TMX_Req.txt"; exit 1; }
                cp "$SRC_DIR/TMX_Req.txt" "$PREFIX/share/doc/autux/TMX_Req.txt" || { Error "Failed to copy $SRC_DIR/TMX_Req.txt"; exit 1; }
            fi
            SetCache "Dir-Docs/Files"
            Info "Documentation Files Created Successfully."
        fi
    SetCache "Dir-Docs"
    fi
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
    if ! Cache "Dir-Etc"; then
        if [ ! -d "$PREFIX/etc/autux" ]; then
            mkdir -p "$PREFIX/etc/autux" || { Error "Failed to create $PREFIX/etc/autux"; exit 1; }
        fi
        if [ ! -f "$PREFIX/etc/autux/autux.conf" ]; then
            echo -n > "$PREFIX/etc/autux/autux.conf" || { Error "Failed to Create File etc/autux/autux.conf"; exit 1; }
            cp "$SRC_DIR/autux.conf" "$PREFIX/etc/autux/autux.conf" || { Error "Failed to copy $SRC_DIR/autux.conf"; exit 1; }
        fi
        if [ ! -f "$PREFIX/etc/autux/autux.conf" ]; then
            Error "autux.conf not created"
        elif [ -f "$PREFIX/etc/autux/autux.conf" ]; then
            SetCache "Dir-Etc"
            Info "autux.conf Saved to Etc"
        fi
    fi
    # /5.7/ Storage Access
    if ! Cache "Dir-Access"; then
        if [ ! -d "$HOME/storage" ]; then
            Warn "Termux storage permission not granted." "You must manually allow storage permissions on the next screen"
            Timer 5
            if ! command -v termux-setup-storage >/dev/null 2>&1; then
                Error "termux-setup-storage not found"
                exit 1
            fi
            termux-setup-storage || { Error "termux-setup-storage failed"; exit 1; }
            Timer 5
            if [ -d "$HOME/storage" ]; then
                Info "Storage Access Detected" "Creating Termux Folder on Local Storage"
                mkdir -p "$HOME/storage/shared/Termux/bash" || { Error "Failed to create bash folder"; exit 1; }
                FBash="$HOME/storage/shared/Termux/bash"
                mkdir -p "$HOME/storage/shared/Termux/py" || { Error "Failed to create py folder"; exit 1; }
                FPy="$HOME/storage/shared/Termux/py"
                SetCache "Dir-Access"
                Info "Folders and Variables Created"
            else
                Error "Storage Access not set Properly! Exiting"
                Timer 5
                exit 1
            fi
        else
            Info "Storage Access Detected" "Creating Termux Folder on Local Storage"
            mkdir -p "$HOME/storage/shared/Termux/bash" || { Error "Failed to create bash folder"; exit 1; }
            FBash="$HOME/storage/shared/Termux/bash"
            mkdir -p "$HOME/storage/shared/Termux/py" || { Error "Failed to create py folder"; exit 1; }
            FPy="$HOME/storage/shared/Termux/py"
            SetCache "Dir-Access"
            Info "Folders and Variables Created"
        fi
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
                cp -v "$SCR_DIR/autux" "$PREFIX/share/bash-completion/completions/autux" || Error "Failed to copy $SCR_DIR/autux"
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
        fi
    # /7.4/ Source Bash.Bashrc
        set +u
        source "$PREFIX/etc/bash.bashrc"
        Info "bash.bashrc Set Successfully"
        set -u
        Info "Autux Configs set in Bash.Bashrc"
    fi
    SetCache "Bash-Echo"
}

# <!-- [SS-8]: Set Terminal Configs ----->
IDE () {
    if ! Cache "IDE-Prop"; then
        Info "Setting termux.properties settings..."
        if [ -f "$HOME/.termux/termux.properties" ]; then
            sed -i "s/^# allow-external-apps =.*/allow-external-apps = true/" "$HOME/.termux/termux.properties" || { Error "Failed to edit termux.properties"; Exit; }
            sed -i "s/^# terminal-cursor-blink-rate =.*/terminal-cursor-blink-rate = 750/" "$HOME/.termux/termux.properties" || { Error "Failed to edit termux.properties"; Exit; }
            sed -i "s/^# terminal-cursor-style =.*/terminal-cursor-style = block/" "$HOME/.termux/termux.properties" || { Error "Failed to edit termux.properties"; Exit; }
            sed -i "s/^# default-working-directory =.*/default-working-directory = "$HOME/VenV"/" "$HOME/.termux/termux.properties" || { Error "Failed to edit termux.properties"; Exit; }
            sed -i "s/^# shortcut.create-session =.*/shortcut.create-session = ctrl + t/" "$HOME/.termux/termux.properties" || { Error "Failed to edit termux.properties"; Exit; }
        elif [ ! -f "$HOME/.termux/termux.properties" ]; then
            mkdir -p "$HOME/.termux"
            echo "allow-external-apps = true" > "$HOME/.termux/termux.properties" || { Error "Failed to create termux.properties"; Exit; }
            echo "terminal-cursor-blink-rate = 750" >> "$HOME/.termux/termux.properties" || { Error "Failed to set terminal-cursor-blink-rate"; Exit; }
            echo "terminal-cursor-style = block" >> "$HOME/.termux/termux.properties" || { Error "Failed to set terminal-cursor-style"; Exit; }
            echo "bell-character = vibrate" >> "$HOME/.termux/termux.properties" || { Error "Failed to set bell-character"; Exit; }
            echo "default-working-directory = $HOME/VenV" >> "$HOME/.termux/termux.properties" || { Error "Failed to set default-working-directory"; Exit; }
            echo "shortcut.create-session = ctrl + t" >> "$HOME/.termux/termux.properties" || { Error "Failed to set shortcut.create-session"; Exit; }
        fi
        Info "termux.properties Set Successfully"
        SetCache "IDE-Prop"
    fi
    set +u
    termux-reload-settings
    set -u
}

# <!-- [SS-9]: Setup the PyVenV ----->
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
                echo 'bash "$PREFIX/bin/session"'
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
    End
}

# <!-- [SS-11]: Run ----->
Setup
