#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'
Version='0.4.98'
Date='5/13/25'

# <!-- Global Variables ----->
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
HOME="${HOME:-/data/data/com.termux/files/home}"
export VENV="${PREFIX%/usr}/PyVenV"
export PS1='\[\e[0;31m\]\w\[\e[0m\] \[\e[0;32m\]\$\[\e[0m\] '

SCR_DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"

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
    local pat="$SCR_DIR/reqs"
    case "$1" in
        "tmx")
            Info "Installing Termux packages from TMX_Req.txt..."
            if [[ -f "$pat/TMX_Req.txt" ]]; then
                grep -vE '^\s*#|^\s*$' "$pat/TMX_Req.txt" | sed 's/[[:space:]]*$//' | xargs -r pkg install -y
                pkg update && pkg upgrade -y
                Info "Termux packages installed successfully."
            else
                Error "TMX_Req.txt not found in $pat."
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
Repo () {
    cd $HOME
    if pkg list-installed | grep -qe 'x11-repo||science-repo||game-repo'; then
        Info "Repositories already configured"
    else 
        Warn "Repositories not selected, installing repo pkgs"
        pkg update -y
        pkg install -y x11-repo science-repo game-repo
        pkg update -y
        Info "pkg"
        Warn "You must manually choose your respective repo on the next screens"
        Timer 5
        termux-change-repo
        Input "Press ENTER to continue..."
        Info "Updating all pkgs"
        pkg update && pkg upgrade -y
        Info "Repo Selected and Packages Updated"
    fi
    if [ ! -d "$HOME/storage" ]; then
        Warn "Termux storage permission not granted." "You must manually allow storage permissions on the next screen"
        Timer 5
        termux-setup-storage
        Input "Press ENTER to continue..."
        if [ -d "$HOME/storage" ]; then
            Info "Storage Access Detected"
        elif [ ! -d "$HOME/storage" ]; then
            Error "Storage Acess not set Properly! Exiting"
            Timer 5
            Exit
    Input "Automatically create script folders on storage drive? (y/n)"
    if [[ "${answer1,,}" =~ ^n ]]; then
        Input "Do you have a bash script folder location to add? If so type the location here, else press enter to skip"
        if [[ -z "${answer1// }" ]] || [[ "${answer1,,}" =~ ^n ]] ; then
            Warn "No bash script folder will be added, you can add this later in .config/autux/settings.json"
            FBash=' '
        else
            if [ -d "$HOME/storage/$answer1" ]; then
                FBash="$HOME/storage/$answer1"
            else
                Warn "The folder '$answer1' does not exist."
                Input "Would you like to create this folder? (y/n)"
                if [[ "${answer1,,}" =~ ^y ]]; then
                    mkdir -p "$HOME/storage/$answer1"
                    Info "Folder created at: $answer1"
                    FBash="$HOME/storage/$answer1"
                else
                    Warn "Folder not created."
                    FBash=' '
                fi
            fi
        fi
        Input "Do you have a py script folder location to add? If so type the location here, else press enter to skip"
        if [[ -z "${answer1// }" ]] || [[ "${answer1,,}" =~ ^n ]] ; then
            Warn "No py script folder will be added, you can add this later in .config/autux/settings.json"
            FPy=' '
        else
            if [ -d "$HOME/storage/$answer1" ]; then
                FPy="$HOME/storage/$answer1"
            else
                Warn "The folder '$answer1' does not exist."
                Input "Would you like to create this folder? (y/n)"
                if [[ "${answer1,,}" =~ ^y ]]; then
                    mkdir -p "$HOME/storage/$answer1"
                    Info "Folder created at: $answer1"
                    FPy="$HOME/storage/$answer1"
                else
                    Warn "Folder not created."
                    FPy=' '
                fi
            fi
        fi
    elif [[ "${answer1,,}" =~ ^y ]]; then
        mkdir -p "$HOME/storage/shared/Documents/scripts/bash"
        FBash="$HOME/storage/shared/Documents/scripts/bash"
        mkdir -p "$HOME/storage/shared/Documents/scripts/py"
        FPy="$HOME/storage/shared/Documents/scripts/py"
        Info "Folder '$HOME/storage/shared/Documents/scripts/bash' created" "Folder '$HOME/storage/shared/Documents/scripts/bash'"
    fi
    if [ ! -d "$HOME/.local/bin" ]; then
        mkdir -p "$HOME/.local/bin"
    fi
    if [ ! -d "$VENV/local/bin" ]; then
        mkdir -p "$VENV/local/bin"
    fi
    Info "Created '$HOME/.local/bin' & '$VENV/local/bin' " "Creating autux settings.json"
    mkdir -p "$HOME/.config/autux"
    cp "$SCR_DIR/bash/settings.json" "$HOME/.config/autux/settings.json"
    sed "s|\${VENV}|$VENV|g; s|\${FBash}|$FBash|g; s|\${FPy}|$FPy|g" "$HOME/.config/autux/settings.json" > "$HOME/.config/autux/settings.tmp" && mv "$HOME/.config/autux/settings.tmp" "$HOME/.config/autux/settings.json"
}

