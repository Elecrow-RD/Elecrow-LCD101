#!/bin/sh
#Get EETI Debug information script. Version 1.0 (20201007)
INFO_PATH="./eeti/info.html"
DMESG_PATH="./eeti/dmesg"
INFO_FOLDER="./eeti/"

CheckPermission() {
    echo -n "(I) Check user permission:"
    account=`whoami`
    if [ ${account} = "root" ]; then
        echo " ${account}, you are the supervisor."
    else
        echo " ${account}, you are NOT the supervisor."
        echo "(E) The root permission is required to run this installer."
        echo ""
        exit 1
    fi
}

CheckPermission
echo "Start to collect log..."

#Modify DebugBits
CONFIG_FILE="/etc/eGTouchL.ini"
DEBUG_BITS="FFFFF"
sed -i '2d' $CONFIG_FILE
sed -i '1a DebugEnableBits\t\t\t'`echo $DEBUG_BITS` $CONFIG_FILE

#Restart driver
eGTouchD -f
sleep 5

#Create folder to put information
mkdir $INFO_FOLDER
touch $INFO_PATH
chmod 666 $INFO_PATH

#Print Information to file
{
echo "<html>"
echo "<body>"
echo "<tr>"
echo "<h1><strong><th>EETI Debug Log</th></strong></h1>"
echo "</tr>"
echo "<tr>"
date
echo "<p><strong><th>=====CPU Arch.=====</th></strong></p>"
lscpu | grep Architecture
echo "</tr>"
echo "<tr>"
echo "<p><strong><th>=====Kernel version.=====</th></strong></p>"
uname -r
echo "</tr>"
echo "<tr>"
echo "<p><strong><th>=====Distribution Info.=====</th></strong></p>"
cat /etc/*release
echo "</tr>"
echo "<tr>"
echo "<p><strong><th>=====Display server=====</th></strong></p>"
ps -e | grep tty
echo "</tr>"
echo "<tr>"
echo "<p><strong><th>=====Xinput Info.=====</th></strong></p>"
xinput list
echo "</tr>"
echo "<tr>"
echo "<p><strong><th>=====Input Devices=====</th></strong></p>"
cat /proc/bus/input/devices
echo "</tr>"
echo "</body>"
echo "</html>"
}>  $INFO_PATH

#Copy dmesg
dmesg >> "$DMESG_PATH"

#Copy driver log
cp /tmp/eGTouch* $INFO_FOLDER

#Recover DebugBits
DEBUG_BITS="1"
sed -i '2d' $CONFIG_FILE
sed -i '1a DebugEnableBits\t\t\t'`echo $DEBUG_BITS` $CONFIG_FILE

#Copy config file
cp $CONFIG_FILE $INFO_FOLDER

#Restart driver
eGTouchD -f

tar --remove-files -zcvf ./eeti.tar.gz $INFO_FOLDER > /dev/null

echo "Finish."
