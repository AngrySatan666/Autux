
# CodeServer BashRC Settings #

# Aliases
alias ls='ls -a'
alias cfd='cloudflared tunnel'
alias cfl='cloudflared tunnel list'
alias cfr='cloudflared tunnel run'
alias g='git'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gst='git status'
alias gcl='git clone'
alias gv='git version'
alias env="cd $ENV"
alias doc="cd $DOC"
alias bin="cd $BIN"
alias etc="cd $PREFIX/etc"
alias code='code-server'
alias pd='proot-distro login'
alias pdu='proot-distro login ubuntu'
alias pda='proot-distro login archlinux'
alias pdd='proot-distro login debian'
alias pdi='proot-distro login alpine'

# Exports
export ENV='/data/data/com.termux/files/env'
export BRC="$PREFIX/etc/bash.bashrc"
export CFD="$HOME/.cloudflared"
export DOC="$HOME/storage/shared/Documents"
export CONF="$HOME/.config"
export CACHE="$HOME/.cache"
export BIN="$HOME/.local/bin"
export LOCAL="$HOME/.local"
export UBIN="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/.local/bin"

export PATH="$PATH:$PREFIX/bin:$PREFIX/usr/bin:$PREFIX/usr/local/bin"
export PATH="$PATH:$UBIN"

# Settings

