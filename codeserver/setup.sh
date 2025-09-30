#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BUGS='true'

# <!-- [SS-1]: Global Variables ----->
    # /1.1/ Standard Directory
: "${PREFIX:=/data/data/com.termux/files/usr}"
: "${HOME:=/data/data/com.termux/files/home}"
: "${TMP:=$PREFIX/tmp}"
: "${BIN:=$HOME/.local/bin}"
: "${CONF:=$HOME/.config}"
: "${DOC:=$HOME/storage/shared/Documents}"
: "${BRC:=$PREFIX/etc/bash.bashrc}"
: "${UBIN:=$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/.local/bin}"
: "${UBHOME:=$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu}"

    # /1.2/ CodeServer Spec
: "${CACHE:=$HOME/.cache/codeserver/build.cache}"
: "${CFD:=$HOME/.cloudflared}"
: "${ENV:=/data/data/com.termux/files/env}"

    # /1.3/ Source Routing
: "${SRC:="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"}"

# <!-- [SS-2]: SnippeType Functions ----->
    # /2.1/ Console Debug
error () {
    local C="\033[91m"
    local R="\033[0m"
    for txt in "$@"; do
        echo -e "${C}[ERROR] $txt${R}"
        echo  ' '
        sleep 1
        exit 1
    done
}

warn () {
    local C="\033[33m"
    local R="\033[0m"
    if [ "$BUGS" = "true" ]; then
        for txt in "$@"; do
            echo -e "${C}[WARN] $txt${R}"
            sleep 1
        done
        echo ' '
    fi
}

info () {
    local C="\033[92m"
    local R="\033[0m"
    if [ "$BUGS" = "true" ]; then
        for txt in "$@"; do
            echo -e "${C}[INFO] $txt${R}"
            sleep 1
        done
        echo ' '
    fi
}

ok () {
    local C="\033[92m"
    local R="\033[0m"
    if [ "$BUGS" = "true" ]; then
        for txt in "$@"; do
            echo -e "${C}[OKAY] $txt${R}"
            sleep 1
        done
        echo ' '
    fi
}

    # /2.2/ Console Control
