#!/bin/bash

usage() {
	echo "Usage:"
	echo "$0:"
	echo "		Install Gnome Extension: Disable-Gnome-Gesuture."
	echo "$0 uninstall:"
	echo "		Uninstall Gnome Extension: Disable-Gnome-Gesuture."
	echo ""
	exit 0
}

CheckPermission() {
    echo -n "(I) Check user permission:"
    account=`whoami`
    if [ ${account} = "root" ]; then
        echo " ${account}, you are the supervisor."
    else
        echo " ${account}"
        echo -e "\033[1;31;5mYou are NOT the supervisor.\033[0m"   
        echo -e "\033[1;31;5m(E) The root permission is required to run this installer.\033[0m"
        echo ""
        exit 1
    fi
}

InitMember(){
	drivername="eGalaxInfo"
	installpath="/usr/bin"
	driverEXE="${drivername}_${cpuArch}"
	
	
	gnomeShellPath="/usr/share/gnome-shell/extensions"
	gnomeShellDisaleGesture="disable-gestures@egalax"
	SupportDisableGnomeGesture="false"	#Gnome Gesture Defalut is enabled.

}

install(){
	
	if [ -e ${gnomeShellPath} ];then  #/usr/share/gnome-shell/extensions folder is exist
		echo "(I) Copying ${gnomeShellDisaleGesture} to ${gnomeShellPath}."
		cp -af "${gnomeShellDisaleGesture}" ${gnomeShellPath}
		gnome-shell-extension-tool -e ${gnomeShellDisaleGesture}
	else
		echo "(I) If you Need to disable Gnome Gesture"
		echo "\t please install gnome-shell-extension-tool, and try again."
	fi

}

uninstall(){

	gnome-shell-extension-tool -d ${gnomeShellDisaleGesture}

	if [ -e ${gnomeShellPath} ];then  #/usr/share/gnome-shell/extensions folder is exist
		echo "(I) Remove ${gnomeShellDisaleGesture}."
		rm -rf ${gnomeShellPath}/${gnomeShellDisaleGesture}
	fi


}


if [ $# = 0 ]; then
	clear
	CheckPermission
	InitMember
	install
elif [ $# -ge 1 ]; then
	if [ $1 = "uninstall" ]; then
		clear
		CheckPermission
		InitMember
		uninstall
        echo "(I) Gnome Extension: Disable Gnome Gesuture Uninstall Done."
		echo ""

	else
		usage
	fi
fi



