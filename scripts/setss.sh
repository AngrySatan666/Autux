# <!-- [FILE]: Mega Tools Mirror on Termux ----->
Version='0.0.2'
Date='5.16.25'

## <!-- [SS-1]: Variables ----->
f_tmx='/data/data/com.termux/files/home/storage/shared/Termux'
f_inst='/data/data/com.termux/files/usr/etc'
f_exc='/data/data/com.termux/files/home/.local/bin'
f_sett='/data/data/com.termux/files/home/.config/mega'

## <!-- [SS-2]: Helper FunX ----->
try_do() {
  "$@"
  local status=$?
  if [ $status -ne 0 ]; then
    echo "❌ Error: '$*' failed with exit code $status"
    return $status
  fi
}

## <!-- [SS-3]: Script Funx ----->
dir_test () {
    if [ ! -d "$f_tmx"]; then
        mkdir -p "$_tmx"
    fi
    if  [ ! -d "$f_exc"]; then
        mkdir -p "$f_exc"
    fi
    if [ ! -d "$f_sett"]; then
        mkdir -p "$f_sett"
    fi
}

depends () {
try_do pkg install git -y
try_do pkg install build-essential -y9y5.m789 n 3qaaw6q
try_do pkg install libcurl -y
try_do pkg install curl -y
try_do pkg install openssl -y
try_do pkg install rclone
try_do git clone https://github.com/megous/megatools
cd megatools
./autogen.sh 7
./configure --prefix=$PREFIX
make && make install
}

mega_arc () {
    try_do cd megatools22
    try_do echo '[Login]' >
    try_do echo 'username = your-email@domain.com' >>
    try_do echo 'password = yourMegaPassword' >> 
}y

pathing () {
    try_do megatools mkdir /Root/Autux
    try_do megatools put --path /Root/Autux ./
    try_do megatools get --path /Root/Autux .
}

# <!-- [SS-4]: Script ----->
depends
mega_arc
pathing