# <!-- Install Packages ----->
Depends () {
    PAK "tmx"
    if pkg list-installed | grep -qe 'ranger'; then
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
    fi
}


# <!-- Configure Bash && Bash.Bash ---->
Bash () {
    # <!-- $PREFIX/etc/bash.bashrc ----->
    Info "Setting bash.bashrc..."
    PS1='\[\e[0;31m\]\w\[\e[0m\] \[\e[0;32m\]\$\[\e[0m\] '
    if [ -f "$PREFIX/etc/bash.bashrc" ]; then
        if grep -q '^PROMPT_DIRTRIM=' "$PREFIX/etc/bash.bashrc"; then
            sed -i 's/^PROMPT_DIRTRIM=.*/PROMPT_DIRTRIM=0/' "$PREFIX/etc/bash.bashrc"
        else
            echo 'PROMPT_DIRTRIM=0' >> "$PREFIX/etc/bash.bashrc"
        fi
        if grep -q '^PS1=' "$PREFIX/etc/bash.bashrc"; then
            sed -i "s|^PS1=.*|$PS1|g" "$PREFIX/etc/bash.bashrc"
        else
            echo "$PS1" >> "$PREFIX/etc/bash.bashrc"
        fi
    else
        echo 'PROMPT_DIRTRIM=0' > "$PREFIX/etc/bash.bashrc"
        echo "$PS1" >> "$PREFIX/etc/bash.bashrc"
    fi
    SETTINGS="$HOME/.config/autux/settings.json"
    if command -v jq >/dev/null 2>&1; then
        export FBash="$(jq -r '.script.folders.bashFolder' "$SETTINGS")"
        export FPy="$(jq -r '.script.folders.pyFolder' "$SETTINGS")"
    else
        export FBash="$(grep -oP '"bashFolder":\s*"\K[^"]+' "$SETTINGS")"
        export FPy="$(grep -oP '"pyFolder":\s*"\K[^"]+' "$SETTINGS")"
    fi
    cat <<'EOF' >> "$PREFIX/etc/bash.bashrc"
# --- Autux dynamic script folders ---
SETTINGS="$HOME/.config/autux/settings.json"
if command -v jq >/dev/null 2>&1; then
    export FBash="$(jq -r '.script.folders.bashFolder' "$SETTINGS")"
    export FPy="$(jq -r '.script.folders.pyFolder' "$SETTINGS")"
else
    export FBash="$(grep -oP '"bashFolder":\s*"\K[^"]+' "$SETTINGS")"
    export FPy="$(grep -oP '"pyFolder":\s*"\K[^"]+' "$SETTINGS")"
fi

if [ -n "$FBash" ]; then
    find "$FBash" -type d -exec mkdir -p "$HOME/.local/bin/{}" \;
    find "$FBash" -type f -exec sh -c 'cp "$1" "$HOME/.local/bin/${1#"$FBash/"}"' _ {} \;
    find "$HOME/.local/bin" \( -name "*.sh" -o -name "*.py" -o -name "*.pym" -o -name "*.js" -o -name "*.pl" -o -name "*.rb" -o -name "*.sql" \) -type f -exec chmod +x {} \;
fi
if [ -n "$FPy" ]; then
    find "$FPy" -type d -exec mkdir -p "$VENV/local/bin/{}" \;
    find "$FPy" -type f -exec sh -c 'cp "$1" "$VENV/local/bin/${1#"$FPy/"}"' _ {} \;
    find "$VENV/local/bin" \( -name "*.sh" -o -name "*.py" -o -name "*.pym" -o -name "*.js" -o -name "*.pl" -o -name "*.rb" -o -name "*.sql" \) -type f -exec chmod +x {} \;
fi
export PATH="$HOME/.local/bin:$PATH"
# --- End Autux dynamic script folders ---
EOF
    echo "Welcome to Autux!" > "$PREFIX/etc/motd"
    source "$PREFIX/etc/bash.bashrc"
    Info "bash.bashrc Set Successfully"
    # <!-- $HOME/.bashrc ----->
    Info "Setting up ~/.bashrc…"
    [ -f "$HOME/.lesshst" ] && rm -f "$HOME/.lesshst"
    : > "$HOME/.bash_history"
    source "$HOME/.bashrc"
    Info "~/.bashrc updated successfully"
}

# <!-- Set Terminal Configs ----->
IDE () {
    # <!-- Set Properties ---->
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
    # <!-- Set Font ----->
    if [ ! -f "$HOME/.termux/colors.properties" ]; then
        echo -n "$HOME/.termux/colors.properties"
    fi
    Info "Setting Color Scheme and Font..."
    echo "# Using default color theme." > "$HOME/.termux/colors.properties"
    termux-reload-settings
    Info "Color scheme set to default successfully."
}

# <!-- Setup the PyVenV ----->
PyVenV () {
    # <!-- Create the Env ----->
    if [[ -d "$VENV" ]]; then
        Info "Python virtual environment already exists at $VENV"
    else
        if ! pkg list-packages | grep -qe 'python'; then
            pkg install python -y
        fi
        python3 -m venv "$VENV" --prompt "VenV"
        Info "PyVenV Built, activating to install dependencies"
        source "$VENV/bin/activate"
        python3 -m pip install --upgrade pip wheel setuptools
        PAK "pip"
        Info "Python virtual environment created and dependencies installed."
    fi
    # <!-- Set Site.customize ----->
    Info "Editing PyVenV Site-Packages"
    PYVER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    if [ -n "$PYVER" ]; then
        mkdir -p "$VENV/lib/python$PYVER/site-packages"
        cp -r "$SCR_DIR/py" "$VENV/lib/python$PYVER/site-packages/"
        "$VENV/bin/pip" install -e "$SCR_DIR/py"
    fi
    Info "PyVenV Site-Packages edited"
    # <!-- Edit bin/activate ----->
    Info "Editing PyVenV bin"
    ACTIVATE="$VENV/bin/activate"
    SETTINGS_JSON="$HOME/.config/autux/settings.json"
    if ! grep -q "Autux: Update settings.json" "$ACTIVATE"; then
        cat <<'EOF' >> "$ACTIVATE"
# --- Autux: Update settings.json with pip and pkg dependencies ---
if [ -f "$SETTINGS_JSON" ]; then
    pip freeze | jq --raw-input --slurp '
        split("\n")[:-1] | {pipDepend: .}
    ' > "$VIRTUAL_ENV/tmp_pip.json"
    jq --argjson pipDep "\$(cat $VIRTUAL_ENV/tmp_pip.json | jq .pipDepend)" \
        '(.VenV[0].main.pipDepend) = $pipDep' \
        "$SETTINGS_JSON" > "$VIRTUAL_ENV/tmp_settings.json" && mv "$VIRTUAL_ENV/tmp_settings.json" "$SETTINGS_JSON"
    rm "$VIRTUAL_ENV/tmp_pip.json"
    pkg list-installed | awk '{print \$1}' | jq --raw-input --slurp '
        split("\n")[:-1] | {pkgDepend: .}
    ' > "$VIRTUAL_ENV/tmp_pkg.json"
    jq --argjson pkgDep "\$(cat $VIRTUAL_ENV/tmp_pkg.json | jq .pkgDepend)" \
        '(.VenV[0].main.pkgDepend) = $pkgDep' \
        "$SETTINGS_JSON" > "$VIRTUAL_ENV/tmp_settings.json" && mv "$VIRTUAL_ENV/tmp_settings.json" "$SETTINGS_JSON"
    rm "$VIRTUAL_ENV/tmp_pkg.json"
fi
# --- End Autux block ---
EOF
    fi
}

Setup () {
    Repo
    Depends
    Bash
    IDE
    PyVenV
}

# <!-- Run ----->
Start
Setup
End
