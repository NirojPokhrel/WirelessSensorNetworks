#!/bin/bash

case $1 in
    ''|*[!0-9]*) echo "call with channel number like ./tos-install.sh 11";exit ;;
    *) echo "TOS_CHANNEL is $1" ;;
esac

echo -e "\e[0;34;47m[installing tinyos]\033[0m"

WSNPR=~/wsnpr
WSNPR_TOSROOT=$WSNPR/tinyos-main

## get sudo
echo -e "\e[0;34;47m[enter system password ..]\033[0m"
sudo echo "sudo password cached .."

## rights to access serial ports
echo -e "\e[0;34;47m[access to serial ports ..]\033[0m"
sudo usermod -a -G dialout $USER


## tools
echo -e "\e[0;34;47m[installing packages ..]\033[0m"
sudo apt-get --yes --force-yes --no-install-recommends install git netcat6 cutecom wireshark autoconf automake libtool libc6-dev build-essential libncurses5-dev binutils-msp430 gcc-msp430 gdb-msp430 msp430-libc msp430mcu nescc openjdk-7-jdk

echo -e "\e[0;34;47m[create working directory ..]\033[0m"
mkdir $WSNPR
mkdir $WSNPR/util


## tinyos-main tree
echo -e "\e[0;34;47m[clone tinyos-main tree ..]\033[0m"
git clone https://github.com/tinyos/tinyos-main.git $WSNPR_TOSROOT

## tinyos tools
echo -e "\e[0;34;47m[compiling tinyos tools ..]\033[0m"
cd $WSNPR_TOSROOT/tools
./Bootstrap
./configure
make
sudo make install
cd

cd $WSNPR_TOSROOT/tools/tinyos/c/coap
./configure --with-tinyos
cd


## wsnpr apps
echo -e "\e[0;34;47m[clone wsnpr apps ..]\033[0m"
mkdir $WSNPR/apps
git clone https://github.com/vlahan/sn_pr_1516.git $WSNPR/apps


## set up enviroment variables
echo -e "\e[0;34;47m[set up enviroment variables ..]\033[0m"
cat <<EOF >$WSNPR/tos.env
export TOS_CHANNEL=$1
echo "setting up TOS_CHANNEL with \$TOS_CHANNEL"
export CLASSPATH=\$CLASSPATH:$WSNPR/tinyos-main/tools/tinyos/java
export PYTHONPATH=\$PYTHONPATH:$WSNPR/tinyos-main/tools/tinyos/python
export PATH=\$PATH:$WSNPR/util
export WSNPR_TOSROOT=$WSNPR_TOSROOT
EOF

echo "source $WSNPR/tos.env" >> ~/.bashrc


## set up gedit syntax highlighting for nesc
echo -e "\e[0;34;47m[installing nesc syntax highlighting fopr nesc ..]\033[0m"
wget http://downloads.sourceforge.net/project/nescplugin/nesc.lang 
sudo cp nesc.lang /usr/share/gtksourceview-2.0/language-specs/
sudo cp nesc.lang /usr/share/gtksourceview-3.0/language-specs/
rm nesc.lang

## set up pppd handling scripts
cat <<EOF >$WSNPR/util/tos-pppd_start
#!/bin/bash
case \$1 in
    ''|*[!0-9]*) echo "call with digit of ppprouter usb digit, e.g. tos-pppd_start 0 for ppprouter on /dev/ttyUSB0" ;;
    *) sudo pppd debug passive noauth nodetach 115200 /dev/ttyUSB\$1 nocrtscts nocdtrcts lcp-echo-interval 0 noccp noip ipv6 ::23,::24 ;;
esac
EOF
chmod +x $WSNPR/util/tos-pppd_start

cat <<EOF >$WSNPR/util/tos-pppd_configure
#!/bin/bash
sudo ifconfig ppp0 add fec0::100/64
EOF
chmod +x $WSNPR/util/tos-pppd_configure

cat <<EOF >$WSNPR/util/tos-pppd_kill
#!/bin/bash
sudo pkill pppd
EOF
chmod +x $WSNPR/util/tos-pppd_kill
