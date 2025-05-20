#!/data/data/com.termux/files/usr/bin/bash

# <!-- [SS-1]: Build Descrip / Linking ----->
TERMUX_PKG_HOMEPAGE=https://github.com/AngrySatan666/Autux
TERMUX_PKG_DESCRIPTION="Device Automation via Wireless Debugging ADB bridge"
TERMUX_PKG_LICENSE="None"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.0.1
TERMUX_PKG_SRCURL="https://github.com/AngrySatan666/Autux/Autux${TERMUX_PKG_VERSION:2}.tar.gz"
TERMUX_PKG_SHA256=
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_GROUPS="automation"

# <!-- [SS-2]: The Build Params ----->
# dependencies #
TERMUX_PKG_DEPENDS="python, android-tools, ranger, jq, rclone, bash-completion"

# how to build #
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_BUILD_IN_SRC=false
TERMUX_PKG_CONFFILES="etc/autux/settings.json"
TERMUX_PKG_SERVICE_SCRIPT="autux: ./"
TERMUX_PKG_NO_DEBUG=true

# <!-- [SS-3]: The Build ----->
termux_step_pre_configure() {

}

termux_step_make_install() {

}

termux_step_post_make_install() {

}










"
When TERMUX_PKG_BUILD_IN_SRC=false, Termux packages are built in a temporary build directory (not the source tree). During installation, files are usually placed in these standard locations:

- Executable scripts:
  `/data/data/com.termux/files/usr/bin/`
  (for user-invokable commands, symlinked or copied here)

- Python packages:
  `/data/data/com.termux/files/usr/lib/pythonX.Y/site-packages/`
  (for importable Python modules)

- Configuration files:
  `/data/data/com.termux/files/usr/etc/<yourpackage>/`
  (or sometimes `/data/data/com.termux/files/usr/etc/` directly)

- Service/autorun scripts:
  `/data/data/com.termux/files/usr/etc/service/`
  (for Termux:Boot or service scripts)

- Documentation:
  `/data/data/com.termux/files/usr/share/doc/<yourpackage>/`

- Other data:
  `/data/data/com.termux/files/usr/share/<yourpackage>/`

If you want scripts to autorun or be available globally, you should install them to the appropriate directory (e.g., `bin/` for commands, `etc/` or `share/` for configs and data).
Custom post-install steps (like copying to `$HOME/.termux/boot/` for autorun) are usually handled in a `termux_step_post_make_install` function in your build script.
"
