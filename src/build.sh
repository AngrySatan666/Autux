
# <!-- [SS-4]: Termux Build ----->
# /4.1/ Termux-Packages Linking
TERMUX_PKG_HOMEPAGE=https://github.com/AngrySatan666/Autux
TERMUX_PKG_DESCRIPTION="Device Automation via Wireless Debugging ADB bridge"
TERMUX_PKG_LICENSE="None"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.0.1
TERMUX_PKG_SRCURL="https://github.com/AngrySatan666/Autux/Autux${TERMUX_PKG_VERSION:2}.tar.gz"
TERMUX_PKG_SHA256=
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_GROUPS="automation"

# /4.2/ Termux-Packages Build Configs
TERMUX_PKG_DEPENDS="python, android-tools, ranger, jq, rclone, bash-completion"
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_BUILD_IN_SRC=false
TERMUX_PKG_CONFFILES="etc/autux/"
TERMUX_PKG_SERVICE_SCRIPT="autux: ./"
TERMUX_PKG_NO_DEBUG=true

termux_step_pre_configure() {

}

termux_step_make_install() {

}

termux_step_post_make_install() {

}
