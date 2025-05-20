#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SETTINGS="$(dirname "$0")/../../src/settings.json"

if command -v jq >/dev/null 2>&1; then
    FBash="$(jq -r '.Storage.bashFolder' "$SETTINGS")"
    FPy="$(jq -r '.Storage.pyFolder' "$SETTINGS")"
else
    FBash="$(grep -oP '"bashFolder":\\s*"\\K[^"]+' "$SETTINGS")"
    FPy="$(grep -oP '"pyFolder":\\s*"\\K[^"]+' "$SETTINGS")"
fi
export FBash
export FPy

echo "[INFO] FBash: $FBash"
echo "[INFO] FPy: $FPy"

ensure_venv_and_deps() {
    local venv_path="$1"
    local venv_prompt="$2"
    shift 2
    local depends=("$@")
    local activate="$venv_path/bin/activate"
    if [ ! -f "$activate" ]; then
        echo "[INFO] Creating venv at $venv_path with prompt $venv_prompt"
        python3 -m venv "$venv_path" --prompt "$venv_prompt"
    fi
    source "$activate"
    pip install --upgrade pip wheel setuptools
    installed=$(pip freeze | cut -d= -f1 | tr '\n' ' ')
    for dep in "${depends[@]}"; do
        if ! echo "$installed" | grep -qw "$dep"; then
            echo "[INFO] Installing missing dependency: $dep in $venv_path"
            pip install "$dep"
        fi
    done
    deactivate
    scripts_dir="$venv_path/scripts"
    mkdir -p "$scripts_dir"
    if [ -f "$FPy" ]; then
        cp "$FPy" "$scripts_dir/"
        echo "[INFO] Copied $FPy to $scripts_dir/"
        chmod +x "$scripts_dir/$(basename "$FPy")"
    fi
    if [ -d "$scripts_dir" ]; then
        chmod +x "$scripts_dir"/*
    fi
    echo "[INFO] Editing PyVenV Site-Packages"
    PYVER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    if [ -n "$PYVER" ]; then
        mkdir -p "$venv_path/lib/python$PYVER/site-packages"
        if [ -d "$SCR_DIR/py" ]; then
            cp -r "$SCR_DIR/py" "$venv_path/lib/python$PYVER/site-packages/"
        fi
        if [ -d "$SCR_DIR/site.customize" ]; then
            "$venv_path/bin/pip" install -e "$SCR_DIR/site.customize"
        fi
    fi
    echo "[INFO] PyVenV Site-Packages edited"
    ACTIVATE="$venv_path/bin/activate"
    SESSION_SH="$PREFIX/etc/autux/session.sh"
    if [ -f "$ACTIVATE" ] && ! grep -q "source.*session.sh" "$ACTIVATE"; then
        echo "" >> "$ACTIVATE"
        echo "# Autux: Source session.sh on venv activation" >> "$ACTIVATE"
        echo "[ -f \"$SESSION_SH\" ] && source \"$SESSION_SH\"" >> "$ACTIVATE"
    fi
}
if command -v jq >/dev/null 2>&1; then
    VenVPath="$(jq -r '.VenV.path' "$SETTINGS")"
    mapfile -t VenVDeps < <(jq -r '.VenV.depend[]' "$SETTINGS")
else
    VenVPath="$(grep -oP '"path":\\s*"\\K[^"]+' "$SETTINGS" | head -n1)"
    VenVDeps=()
    while read -r dep; do
        VenVDeps+=("$dep")
    done < <(grep -A 10 '"VenV":' "$SETTINGS" | grep -oP '"[^"]+"' | grep -v 'path' | tr -d '"' | grep -v '^$')
fi
if [ -n "$VenVPath" ]; then
    export VenV="$VenVPath"
    ensure_venv_and_deps "$VenVPath" "VenV" "${VenVDeps[@]}"
    if ! env | grep -q '^VenV='; then
        export VenV="$VenVPath"
    fi
fi

if command -v jq >/dev/null 2>&1; then
    mapfile -t other_keys < <(jq -r 'to_entries[] | select(.key != "VenV" and .key != "README!" and .value.path and .value.depend) | .key' "$SETTINGS")
    for key in "${other_keys[@]}"; do
        vpath="$(jq -r ".${key}.path" "$SETTINGS")"
        mapfile -t deps < <(jq -r ".${key}.depend[]" "$SETTINGS")
        if [ -n "$vpath" ]; then
            export "$key"="$vpath"
            ensure_venv_and_deps "$vpath" "$key" "${deps[@]}"
            if ! env | grep -q "^${key}="; then
                export "$key"="$vpath"
            fi
        fi
    done
else
    echo "[WARN] jq not found, skipping additional venvs beyond VenV."
fi

if [ -f "$FBash" ]; then
    mkdir -p "$HOME/local/bin"
    cp "$FBash" "$HOME/local/bin/"
    echo "[INFO] Copied $FBash to $HOME/local/bin/"
    chmod +x "$HOME/local/bin/$(basename "$FBash")"
    if [ -d "$HOME/local/bin" ]; then
        chmod +x "$HOME/local/bin"/*
    fi
fi

echo "[INFO] Environment setup complete."