input () {
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

timer () {
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

    # /2.3/ Cache Config
setcache () {
        echo "$1" >> "$CACHE" || Error "Failed to Write to $CACHE"
    fi
}

cache () {
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

End () {
    local C="\033[96m"
    local R="\033[0m"
    echo ""
    echo "================================================================================================================================================================================="
    echo ""
    echo -e "${C}__SETUP__ has finished${R}"
    echo ""
    exit 1
}

# <!-- [SS-3]: Setup Cache's ----->
CacheSet () {
    # /3.1/ Ensure Terminal at Home
    info "Moving to Home Directory"
    cd "$HOME" || Error "Failed to cd to $HOME"
    ok "Switched to Home"

    # /3.2/ Create Install Cache
    if [ ! -f "$CACHE" ]; then
        info "Creating Cache Directory"
        mkdir -p "$$HOME/.cache/codeserver" || Error "Failed to Create Cache Directory"
        ok "Created Cache Directory"
        info "Creating Cache Build File"
        echo -n > "$CACHE" || Error "Failed to Create State File '$CACHE'"
        setcache "# // Cache Created: $DATE // #"
        ok "Cache File Created"
    elif [ -f "$CACHE" ]; then
        info "Previous Cache File Detected" "This Usually Means Setup Has been Ran Before, But Didn't Finish" "Checking..."
    fi
}

# <!-- [SS-4]: Termux State ----->
State () {
    # /4.1/ Check Repo Set
    if ! cache State-Repo; then
        if [ ! -L "$PREFIX/etc/termux/chosen_mirrors" ]; then
            info "Repo Set Not Detected" "Executing..."
            warn "You Must Manually Choose Your Respective Repo on the Next Screens"
            timer 3
            info "Launching termux-change-repo"
            if ! command -v termux-change-repo >/dev/null 2>&1; then
                error "termux-change-repo Not Found"
            fi
            termux-change-repo || Error "termux-change-repo Failed"
            timer 5
            ok "termux-change-repo Finished"
            info "Checking Repo Set..."
            if [ ! -L "$PREFIX/etc/termux/chosen_mirrors" ]; then
                error "Repo Set Not Created"
            elif [ -L "$PREFIX/etc/termux/chosen_mirrors" ]; then
                ok "Repo Set Successfully"
            fi
        elif [ -L "$PREFIX/etc/termux/chosen_mirrors" ]; then
            setcache State-Repo
            ok "Repo Set Finished"
        fi
    fi

    # /4.2/ Ensure Storage
    if ! cache State-Storage; then
        info "Checking Storage Permission"
        if [ ! -d "$HOME/storage" ]; then
            info "Storage Permission Not Found" "Executing..."
            warn "You Must Manually Allow Storage Permission on the Next Screen"
            timer 3
            info "Launching termux-setup-storage"
            if ! command -v termux-setup-storage >/dev/null 2>&1; then
                error "termux-setup-storage Not Found"
            fi
            termux-setup-storage || Error "termux-setup-storage Failed"
            timer 5
            ok "termux-setup-storage Finished"
            info "Checking Storage Permission..."
            if [ ! -d "$HOME/storage" ]; then
                error "Storage Permission Not Granted"
            elif [ -d "$HOME/storage" ]; then
                ok "Storage Permission Successfully Granted"
            fi
        elif [ -d "$HOME/storage" ]; then
            setcache State-Storage
            ok "Storage Permission Finished"
        fi
    fi

    # /4.3/ Ensure Directories
    if ! cache State-Dirs; then
        info "Checking Required Directories"
        local DIRS=("$BIN" "UBIN" "$DOC" "$ENV" "$CONF")
        for dir in "${DIRS[@]}"; do
            if [ ! -d "$dir" ]; then
               info "Creating Directory $dir"
               mkdir -p "$dir" || error "Failed to Create Required Directory: $dir"
               ok "Created Directory $dir"
            fi
        done
        for dir in "${DIRS[@]}"; do
            if [ ! -d "$dir" ]; then
               error "Required Directory Not Found: $dir"
            fi
        done
        fi
        setcache State-Dirs
        ok "All Required Directories Found"
    fi

    # /4.4/ Ensure Binaries
    if ! cache State-Bins; then
        info "Installing Source Files"
        if [ ! -f "$CONF/Req.ini" ]; then
            cp "$SRC/CodeServer/Req.ini" "$CONF/Req.ini" || error "Failed To Copy Req.ini"
            ok "Created $CONF/Req.ini"
        fi
        if [ ! -f "$CONF/setup.sh" ]; then
            cp "$SRC/CodeServer/setup.sh" "$CONF/setup.sh" || error "Failed To Copy Setup Script"
            ok "Created $CONF/setup.sh"
        fi
        if [ ! -f "$CONF/bash.bashrc" ]; then
            cp "$SRC/CodeServer/bash.bashrc" "$CONF/bash.bashrc" || error "Failed To Copy Bash Config"
            ok "Created $CONF/bash.bashrc"
        fi
        if [ ! -f "$BIN/install.sh" ]; then
            cp "$SRC/CodeServer/install.sh" "$BIN/install.sh" || error "Failed To Copy Install Script"
            chmod +x "$BIN/install.sh" || error "Failed To Make Install Script Executable"
            ok "Created $BIN/install.sh"
        fi
        if [ ! -d "$BIN/app" ]; then
            mkdir -p "$BIN/app" || error "Failed To Create App Directory"
            cp -r "$SRC/app"/* "$BIN/app/" || error "Failed To Copy App Files"
            ok "Created $BIN/app Directory And Copied Files"
            for file in "$BIN/app"/*; do
                if [ -f "$file" ]; then
                    chmod +x "$file" || error "Failed To Make $file Executable"
                    ok "Made $(basename "$file") Executable"
                fi
            done
        fi
        setcache State-Bins
        ok "Source Files Installed"
    fi

    # /4.5/ Ensure Packages
    if ! cache State-Packages; then
        # /4.5.1/ Check Update
        info "Checking for Package Updates"
        warn "Package Updates May Take a While Depending on Your Repo" "Some Updates Require User Interaction!"
        timer 3
        pkg update && pkg upgrade -y || error "Failed to Update Packages"
        ok "Package Update Finished"

        # /4.5.2/ Get Req.ini
        info "Installing Termux Dependencies"
        local REQ_FILE="$SRC/CodeServer/Req.ini"
        if [ ! -f "$REQ_FILE" ]; then
            error "Requirements file not found: $REQ_FILE"
        fi

        # /4.5.3/ Parse Req.ini
        info "Reading package requirements from $REQ_FILE"
        local in_pkg_section=false
        local packages=()
        info "Parsing packages from [pkg] section"
        while IFS= read -r line || [[ -n "$line" ]]; do
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [[ -z "$line" || "$line" =~ ^# ]]; then
                continue
            fi
            if [[ "$line" =~ ^\[.*\]$ ]]; then
                if [[ "$line" == "[pkg]" ]]; then
                    in_pkg_section=true
                    ok "Found [pkg] Section"
                else
                    in_pkg_section=false
                fi
                continue
            fi
            if [[ "$in_pkg_section" == true ]]; then
                packages+=("$line")
                ok "Found Package: $line"
            fi
        done < "$REQ_FILE"

        # /4.5.4/ Install Packages
        if [ ${#packages[@]} -gt 0 ]; then
            info "Installing ${#packages[@]} Packages..."
            for package in "${packages[@]}"; do
                info "Installing Package: $package"
                pkg install -y "$package" || error "Failed to Install Package: $package"
                ok "Successfully Installed: $package"
            done
            ok "All Packages Installed Successfully"
        else
            error "No Packages Found in [pkg] Section"
        fi
        setcache State-Packages
        ok "Package Installation Finished"
    fi
}

# <!-- [SS-5]: Environment Setup ----->
Setup () {
    # /5.1/ Bash Completion Install
    if ! cache Set-BashComp; then
        if ! pkg list-installed | grep -qe 'bash-completion'; then
            info "Installing Bash-Completion"
            pkg install bash-completion -y || error "Failed to Install Bash-Completion"
            setcache Set-BashComp
            ok "Installation Complete"
        fi
    fi

    # /5.2/ Enable Bash-Completion
    if ! cache Set-Bashrc; then
        info "Enabling Bash-Completion With $BRC"
        echo "[ -f \"$PREFIX/etc/bash_completion\" ] && . \"$PREFIX/etc/bash_completion\"" >> "$BRC"
        setcache Set-Bashrc
        ok "$BRC Appended"
    fi

    # /5.3/ Check Bash-Completion Directory
    if ! cache Set-BashDir; then
        if [ ! -d "$PREFIX/share/bash-completion/completions" ]; then
            warn "Completions Directory not found" "Creating"
            mkdir -p "$PREFIX/share/bash-completion/completions" || error "Failed to Create Bash-Completions Directory"
            setcache Set-BashDir
            ok "Completions Folder Created"
        fi
    fi

    # /5.4/ Ranger Install
    if ! cache Set-Ranger; then
        if ! pkg list-installed | grep -qe 'ranger'; then
            warn "Ranger Not Installed" "Installing Now"
            pkg install ranger -y || error "Failed to Install Ranger"
            setcache Set-RngInst
            ok "Ranger Installed Successfully"
        fi
    fi

    # /5.5/ Ranger Configs Directory
    if ! cache Set-RngDir; then
        info "Configuring Ranger"
        if [ ! -d "$HOME/.config/ranger" ]; then
            warn "Ranger Config Folder Not Found" "Creating..."
            mkdir -p "$HOME/.config/ranger" || error "Failed to Create Ranger Config Directory"
            setcache Set-RngDir
            ok "Ranger Config Folder Created"
        fi
    fi

    # /5.6/ Check Ranger Config File
    if ! cache Set-RngConf; then
        export rc_file="$HOME/.config/ranger/rc.conf"
        if [ ! -f "$rc_file" ]; then
            warn "Ranger Configs Not Found" "Attempting To Create With Ranger"
            if command -v ranger >/dev/null 2>&1; then
                ranger --copy-config=rc || warn "Ranger Copy Config Failed"
                if [ -f "$rc_file" ]; then
                    ok "Ranger Configs Created Successfully"
                else
                    warn "Ranger Copy Config Failed" "Manually Creating Config"
                    echo "# Default Ranger configuration" > "$rc_file" || error "Failed To Create Ranger Config"
                fi
            else
                warn "Ranger Command Not Found" "Manually Creating Config"
                echo "# Default Ranger configuration" > "$rc_file" || error "Failed To Create Ranger Config"
            fi
        fi
        setcache Set-RngConf
        ok "Ranger Config File Ready"
    fi

    # /5.8/ Set Ranger Configs Show Hidden
    if ! cache Set-RngHidden; then
        if [ -f "$rc_file" ]; then
            local target_line1="set show_hidden false"
            local new_line1="set show_hidden true"
            if grep -q "^$target_line1" "$rc_file"; then
                info "Editing Show Hidden Setting In Config"
                sed -i "s/^$target_line1.*/$new_line1/" "$rc_file" || error "Failed To Edit Ranger Config"
            elif grep -q "^$new_line1" "$rc_file"; then
                ok "Show Hidden Already Set In Config"
            else
                info "Adding Show Hidden Setting To Config"
                echo "$new_line1" >> "$rc_file" || error "Failed To Add Setting To Config"
                ok "Added Show Hidden Setting To Config"
            fi
            setcache Set-RngHidden
        fi
    fi

    # /5.8/ Set Ranger Configs Viewmode
    if ! cache Set-RngView; then
        local target_line2="set viewmode miller"
        local new_line2="# set viewmode miller"
        local target_line3="# set viewmode multipane"
        local new_line3="set viewmode multipane"
        if grep -q "^$target_line2" "$rc_file"; then
            info "Editing Viewmode Setting In Config"
            sed -i "s/^$target_line2.*/$new_line2/" "$rc_file" || error "Failed To Edit Ranger Config"
            sed -i "s/^$target_line3.*/$new_line3/" "$rc_file" || error "Failed To Edit Ranger Config"
        elif grep -q "^$new_line2" "$rc_file"; then
            if grep -q "^$new_line3" "$rc_file"; then
                ok "Viewmode Already Set In Config"
            fi
        else
            info "Adding Viewmode Setting To Config"
            echo "$new_line2" >> "$rc_file" || error "Failed To Add Setting To Config"
            echo "$new_line3" >> "$rc_file" || error "Failed To Add Setting To Config"
            ok "Added Viewmode Setting To Config"
        fi
        setcache Set-RngView
    fi

    # /5.9/ Set Ranger Configs Confirm on Delete
    if ! cache Set-RngConfirm; then
        local target_line4="set confirm_on_delete multiple"
        local new_line4="set confirm_on_delete always"
        if grep -q "^$target_line4" "$rc_file"; then
            info "Editing Confirm Delete Setting In Config"
            sed -i "s/^$target_line4.*/$new_line4/" "$rc_file" || error "Failed To Edit Ranger Config"
        elif grep -q "^$new_line4" "$rc_file"; then
            ok "Confirm Delete Already Set In Config"
        else
            info "Adding Confirm Delete Setting To Config"
            echo "$new_line4" >> "$rc_file" || error "Failed To Add Setting To Config"
            ok "Added Confirm Delete Setting To Config"
        fi
        setcache Set-RngConfirm
    fi

    # /5.10/ Set Ranger Configs Draw Borders
    if ! cache Set-RngBorders; then
        local target_line5="set draw_borders none"
        local new_line5="set draw_borders both"
        if grep -q "^$target_line5" "$rc_file"; then
            info "Editing Draw Borders Setting In Config"
            sed -i "s/^$target_line5.*/$new_line5/" "$rc_file" || error "Failed To Edit Ranger Config"
        elif grep -q "^$new_line5" "$rc_file"; then
            ok "Draw Borders Already Set In Config"
        else
            info "Adding Draw Borders Setting To Config"
            echo "$new_line5" >> "$rc_file" || error "Failed To Add Setting To Config"
            ok "Added Draw Borders Setting To Config"
        fi
        setcache Set-RngBorders
    fi

    # /5.11/ Set Ranger Configs Autoupdate Cumulative Size
    if ! cache Set-RngSize; then
        local target_line6="set autoupdate_cumulative_size false"
        local new_line6="set autoupdate_cumulative_size true"
        if grep -q "^$target_line6" "$rc_file"; then
            info "Editing Cumulative Size Setting In Config"
            sed -i "s/^$target_line6.*/$new_line6/" "$rc_file" || error "Failed To Edit Ranger Config"
        elif grep -q "^$new_line6" "$rc_file"; then
            ok "Cumulative Size Already Set In Config"
        else
            info "Adding Cumulative Size Setting To Config"
            echo "$new_line6" >> "$rc_file" || error "Failed To Add Setting To Config"
            ok "Added Cumulative Size Setting To Config"
        fi
        setcache Set-RngSize
    fi

    # /5.12/ Set Ranger Configs Wrap Scroll
    if ! cache Set-RngScroll; then
        local target_line8="set wrap_scroll false"
        local new_line8="set wrap_scroll true"
        if grep -q "^$target_line8" "$rc_file"; then
            info "Editing Wrap Scroll Setting In Config"
            sed -i "s/^$target_line8.*/$new_line8/" "$rc_file" || error "Failed To Edit Ranger Config"
        elif grep -q "^$new_line8" "$rc_file"; then
            ok "Wrap Scroll Already Set In Config"
        else
            info "Adding Wrap Scroll Setting To Config"
            echo "$new_line8" >> "$rc_file" || error "Failed To Add Setting To Config"
            ok "Added Wrap Scroll Setting To Config"
        fi
        setcache Set-RngScroll
    fi

    # /5.13/ Set Ranger Configs Colorscheme
    if ! cache Set-RngColor; then
        local target_line8="set colorscheme default"
        local new_line8="set colorscheme snow"
        if grep -q "^$target_line8" "$rc_file"; then
            info "Editing Colorscheme Setting In Config"
            sed -i "s/^$target_line8.*/$new_line8/" "$rc_file" || error "Failed To Edit Ranger Config"
        elif grep -q "^$new_line8" "$rc_file"; then
            ok "Colorscheme Already Set In Config"
        else
            info "Adding Colorscheme Setting To Config"
            echo "$new_line8" >> "$rc_file" || error "Failed To Add Setting To Config"
            ok "Added Colorscheme Setting To Config"
        fi
        setcache Set-RngColor
    fi

    # /5.14/ Set Ranger Configs Ranger/Share
    if ! cache Set-RngShare; then
        if [ ! -d "$HOME/.local/share/ranger" ]; then
            warn "Rangers Local Configs Folder Not Found" "Creating Directory"
            mkdir -p "$HOME/.local/share/ranger" || error "Failed To Create Ranger Local Share Directory"
            ok "Ranger Local Configs Folder Created"
        fi
        setcache Set-RngShare
    fi

    # /5.15/ Set Ranger Configs Ranger/Bookmarks
    if ! cache Set-RngBook; then
        if [ ! -f "$HOME/.local/share/ranger/bookmarks" ]; then
            warn "Bookmarks File Not Found"
            info "Creating Bookmarks File"
            echo "':/data/data" > "$HOME/.local/share/ranger/bookmarks" || error "Failed To Create Bookmarks File"
            ok "Bookmarks File Created"
        fi
        setcache Set-RngBook
    fi

    # /5.16/ Set Ranger Configs Add Bookmarks
    if ! cache Set-RngRead; then
        if [ -f "$HOME/.local/share/ranger/bookmarks" ]; then
            info "Including Locations To Bookmarks File"
            echo "':$ENV/scripts" >> "$HOME/.local/share/ranger/bookmarks" || error "Failed To Add Scripts To Bookmarks"
            echo "':$HOME/.local/bin" >> "$HOME/.local/share/ranger/bookmarks" || error "Failed To Add Local Bin To Bookmarks"
            echo "':$HOME/storage/shared/Termux" >> "$HOME/.local/share/ranger/bookmarks" || error "Failed To Add Termux To Bookmarks"
            ok "Bookmarks Set Successfully"
        fi
        setcache Set-RngRead
    fi

    # /5.18/ Set Ranger Configs Ranger/History
    if ! cache Set-RngHist; then
        if [ ! -f "$HOME/.local/share/ranger/history" ]; then
            info "Creating Local History Config File"
            echo -n > "$HOME/.local/share/ranger/history" || error "Failed To Create History File"
            ok "History Config Created"
        fi
        setcache Set-RngHist
    fi

    # /5.18/ Set Ranger Configs Ranger/Tagged
    if ! cache Set-RngTag; then
        if [ ! -f "$HOME/.local/share/ranger/tagged" ]; then
            info "Creating Local Tagged Config File"
            echo -n > "$HOME/.local/share/ranger/tagged" || error "Failed To Create Tagged File"
            ok "Tagged Config Created"
        fi
        setcache Set-RngTag
    fi

    # /5.19/ Set Ranger Configs Ranger/GLOBAL
    if ! cache Set-RngGlobal; then
        if ! grep -q "RANGER_LOAD_DEFAULT_RC" "$PREFIX/etc/bash.bashrc"; then
            echo 'export RANGER_LOAD_DEFAULT_RC=FALSE' >> "$PREFIX/etc/bash.bashrc" || error "Failed To Set Ranger Load Default RC"
            ok "Set Ranger Load Default RC In Bashrc"
        fi
        setcache Set-RngGlobal
        ok "Ranger Configuration Finished"
    fi
}

# <!-- [SS-6]: BashRC Setup ----->
BashRC () {
    # /6.1/ Set Ranger Load Default RC
    if ! cache Bash-RngSet; then
        if ! grep -q "RANGER_LOAD_DEFAULT_RC" "$BRC"; then
            echo 'export RANGER_LOAD_DEFAULT_RC=FALSE' >> "$BRC" || error "Failed To Set Ranger Load Default RC"
            ok "Set Ranger Load Default RC In Bashrc"
        fi
        setcache Bash-RngSet
    fi

    # /6.2/ Set Bash Aliases
    if ! cache Bash-Bashrc; then
        if [ -f "$CONF/bash.bashrc" ]; then
            info "Appending Custom Bashrc Content"
            echo "" >> "$BRC" || error "Failed To Add Blank Line To Bashrc"
            cat "$CONF/bash.bashrc" >> "$BRC" || error "Failed To Append Custom Bashrc Content"
            ok "Custom Bashrc Content Appended Successfully"
        else
            warn "Custom Bashrc File Not Found At $CONF/bash.bashrc"
        fi
        setcache Bash-Bashrc
    fi

    # /6.3/ IDE Settings
    if ! cache IDE-Prop; then
        info "Setting Termux Properties Settings"

        # /6.3.1/ If termux.properties exists, sed edit
        if [ -f "$HOME/.termux/termux.properties" ]; then
            info "Termux Properties Found" "Editing With Sed"
            sed -i "s/^# allow-external-apps =.*/allow-external-apps = true/" "$HOME/.termux/termux.properties" || error "Failed To Edit Allow External Apps"
            sed -i "s/^# terminal-cursor-blink-rate =.*/terminal-cursor-blink-rate = 850/" "$HOME/.termux/termux.properties" || error "Failed To Edit Cursor Blink Rate"
            sed -i "s/^# terminal-cursor-style =.*/terminal-cursor-style = block/" "$HOME/.termux/termux.properties" || error "Failed To Edit Cursor Style"
            sed -i "s/^# default-working-directory =.*/default-working-directory = $ENV\/scripts/" "$HOME/.termux/termux.properties" || error "Failed To Edit Working Directory"
            sed -i "s/^# shortcut.create-session =.*/shortcut.create-session = ctrl + t/" "$HOME/.termux/termux.properties" || error "Failed To Edit Session Shortcut"
            ok "Termux Properties Edited Successfully"

        # /6.3.2/ If termux.properties does not exist, echo create it
        elif [ ! -f "$HOME/.termux/termux.properties" ]; then
            info "Termux Properties Not Found" "Creating With Echo Commands"
            mkdir -p "$HOME/.termux" || error "Failed To Create Termux Directory"
            echo -n > "$HOME/.termux/termux.properties" || error "Failed To Create Termux Properties"
            echo "allow-external-apps = true" >> "$HOME/.termux/termux.properties" || error "Failed To Set Allow External Apps"
            echo "terminal-cursor-blink-rate = 850" >> "$HOME/.termux/termux.properties" || error "Failed To Set Cursor Blink Rate"
            echo "terminal-cursor-style = block" >> "$HOME/.termux/termux.properties" || error "Failed To Set Cursor Style"
            echo "bell-character = vibrate" >> "$HOME/.termux/termux.properties" || error "Failed To Set Bell Character"
            echo "default-working-directory = $ENV/scripts" >> "$HOME/.termux/termux.properties" || error "Failed To Set Working Directory"
            echo "shortcut.create-session = ctrl + t" >> "$HOME/.termux/termux.properties" || error "Failed To Set Session Shortcut"
            ok "Termux Properties Created Successfully"
        fi
        setcache IDE-Prop
    fi

    # /6.4/ Reload Settings
    if ! cache IDE-Reload; then
        info "Reloading Termux Settings"
        if [ -f "$HOME/.termux/termux.properties" ]; then
            set +u
            termux-reload-settings || error "Failed To Reload Termux Settings"
            set -u
        fi
        setcache IDE-Reload
        ok "Termux Settings Reloaded Successfully"
    fi

    # /6.5/ Ensure for Cache
    if ! cache IDE-DblCheck; then
        if [ ! -f "$HOME/.termux/termux.properties" ]; then
            error "Termux Properties Not Found After Reload"
        elif [ -f "$HOME/.termux/termux.properties" ]; then
            setcache IDE-DblCheck
            ok "Termux Properties Set Successfully"
        fi
    fi

    # /6.6/ Prompt Dir Trim
    if ! cache Bash-DirTrim; then
        info "Setting Prompt Dir Trim"
        if grep -q '^PROMPT_DIRTRIM=' "$PREFIX/etc/bash.bashrc"; then
            sed -i 's/^PROMPT_DIRTRIM=.*/PROMPT_DIRTRIM=0/' "$PREFIX/etc/bash.bashrc" || error "Failed To Set Prompt Dir Trim"
        else
            echo 'PROMPT_DIRTRIM=0' >> "$PREFIX/etc/bash.bashrc" || error "Failed To Append Prompt Dir Trim"
        fi
        setcache Bash-DirTrim
        ok "Prompt Dir Trim Set Successfully"
    fi
}

# <!-- [SS-7]: Proot Distro ----->
Distro () {
    # /7.1/ Install Distro
    if ! cache Distro-Ubuntu; then
        info "Installing Ubuntu Distro"
        proot-distro install ubuntu || error "Failed to Install Ubuntu"
        ok "Installed Ubuntu Distro"
        setcache Distro-Ubuntu
    fi

    # /7.2/ Local Bin
    if ! cache Distro-Bin; then
        info "Creating Ubuntu Local Bin Directory"
        mkdir -p "$UBIN" || error "Failed To Create Ubuntu Local Bin Directory"
        ok "Created Ubuntu Local Directory"
        cp "$SRC/install.sh" "$UBIN/install.sh" || error "Failed to Copy Install Script to Ubuntu"
        okay "Copied Install.sh to Ubuntu"
        chmod +x "$UBIN/install.sh" || error "Failed to chmod +x Install Script in Ubuntu"
        setcache Distro-Bin
    fi

    # /7.3/ Home Directory
    if ! cache Distro-Home ;then
        info "Copying Source Files to Ubuntu"
        cp -r $SRC/app/* "$UBHOME" || error "Failed to Copy Source Files to Ubuntu"
        ok "Source Files Copied"
        setcache Distro-Home
    fi

    # /7.4/ Projects Directory
    if ! cache Distro-Projects; then
        info "Creating Projects Directory in Ubuntu"
        if [ ! -d "$UBHOME/projects" ]; then
            mkdir -p "$UBHOME/Projects/.vscode" || error "Failed To Create Projects Directory in Ubuntu"
            ok "Created Projects Directory in Ubuntu"
        fi
        setcache Distro-Projects
    fi
}


# <!-- [SS-8]: Setting CodeServer ----->
CodeServer () {
    # /8.1/ CodeServer Configs
    if ! cache Code-Set; then
        info "Setting Up CodeServer Configuration"
        if [ ! -d "$HOME/.config/code-server" ]; then
            mkdir -p "$HOME/.config/code-server" || error "Failed To Create CodeServer Config Directory"
            ok "Created CodeServer Config Directory"
        fi
        if [ ! -f "$HOME/.config/code-server/config.yaml" ]; then
            info "Creating CodeServer Config File"
            cat > "$HOME/.config/code-server/config.yaml" << EOF || error "Failed To Create CodeServer Config"
bind-addr: 128.0.0.1:5000
auth: none
cert: false
EOF
            ok "Created CodeServer Config File"
        fi
        setcache Code-Set
        ok "CodeServer Configuration Complete"
    fi

    # /8.2/ CodeServer Install
    if ! cache Code-Inst; then
        info "Installing CodeServer"
        if [ ! -f "$BIN/install.sh" ]; then
            error "CodeServer Install Script Not Found At $BIN/install.sh"
        fi
        if [ ! -x "$BIN/install.sh" ]; then
            error "CodeServer Install Script Not Executable"
        fi
        bash "$BIN/install.sh" || error "CodeServer Install Script Failed"
        setcache Code-Inst
        ok "CodeServer Installed Successfully"
    fi

    # /8.3/ CodeServer Check
    if ! cache Code-Check; then
        info "Verifying CodeServer Installation"
        if command -v code-server >/dev/null 2>&1; then
            ok "CodeServer Command Found"
            code-server --version || warn "CodeServer Version Check Failed"
        else
            error "CodeServer Command Not Found After Install"
        fi
        setcache Code-Check
        ok "CodeServer Installation Verified"
    fi
}

# <!-- [SS-]: Main ----->
Main () {
    Start
    CacheSet
    if ! cache State; then
        State
        setcache State
    elif ! cache Setup; then
        Setup
        setcache Setup
    elif ! cache BashRC; then
        BashRC
        setcache BashRC
    elif ! cache Code; then
        CodeServer
        setcache Code
    fi
    End
}
