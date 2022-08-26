#!/bin/sh


Script_Ver="1.04.9406"


#Set CPU Type here for Silent Mode.
#EX: "64", "32", "ARM", "ARMhf, "AARCH64"
cpuArch=""

CheckCpuType(){
	
	ARCH=`uname -m`
	echo "(I) Platform application binary interface = ${ARCH}"
	if [ ${ARCH} = "64" -o ${ARCH} = "x86_64" ] ; then
		cpuArch="64"
	elif [ ${ARCH} = "i386" -o $ARCH = "i586" -o $ARCH = "i686" ] ; then
		cpuArch="32"
	elif [ ${ARCH} = "aarch64" ] ; then
		cpuArch="AARCH64"
	elif [ ${ARCH} = "armv61" ] ; then
		cpuArch="ARM"
	else
		ReadELF="readelf -A /bin/sh"
		tmpfile="tmp.info"
		${ReadELF}>${tmpfile} 2>&1
		CheckConditionARMhf="Tag_ABI_VFP_args: VFP registers"
		CheckConditionMIPS="Tag_GNU_MIPS_ABI_FP"
		CheckConditionTagARM="Tag_ARM_ISA_use"
		grep -q "${CheckConditionARMhf}" ${tmpfile}
		if [ $? = 0 ];then
			cpuArch="ARMhf"
		else
			grep -q "${CheckConditionMIPS}" ${tmpfile}
			if [ $? = 0 ];then
				cpuArch="MIPS"
			else
				grep -q "${CheckConditionTagARM}" ${tmpfile}
				if [ $? = 0 ];then
					cpuArch="ARM"
				else
					#for Silent Mode.
					if [ ${SilentMode} = "true" ]; then
						echo "Plese setup CPU Type for Silent Mode in setup.sh"
						exit 1
					fi
										
					echo "Which platform arch do you use?"
					echo "[1] ARM  [2] ARMhf  [3] AARCH64  [4] MIPS"
					while : ; do
						read arch
						case $arch in
							1)	cpuArch="ARM"
								break;;
							2)	cpuArch="ARMhf"
								break;;
							3)	cpuArch="AARCH64"
								break;;
							4)	cpuArch="MIPS"
								break;;
							*)	echo "(I) Please choose [1], [2], [3] or [4]"
								echo -n "(A) ";;
						esac
					done
				fi
			fi
		fi
		rm ${tmpfile}
	fi
}

InitMember(){
	# file name
	drivername="eGTouch"
	eGTouchSH="eGTouch.sh"
	xorgfile="52-egalax-virtual.conf"
	xorgfile_libinput="52-egalax-virtual-libinput.conf"
	calibTool="eCalib"
	Distri="GENERAL"

	driverEXE="${drivername}D" 
	IniFile="${drivername}L.ini"
	drvPkgFldr="${drivername}${cpuArch}"
	drvPkgFldrX="" #This would be give value in functions.
	paramfile="${drivername}*.param"

	utilityExec="${drivername}U"
	UtilityPic="${utilityExec}.png"
	UtilityDesktop="${utilityExec}.desktop"

	#/etc/system/systemd
	daemonService="eGTouchD.service"
	
	resumeService="eGTouchResume.service"

	# path name
	installpath="/usr/local"
	etcpath="/etc"
	usrbinpath="/usr/bin"
	initpath="/etc/rc.d/init.d"
	init1path="/etc/init.d"
	rcSpath="/etc/rc.d/rcS.d"
	rcS1path="/etc/rcS.d"
	rc5path="/etc/rc.d/rc5.d"
	rc51path="/etc/rc5.d"	
	lightdmpath="/etc/lightdm"
	lightdmconfdpath="/etc/lightdm/lightdm.conf.d"  #new distribution after Ubuntu 16.04.6
	lightdmconfdfile="52-egalax-lightdm.conf"
	rclocalfile="rc.local"
	rclocalpath="/etc/rc.local"				# Ubuntu and Fedora, General OS
	rclocalpath1="/etc/init.d/boot.local"	# OpenSuSe 11.04.
	rclocalpath2="/etc/rc.d/rc.local"		# Fedora 14 & Redhat6
	rclocalpathSUSE11="/etc/rc.d/boot.local"
	blacklistpath="/etc/modprobe.d/blacklist.conf"
	etcModuleFile1="/etc/modules"				# Ubuntu modules bootup file
	etcModuleFile2="/etc/modules.conf"			# RedHat modules bootup file
	etcModuleFile3="/etc/conf.modules"			# SuSe modules bootup file
	etcModuleFile4="/etc/sysconfig/kernel"      # Suse 11.4 module loaded on bootup file
	trash="/dev/null"
	xorgpath="/usr/share/X11/xorg.conf.d"	# Ubuntu and Fedora
	xorgpath1="/etc/X11/xorg.conf.d"		# OpenSuSe 11.04
	xorgpath2="/usr/lib/X11/xorg.conf.d" # for Ubuntu 10.04 and Meego 1.0 netbook
	xorgconfpath="/etc/X11/xorg.conf"
	parampath="/var/lib"

	systemdpath="/etc/systemd/system" # for ubuntu 18.04 18.10
	systemctlpath="/bin/systemctl" # for ubuntu 18.04 18.10

	pixpath="/usr/share/pixmaps"
	iconpath="/usr/share/icons/gnome/48x48/apps"
	applicationpath="/usr/share/applications"

	#For PS2 interface
	seriofile="serio_raw.sh"
	rcSfile="S01serio_raw.sh"

	Xexist="true"
	interface="usb"
	
	SupportRotationMultiMonitor="false" #Enable detect rotation & multi monitor function, driver need start after X. Current use lightdm conf.
	lightdmexist="false"
	
	SupportBeep="false"
	
	udevpath="/etc/udev/rules.d"
	udevfile="99-egalax-udev.rules"
}
ShowTitle() {
    echo ""
    echo "(*) Driver installer for touch controller "
	echo "(*) Script Version = ${Script_Ver} "
    echo ""
}

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

pause() {
	echo "(I) Please confirm the touch controller is linked with your device. Press [Enter] key to continue.........."
	read DISCARD
}

InstallDriverRoutine() {
	rm -f ${parampath}/${paramfile}
	rm -f ${etcpath}/${paramfile}
	
    if [ -e ${installpath}/${drvPkgFldr} ]; then # check old driver folder1 & remove
        rm -rf ${installpath}/${drvPkgFldr}
    fi
	if [ -e ${installpath}/${drvPkgFldrX} ]; then # check old driver folder2 & remove
        rm -rf ${installpath}/${drvPkgFldrX}
    fi

    cp -rf ${drvPkgFldr}/${drvPkgFldrX} ${installpath} #copy driver directory to target path	
	sysDrvFldr="${installpath}/${drvPkgFldrX}"
	if [ $? = 0 ]; then
		echo "(I) Place ${drivername} driver archive to ${sysDrvFldr}."
	else
		echo "(E) Place ${drivername} driver archive to ${sysDrvFldr} failed."
		exit 1
	fi
	
	if [ $Xexist = "true" -a -e ${sysDrvFldr}/${utilityExec} ];then 
		cp Rule/$UtilityPic $sysDrvFldr # copy the png into driver installdest
	fi
	
	if [ -e ${sysDrvFldr}/${utilityExec} ]; then
		( cd ${sysDrvFldr}; chown root:root ${utilityExec}; chmod 4755 ${utilityExec})
		if [ $? != 0 ]; then
			echo "(I) Change utility permission failed"
			exit 1
		fi
	fi

    cp ${installpath}/${drvPkgFldrX}/${IniFile} ${etcpath}
	if [ $? != 0 ]; then
		echo "(I) Copy ${IniFile} to ${etcpath} failed."
		exit 1
	fi

    if [ -d ${usrbinpath} ]; then
        chmod a+x ${sysDrvFldr}/${driverEXE}
        ln -sf ${sysDrvFldr}/${driverEXE} ${usrbinpath}
		echo "(I) Create ${drivername} daemon shortcut in ${usrbinpath}."
		
		if [ -e ${sysDrvFldr}/${utilityExec} ]; then
			chmod a+x ${sysDrvFldr}/${utilityExec}
			ln -sf ${sysDrvFldr}/${utilityExec} ${usrbinpath}
			echo "(I) Create ${utilityExec} tool shortcut in ${usrbinpath}."
		fi
		
		if [ -e ${sysDrvFldr}/${calibTool} ]; then
			chmod 4755 ${sysDrvFldr}/${calibTool}
			ln -sf ${sysDrvFldr}/${calibTool} ${usrbinpath}
			echo "(I) Create ${calibTool} tool shortcut in ${usrbinpath}."
		fi
    else
		echo "(W) There is no directory ${usrbinpath}. We can NOT link shortcut under ${usrbinpath}."
		echo "(W) Please link it manually."
    fi

	cp setup.sh ${sysDrvFldr}
}

CheckUSBType() {
	usbfile="usb.info"
	checkusb="lsusb -v -d 0eef:"
	${checkusb} > ${usbfile} 2> ${trash}
	grep -q "Human Interface Device" ${usbfile}
	if [ $? -eq 0 ]; then
		echo "(I) Found a HID compliant touch controller."
		CheckModuleAndBlacklist
	else
		grep -q "Vendor Specific Protocol" ${usbfile}
		if [ $? -eq 0 ]; then
			echo "(W) Found a non-HID compliant touch controller."
			echo "(W) This driver doesn't support non-HID touch controller."
			echo "(W) Please update touch driver."
			RemoveDriver
		fi
	fi
	rm -f ${usbfile}
}

CheckUSBPIDnKernel() {
    Kversion=`uname -r`
    Kversion=${Kversion##* }	#3.8.0-23-generic-pae
    Kmajor=${Kversion%%.*}	#3
    Ktmp=${Kversion#*.}
    Kminor=${Ktmp%%.*}		#8

    if [ $Kmajor -ge 3 -a $Kminor -ge 8 ] && [ $Kmajor -le 3 -a $Kminor -le 12 ]  ;then
	usbfile="usb.info"
	checkusbpid="lsusb -d 0eef:"
	${checkusbpid} > ${usbfile} 2> ${trash}
	grep -q "0001" ${usbfile}
	if [ $? -eq 0 ]; then
	    echo ""
	    echo "(I) Found a PID:0001 touch controller in kernel 3.8 upwards."
            dmesg | grep "hid-multitouch 0003:0EEF:0001" > ${trash}
	    if [ $? -ne 0 ]; then	        
	        RemindKernelHIDPatch
	    fi
	fi
	rm -f ${usbfile}
    fi

}

CheckHIDRAW() {
	tmpfile="tmp.info"
	checkhidraw="dmesg"
	${checkhidraw} > ${tmpfile} 2>&1
	grep -q "hidraw" ${tmpfile}

	if [ $? -eq 0 ]; then
		echo "(I) Found hidraw module enabled in system"
	else
		echo "(E) Found no hidraw module. Please rebuild the module before installation."
		exit
	fi
	rm -f ${tmpfile}
}

GenerateSerioRaw(){
	checkcmd="which update-rc.d"
	cmdinfofile="cmd.info"
	${checkcmd} > ${cmdinfofile} 2>&1
	grep -q "no update-rc.d in" ${cmdinfofile}
	if [ $? -eq 0 ]; then #Put it into rclocal. Generally, we'll go into this part.
		grep -q "added by eGalaxTouch installer" $rclocalModulesPath
		if [ $? = 0 ]; then
			echo "(I) echo seriow_raw was already written in ${rclocalModulesPath}"
		else
			filelines=`cat ${rclocalModulesPath} | wc -l`
			sed -i ''${filelines}'i\# added by eGalaxTouch installer\necho -n "serio_raw" > /sys/bus/serio/devices/'${1}'/drvctl' ${rclocalModulesPath}
			echo "(I) Generate serio script in $rclocalModulesPath"
		fi
	else # This part seems like not do the verification. I'm not sure that it could work properly.
		cp -f Rule/${seriofile} ${initpath}
		chmod 755 $initpath/$seriofile
		sed -i '13a echo -n "serio_raw" > /sys/bus/serio/devices/'${1}'/drvctl' ${initpath}/${seriofile}
		update-rc.d ${seriofile} start 01 S . > ${trash}
		echo "(I) Generate serio script as $seriofile"
	fi
	rm -f ${cmdinfofile}
}

CheckSerioRawModule(){
	lsmod | grep serio_raw > ${trash}
	if [ $? = 0 ];then
		echo "(I) Module serio_raw.ko is detected under lsmod"
	else
		echo "(W) Module \"serio_raw.ko\" doesn't exist in kernel module."
		modprobe serio_raw
		if [ $? = 0 ];then
			echo "(I) Module serio_raw could be successfully loaded by modprobe."
			AttachModuleAtBoot "serio_raw"
			if [ $? = 0 ];then
				echo "(I) Attach insmod \"serio_raw\" at boot successfully."
			else
				echo "(E) Module \"serio_raw\" attached at boot failed."
				echo "(E) Please mannually let the module \"serio_raw\" attached at boot. Or touch would not be workable."
			fi
		else
			echo "(E) There is no module serio_raw.ko"
			echo "(E) Please make sure it is built-in the kernel, or touch would not be workable."
		fi
	fi
}



SetPS2Config(){
	CheckSerioRawModule
	echo "(I) Configure PS/2 aux driver."
	SerioDevPath="/sys/bus/serio/devices"
	tmp_file="tmp.info"
	ls ${SerioDevPath} > ${tmp_file}
    grep -q "serio" ${tmp_file}
		
	if [ $? = 0 ];then # Check whether /sys/bus/serio/devices/serio0 1 2 3 4 exist
		for i in 0 1 2 3 4
		do
			if [ -e ${SerioDevPath}/serio${i} ];then
				ls ${SerioDevPath}/serio${i}/ -al > ${tmp_file} # the serioX"/" is very important, or it would not give what we want
				grep -q "psmouse" ${tmp_file}
				if [ $? -eq 0 ];then
					serioport="serio${i}"
					# If this serioX got PS mouse collection, at the file driver would link to ../bus/serio/drivers/psmouse 
					echo "(I) Found PS2 mouse driver at serio${i}."
					GenerateSerioRaw ${serioport}
					rm -f ${tmp_file}
					return
				fi
				
				grep -q "serio_raw" ${tmp_file}
				if [ $? = 0 ]; then
					echo "(I) Found /"serio_raw/" located under ${SerioDevPath}/serio${i}/"
					rm -f ${tmp_file}
					return
				fi
			fi
		done
		echo "(E) No PS2 mouse driver found under ${SerioDevPath}/serioX"
		exit 1
	else
		echo "(E) No serio device found under ${SerioDevPath}"
		exit 1
	fi
	
	rm -f ${tmp_file}
}

RemoveeGTouchFile() {
	rm -f ${parampath}/${paramfile}
	rm -f ${etcpath}/${paramfile}
	
    if [ -e ${etcpath}/${IniFile} ]; then
        rm -rf ${etcpath}/${IniFile}
        echo "(I) Removed ${IniFile} file from ${etcpath}."
    else
        echo "(W) No ${etcpath}/${IniFile} file found."
    fi

}

RemoveShortcut() {
    if [ -d ${usrbinpath} ]; then
        if [ -L ${usrbinpath}/${driverEXE} ]; then
            rm -f ${usrbinpath}/${driverEXE}
            echo "(I) Removed ${driverEXE} shortcut from ${usrbinpath}."
        else
            echo "(W) No ${usrbinpath}/${driverEXE} shortcut found."
        fi
        
        if [ -L ${usrbinpath}/${utilityExec} ]; then
            rm -f ${usrbinpath}/${utilityExec}
            echo "(I) Removed ${utilityExec} shortcut from ${usrbinpath}."
        else
            echo "(W) No ${usrbinpath}/${utilityExec} shortcut found."
        fi
        if [ -L ${usrbinpath}/${calibTool} ]; then
            rm -f ${usrbinpath}/${calibTool}
            echo "(I) Removed ${calibTool} shortcut from ${usrbinpath}."
        else
            echo "(W) No ${usrbinpath}/${calibTool} shortcut found."
        fi
    else
        echo "(W) No ${usrbinpath} folder found."
    fi
}

AttachDrvExecAtRclocal() {
	echo "(I) Append ${drivername} daemon execution into $1."
	filelines=`cat $1 | wc -l`
	sed -i ''${filelines}'i\### Beginning: Launch eGTouchD daemon while setup boot-up ###\
/usr/bin/eGTouchD -f\
### End: Launch eGTouchD daemon while setup boot-up ###' $1
}

DetachDrvExecFromRclocal() { # Remove the auto execution stings in rc.local
	if [ -w ${rclocalModulesPath} ];then
			sed -i '/### Beginning: Launch eGTouchD daemon while setup boot-up ###/,/### End: Launch eGTouchD daemon while setup boot-up ###/d' ${rclocalModulesPath}
			echo "(I) Detach eGTouchD daemon execution from ${rclocalModulesPath}."
	else
		echo "(I) No ${rclocalModulesPath} file found."
	fi
}

CheckRCExist(){
	if [ -e ${systemctlpath} ];then
		echo "(I) Found systemd service support in system"
		cp -r "Rule/${daemonService}" ${systemdpath} 
		chmod a+x ${systemdpath}/${daemonService}
	else
		if [ -e ${initpath} ];then
			cp -f "Rule/${eGTouchSH}" ${initpath}
			chmod a+x ${initpath}/${eGTouchSH}
			echo "(I) Copying ${eGTouchSH} to ${rcSpath}."
		else
			cp -f "Rule/${eGTouchSH}" ${init1path}
			chmod a+x ${init1path}/${eGTouchSH}
			echo "(I) Copying ${eGTouchSH} to ${rcS1path}."
		fi
		
		if [ -e ${rcSpath} ];then # /etc/rc.d/rcS.d exist
			echo "(I) ${rcSpath} path found."
			if [ ! -e ${rcSpath}/S99eGTouch ] && [ -e ${initpath}/${eGTouchSH} ]; then
				ln -s "${initpath}/${eGTouchSH}" "${rcSpath}/S99eGTouch"				
			fi
		elif [ -e ${rcS1path} ];then # /etc/rcS.d exist
			echo "(I) ${rcS1path} path found."
			if [ ! -e ${rcS1path}/S99eGTouch ] && [ -e ${init1path}/${eGTouchSH} ]; then
				ln -s "${init1path}/${eGTouchSH}" "${rcS1path}/S99eGTouch" 
			fi
		elif [ -e ${rc5path} ];then # /etc/rc.d/rc5.d exist
			echo "(I) ${rc5path} path found."
			if [ ! -e ${rc5path}/S99eGTouch ] && [ -e ${initpath}/${eGTouchSH} ]; then
				ln -s ${initpath}/${eGTouchSH} ${rc5path}/S99eGTouch 
			fi
		elif [ -e ${rc51path} ];then # /etc/rc5.d
			echo "(I) ${rc51path} path found."
			if [ ! -e ${rc51path}/S99eGTouch ] && [ -e ${initpath}/${eGTouchSH} ]; then
				ln -s ${initpath}/${eGTouchSH} ${rc51path}/S99eGTouch 		
			fi
		fi
	fi
}

RemoveRCSetting(){
	if [ -e ${rcSpath}/S99eGTouch ];then # /etc/rc.d/rcS.d exist
		echo "(I) ${rcSpath} path found, removing ${rcSpath}/S99eGTouch."
		rm "${rcSpath}/S99eGTouch"
	fi

	if [ -e ${rcS1path}/S99eGTouch ];then # /etc/rcS.d exist
		echo "(I) ${rcS1path} path found, removing ${rcS1path}/S99eGTouch."
		rm "${rcS1path}/S99eGTouch"
	fi

	if [ -e ${rc5path}/S99eGTouch ];then
		echo "(I) ${rc5path} path found, removing ${rc5path}/S99eGTouch."
		rm "${rc5path}/S99eGTouch"
	fi
	
	if [ -e ${rc51path}/S99eGTouch ];then
		echo "(I) ${rc51path} path found, removing ${rc51path}/S99eGTouch."
		rm "${rc51path}/S99eGTouch"
	fi

	if [ -e ${systemdpath}/${daemonService} ]; then
		systemctl disable eGTouchD.service
		rm "${systemdpath}/${daemonService}"
	fi

	if [ -e ${initpath}/${eGTouchSH} ];then
		rm "${initpath}/${eGTouchSH}"
		echo "(I) Removing ${initpath}/${eGTouchSH}."
	fi

	if [ -e ${init1path}/${eGTouchSH} ];then
		rm "${init1path}/${eGTouchSH}"
		echo "(I) Removing ${init1path}/${eGTouchSH}."
	fi
}

CheckLightDMExist(){
	if [ -e ${lightdmconfdpath} ];then  #/etc/lightdm/lightdm.conf.d/ folder is exist
		cp -f "Rule/${lightdmconfdfile}" ${lightdmconfdpath}
		chmod a+x ${lightdmconfdpath}/${lightdmconfdfile}
		echo "(I) Copying ${lightdmconfdfile} to ${lightdmconfdpath}."
		sed -i '/DetectRotation/s/0/1/' $etcpath/$IniFile
		lightdmexist="true"
	elif [ -e ${lightdmpath} ];then # lightdm folder is exist
		if [ ! -e ${lightdmpath}/lightdm.conf ]; then
			echo [SeatDefaults] > ${lightdmpath}/lightdm.conf
		fi
		sed -i '/\[SeatDefaults\]/agreeter-setup-script=\/usr\/bin\/eGTouchD' ${lightdmpath}/lightdm.conf
		echo "(I) Add startup setting to ${lightdmpath}/lightdm.conf"
		sed -i '/DetectRotation/s/0/1/' $etcpath/$IniFile
		lightdmexist="true"
	fi
}

RemoveLightDMSetting(){
	if [ -e ${lightdmconfdpath} ];then  #/etc/lightdm/lightdm.conf.d/ folder is exist
		rm ${lightdmconfdpath}/${lightdmconfdfile}
		echo "(I) Removing ${lightdmconfdpath}/${lightdmconfdfile}"
	elif [ -e ${lightdmpath} ];then # lightdm is exist
		echo "(I) ${lightdmpath} file found."
		sed -i '/eGTouchD/d' ${lightdmpath}/lightdm.conf
		echo "(I) Remove startup setting from ${lightdmpath}/lightdm.conf" 
	fi
}


CheckRClocalExist(){
	if [ ! -e ${rclocalModulesPath} ];then # rc.local is not exist
		if [ ${Distri} = "FC16" -o ${Distri} = "FC17" -o ${Distri} = "FC18" -o ${Distri} = "FC19" -o ${Distri} = "FC20" -o ${Distri} = "FC21" -o ${Distri} = "FC22" -o ${Distri} = "FC2X" -o ${Distri} = "FC3X" ];then
			echo "(I) Copy ${rclocalfile} file to ${rclocalModulesPath}."
			cp -f "Rule/${rclocalfile}" ${rclocalModulesPath}
			chmod a+x ${rclocalModulesPath}
			echo "(I) Starting rc-local.service"
			systemctl restart rc-local.service
		else
			echo "(I) No ${rclocalModulesPath} file found."
			RemoveDriver
			echo ""
			exit 1
		fi
	fi
	echo "(I) Found ${rclocalModulesPath} file."
}

AllotRClocalPath(){ # This function would get target distri's rclocal path. And check whether it exist.		
	if [ ${Distri} = "SUSE" ]; then
		ModifySUSE11Xorg
		if [ -e ${rclocalpathSUSE11} ]; then
			rclocalModulesPath=${rclocalpathSUSE11}
		else
			rclocalModulesPath=${rclocalpath1}
		fi
	elif [ ${Distri} = "FC14" -o ${Distri} = "FC16" -o ${Distri} = "FC17" -o ${Distri} = "FC18" -o ${Distri} = "FC19" -o ${Distri} = "FC20" -o ${Distri} = "FC21" -o ${Distri} = "FC22" -o ${Distri} = "Redhat6" -o ${Distri} = "CentOS6.3" -o ${Distri} = "CentOS6.4" -o ${Distri} = "CentOS6.2" -o ${Distri} = "Slackware" -o ${Distri} = "CentOS6.5" -o ${Distri} = "CentOS7.0" -o ${Distri} = "CentOS6.6" -o ${Distri} = "FC2X" -o ${Distri} = "FC3X" ];then
		rclocalModulesPath=${rclocalpath2}
		if [ -e ${rclocalpath2} ]; then
			chmod 755 ${rclocalpath2}
		fi
	else
		rclocalModulesPath=${rclocalpath}
	fi
}

ModifySUSE11Xorg()
{
	if [ -e ${xorgconfpath} ]; then
		grep -q "ServerFlags" ${xorgconfpath}
	fi

	if [ $? -eq 0 ]; then
		grep -q "AutoAddDevices" ${xorgconfpath}
		if [ $? -eq 0 ]; then
			echo "(I) Support AutoAddDevices on SUSE11"
		else
			sed -i '/Section "ServerFlags"/a\  Option       "AutoAddDevices" "1"' ${xorgconfpath}
		fi
	fi

}

ModifyRClocal() {
	if [ -e ${rclocalModulesPath} ]; then
		grep -q "### Beginning: Launch ${drivername}D daemon while setup boot-up ###" ${rclocalModulesPath}
	fi

	if [ $? -eq 1 ]; then
		AttachDrvExecAtRclocal ${rclocalModulesPath}				
	else
		DetachDrvExecFromRclocal
		if [ -e $rclocalModulesPath} ]; then
			AttachDrvExecAtRclocal ${rclocalModulesPath}
		fi
	fi
}

Add2Blacklist() {
    if [ -w ${blacklistpath} ]; then
        grep -q $1 ${blacklistpath}
        if [ $? -eq 1 ]; then
            filelines=`cat ${blacklistpath} | wc -l`
            if [ ${filelines} > 1 ];then
                echo "(I) Add kernel module $1 into ${blacklistpath}."
                sed -i ''${filelines}'a\### Beginning: blacklist usbtouchscreen ###\
blacklist usbtouchscreen\
### End: blacklist usbtouchscreen ###' ${blacklistpath}
            else
		        echo -e "\n### Beginning: blacklist usbtouchscreen ###\nblacklist usbtouchscreen\n### End: blacklist usbtouchscreen ###" > ${blacklistpath}
            fi
        else
            echo "(I) The kernel module $1 has been added in ${blacklistpath}."
        fi
    else
	echo -e "\n### Beginning: blacklist usbtouchscreen ###\nblacklist usbtouchscreen\n### End: blacklist usbtouchscreen ###" > ${blacklistpath}
    fi
}

ShowBlacklistMenu() {
    echo "(I) It is highly recommended to add it into blacklist."
    echo -n "(Q) Do you want to add it into blacklist? (y/n) "
    while : ; do
        read yorn
        case $yorn in
            [Yy]) Add2Blacklist $1
               break;;
            [Nn]) # Nothing to do here.
               break;;
            *) echo "(I) Please choose [y] or [n]"
               echo -n "(A) ";;
        esac
    done
}

CheckModuleAndBlacklist() {
    checkmod="lsmod"
    modfile="mod.info"
    ${checkmod} > ${modfile} 2> ${trash}
    grep -q "usbtouchscreen" ${modfile}
    if [ $? -eq 0 ]; then
        echo "(I) Found inbuilt kernel module: usbtouchscreen"
        ShowBlacklistMenu "usbtouchscreen"
    fi
    rm -f ${modfile}
}

RestoreBlacklist() {
    if [ -w ${blacklistpath} ]; then
        grep -q "blacklist usbtouchscreen" ${blacklistpath}
        if [ $? -eq 0 ]; then
            sed -i '/### Beginning: blacklist usbtouchscreen ###/,/### End: blacklist usbtouchscreen ###/d' ${blacklistpath}
            echo "(I) Removed blacklist usbtouchscreen from ${blacklistpath}."
        fi
    fi
}

AttachUdevRule() {
	if [ ${Distri} = "SUSE" ];then
		if [ -e ${xorgpath1}/${xorgfile} ]; then
			echo "(W) Found udev rule: ${xorgfile}."
		else
			echo "(I) Copy udev rule: ${xorgfile} to ${xorgpath1}."
			cp -f "Rule/${xorgfile}" ${xorgpath1}
		fi
	elif [ ${Distri} = "Ubuntu10.04" ];then
		if [ -e ${xorgpath2}/${xorgfile} ]; then
			echo "(W) Found udev rule: ${xorgfile}."
		else
			echo "(I) Copy udev rule: ${xorgfile} to ${xorgpath2}."
			cp -f "Rule/${xorgfile}" ${xorgpath2}
		fi
	elif [ -e /usr/lib*/xorg/modules/input/libinput_drv.so ]; then
		if [ -e ${xorgpath}/${xorgfile_libinput} ]; then
			echo "(W) Found udev rule: ${xorgfile_libinput}."
		else
			echo "(I) Copy udev rule: ${xorgfile_libinput} to ${xorgpath}."
			cp -f "Rule/${xorgfile_libinput}" ${xorgpath}
		fi
	else
		if [ -e ${xorgpath}/${xorgfile} ]; then
			echo "(W) Found udev rule: ${xorgfile}."
		else
			echo "(I) Copy udev rule: ${xorgfile} to ${xorgpath}."
			cp -f "Rule/${xorgfile}" ${xorgpath}
		fi
	fi
}

DetachUdevRule() {
	if [ -e ${xorgpath}/${xorgfile} ]; then			# for Ubuntu 11.04 and Fedora 15
		rm -rf ${xorgpath}/${xorgfile}
		echo "(I) Removed udev rule: ${xorgpath}/${xorgfile}."
	elif [ -e ${xorgpath}/${xorgfile_libinput} ]; then
		rm -rf ${xorgpath}/${xorgfile_libinput}
		echo "(I) Removed udev rule: ${xorgpath}/${xorgfile_libinput}."
	else
		if [ -e ${xorgpath1}/${xorgfile} ]; then	# for Open SuSe 11.04
			rm -rf ${xorgpath1}/${xorgfile}
			echo "(I) Removed udev rule: ${xorgpath1}/${xorgfile}."
		else
			echo "(W) No udev rule: ${xorgfile} found."
		fi
	fi
}

RemoveSerioScript() {
    if [ -w ${rclocalpath} ]; then
        grep -q "echo -n" ${rclocalpath}
        if [ $? -eq 0 ]; then
            grep -q "# added by eGalaxTouch installer" ${rclocalpath}
            if [ $? -eq 0 ]; then
                sed -i '/# added by eGalaxTouch installer/,/echo -n/d' ${rclocalpath}
                echo "(I) Restored ${rclocalpath}."
            fi
        fi
    fi
    if [ -e ${initpath}/${seriofile} ]; then
        rm -f ${initpath}/${seriofile}
        rm -f ${rcSpath}/${rcSfile}
        echo "(I) Removed serio_raw script: ${initpath}/${seriofile}."
    fi
}

RemoveDriver() {
    temppath=`find ${installpath} -name ${driverEXE}`
    sysDrvFldr=${temppath%/*}
    if [ -z "${sysDrvFldr}" ]; then
        echo "(E) The driver archive has been removed already."
        echo ""
        exit 1
    elif [ -n "${sysDrvFldr}" ]; then
        ${driverEXE} -k
        rm -rf ${sysDrvFldr}
        echo "(I) Removed ${drivername} driver archive from ${sysDrvFldr}."
    fi

    RemoveeGTouchFile
    RemoveShortcut
	RemoveSerioScript
    DetachDrvExecFromRclocal
	
	if [ ${Distri} = "FC16" -o ${Distri} = "FC17" -o ${Distri} = "FC18" -o ${Distri} = "FC19" -o ${Distri} = "FC20" -o ${Distri} = "FC21" -o ${Distri} = "FC22" -o ${Distri} = "FC2X" -o ${Distri} = "FC3X" ];then
        rm -rf ${rclocalModulesPath}
	fi

    RestoreBlacklist
    DetachModuleAtBoot "uinput"
	if [ $Xexist = "true" ];then
		DetachUdevRule
	fi
}

AddUtilityShortCut() {
	if [ -e ${sysDrvFldr}/${utilityExec} ]; then
		if [ -e ${pixpath} ]; then
			cp -f Rule/${UtilityPic} ${pixpath}/${UtilityPic}
		fi
		
		if [ -e ${iconpath} ]; then
			cp -f Rule/${UtilityPic} ${iconpath}/${UtilityPic}
		fi
        
		if [ -e ${applicationpath} ]; then
			cp -f Rule/${UtilityDesktop} ${applicationpath}/${UtilityDesktop}
			if [ $cpuArch = "32" ]; then
				sed -i 's/eGTouch64withX/eGTouch32withX/' ${applicationpath}/${UtilityDesktop}
			fi
		fi
		echo "(I) Create ${utilityExec} shortcut in application list."
	fi

	
	if [ -f /usr/share/gnome-menus/update-gnome-menus-cache ] ; then
		/usr/share/gnome-menus/update-gnome-menus-cache /usr/share/applications > ~/desktop.en_US.utf8.cache
		mv ~/desktop.en_US.utf8.cache /usr/share/applications/desktop.en_US.utf8.cache
	fi
}
RemoveUtilityShortCut() {
	if [ -e ${pixpath}/${UtilityPic} ];then
		rm -f ${pixpath}/${UtilityPic}
	fi 
	if [ -e ${iconpath}/${UtilityPic} ];then
		rm -f ${iconpath}/${UtilityPic}
	fi
	if [ -e ${applicationpath}/${UtilityDesktop} ];then
		rm -f ${applicationpath}/${UtilityDesktop}
	fi
}

CheckUinput(){
	UinputPath1="/dev/uinput"
	UinputPath2="/dev/input/uinput"
	uinput=0
	
	ls ${UinputPath1} 1>${trash} 2>${trash}
	if [ $? = 0 ];then
		echo "(I) Found uinput at path ${UinputPath1}"
		uinput=1
	fi
		
	ls ${UinputPath2} 1>${trash} 2>${trash}
	if [ $? = 0 ];then
		echo "(I) Found uinput at path ${UinputPath2}"
		uinput=1
	fi
	
	if [ ${uinput} != 1 ];then # Found no uinput file 
		checkmod="lsmod"
        modfile="mod.info"
        ${checkmod} > ${modfile} 2> ${trash}
        grep -q "uinput" ${modfile}
		
		if [ $? != 0 ]; then	# Not found uinput.ko in modules
			checkmodprobe="modprobe -l -a"
			modprobefile="modprobe.info"
			${checkmodprobe} > ${modprobefile} 2> ${trash}
			grep -q "uinput" ${modprobefile}
			if [ $? -eq 0 ]; then	# Found uinput.ko in modules
				echo "(I) Found uinput.ko in modules."
				Loaduinput="modprobe uinput"
				${Loaduinput}		# Load uinput modules
				AttachModuleAtBoot "uinput"
			else
				echo "(E) Can't load uinput module. Please rebuild the module before installation."
				exit 1
			fi  
        fi
    fi
	
    rm -f ${modfile}
    rm -f ${modprobefile}
}
AttachModuleAtBoot(){
	echo "(I) Attach module $1 loaded at boot."
    if [ -w ${etcModuleFile1} ]; then
        grep -q "### Beginning: Load ${1}.ko modules ###" ${etcModuleFile1}
        if [ $? -eq 1 ]; then 
            filelines=`cat ${etcModuleFile1} | wc -l`
            sed -i ''${filelines}'a\### Beginning: Load '${1}'.ko modules ###\
'${1}'\
### End: Load '${1}'.ko modules###' ${etcModuleFile1}
			echo "(I) Add ${1} module into ${etcModuleFile1} file."
		fi
	elif [ -w ${etcModuleFile2} ]; then
		grep -q "### Beginning: Load ${1}.ko modules ###" ${etcModuleFile2}
		if [ $? -eq 1 ]; then
			filelines=`cat ${etcModuleFile2} | wc -l`
			sed -i ''${filelines}'a\### Beginning: Load '${1}'.ko modules ###\
'${1}'\
### End: Load '${1}'.ko modules###' ${etcModuleFile2}
			echo "(I) Add ${1} module into ${etcModuleFile2} file."
		fi
	elif [ -w ${etcModuleFile3} ]; then
		grep -q "### Beginning: Load ${1}.ko modules ###" ${etcModuleFile3}
		if [ $? -eq 1 ]; then
			filelines=`cat ${etcModuleFile3} | wc -l`
			sed -i ''${filelines}'a\### Beginning: Load '${1}'.ko modules ###\
'${1}'\
### End: Load '${1}'.ko modules###' ${etcModuleFile3}
			echo "(I) Add ${1} module into ${etcModuleFile3} file."
		fi
	elif [ -w ${etcModuleFile4} ]; then
		grep -q "### Beginning: Load ${1}.ko modules ###" ${etcModuleFile4}
		if [ $? -eq 1 ]; then
			filelines=`cat ${etcModuleFile4} | wc -l`
			sed -i ''${filelines}'a\### Beginning: Load '${1}'.ko modules ###\
MODULES_LOADED_ON_BOOT="'${1}'"\
### End: Load '${1}'.ko modules###' ${etcModuleFile4}
			echo "(I) Add ${1} module into ${etcModuleFile4} file."
		fi
	elif [ -w ${rclocalModulesPath} ]; then
		grep -q "### Beginning: Load ${1}.ko modules ###" ${rclocalModulesPath}
		if [ $? -eq 1 ]; then
			filelines=`cat ${rclocalModulesPath} | wc -l`
			echo "(I) Add modprobe '${1}' module into ${rclocalModulesPath} file."
			sed -i ''${filelines}'a\### Beginning: Load '${1}'.ko modules ###\
modprobe '${1}'\
### End: Load '${1}'.ko modules###' ${rclocalModulesPath}
		fi
	else
		echo "(E) Can't add ${1} modules in ${etcModuleFile1}, ${etcModuleFile2}, ${etcModuleFile3} or ${rclocalModulesPath}."
		exit 1
	fi
}

DetachModuleAtBoot() {
    if [ -w ${etcModuleFile1} ]; then
        grep -q "Load $1.ko modules" ${etcModuleFile1}
        if [ $? -eq 0 ]; then
            sed -i '/### Beginning: Load $1.ko modules ###/,/### End: Load $1.ko modules###/d' ${etcModuleFile1}
			rmmod $1
            echo "(I) Removed $1 modules from ${etcModuleFile1}."
        fi
	elif [ -w ${etcModuleFile2} ]; then
        grep -q "Load $1.ko modules" ${etcModuleFile2}
        if [ $? -eq 0 ]; then
            sed -i '/### Beginning: Load $1.ko modules ###/,/### End: Load $1.ko modules###/d' ${etcModuleFile2}
            rmmod $1
            echo "(I) Removed $1 modules from ${etcModuleFile2}."
        fi
	elif [ -w ${etcModuleFile3} ]; then
        grep -q "Load $1.ko modules" ${etcModuleFile3}
        if [ $? -eq 0 ]; then
            sed -i '/### Beginning: Load $1.ko modules ###/,/### End: Load $1.ko modules###/d' ${etcModuleFile3}
            rmmod $1
            echo "(I) Removed $1 modules from ${etcModuleFile3}."
        fi
    elif [ -w ${rclocalModulesPath} ]; then
        grep -q "Load $1.ko modules" ${rclocalModulesPath}
        if [ $? -eq 0 ]; then
            sed -i '/### Beginning: Load $1.ko modules ###/,/### End: Load $1.ko modules###/d' ${rclocalModulesPath}
            rmmod $1
            echo "(I) Removed $1 modules from ${rclocalModulesPath}."
        fi
	else
		echo "(E) Can't find ${etcModuleFile1}, ${etcModuleFile2}, ${etcModuleFile3} or ${rclocalModulesPath} file."
    fi
}

GetDistribution(){
	Xcommand="X -version"
	tmpfile="tmp.info"
	
	${Xcommand}>${tmpfile} 2>&1
	
	CheckCondition1="SUSE"
	CheckCondition2="Build ID: xorg-x11-server 1.9.0-15.fc14 "		#FC14
	CheckCondition3="Build ID: xorg-x11-server 1.7.7-26.el6"		#RHEL 6.1
	CheckCondition4="Build ID: xorg-x11-server 1.11.1-1.fc16"		#FC16
	CheckCondition5="Build ID: xorg-x11-server 1.12.0-2.fc17"		#FC17
	CheckCondition6="xorg-server 2:1.7.6-2ubuntu7"				#Ubuntu 10.04
	CheckCondition7="Build ID: xorg-x11-server 1.8.0-12.fc13"		#FC13
	CheckCondition8="Build ID: xorg-x11-server 1.10.6-1.el6.centos"		#CentOS 6.3
	CheckCondition9="Build ID: xorg-x11-server 1.13.0-11.el6.centos"	#CentOS 6.4
	CheckCondition10="Build ID: xorg-x11-server 1.10.4-6.el6"		#CentOS 6.2
	CheckCondition11="Build ID: xorg-x11-server 1.13.0-11.el6"		#RHEL 6.4
	CheckCondition12="Build ID: xorg-x11-server 1.13.0-11.fc18"		#FC18
	CheckCondition13="Build ID: xorg-x11-server 1.14.1-4.fc19"		#FC19
	CheckCondition14="Build ID: xorg-x11-server 1.10.6-1.el6"		#RHEL 6.3
	CheckCondition15="Slackware Linux Project"				#Slackware
	CheckCondition16="Build ID: xorg-x11-server 1.14.4-5.fc20"		#FC20
	CheckCondition17="Build ID: xorg-x11-server 1.13.0-23"			#CentOS 6.5
	CheckCondition18="Build ID: xorg-x11-server 1.15.0-7.el7"		#CentOS 7.0
	CheckCondition19="Build ID: xorg-x11-server 1.15.0-22.el6.centos"	#CentOS 6.6
	CheckCondition20="Build ID: xorg-x11-server 1.16.1-1.fc21"		#FC21
	CheckCondition21="Build ID: xorg-x11-server 1.17.1-11.fc22"		#FC22
	CheckCondition22="fc2"		#FC2X
	CheckCondition23="fc3"		#FC3X

	grep -q "${CheckCondition1}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="SUSE"
	fi
	
	grep -q "${CheckCondition2}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="FC14"
	fi
	
	grep -q "${CheckCondition3}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="Redhat6"
	fi

	grep -q "${CheckCondition4}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="FC16"
	fi
	
	grep -q "${CheckCondition5}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="FC17"
	fi
	
	grep -q "${CheckCondition6}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="Ubuntu10.04"
	fi
	
	grep -q "${CheckCondition7}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="FC14"
	fi

	grep -q "${CheckCondition8}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="CentOS6.3"
	fi

	grep -q "${CheckCondition9}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="CentOS6.4"
	fi
	
	grep -q "${CheckCondition10}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="CentOS6.2"
	fi
	
	grep -q "${CheckCondition11}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="Redhat6"
	fi

	grep -q "${CheckCondition12}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="FC18"
	fi

	grep -q "${CheckCondition13}" ${tmpfile}
	if [ $? = 0 ];then
		Distri="FC19"
	fi

	grep -q "${CheckCondition14}" ${tmpfile}
        if [ $? = 0 ];then
                Distri="RedHat6"
        fi

        grep -q "${CheckCondition15}" ${tmpfile}
        if [ $? = 0 ];then
                Distri="Slackware"
        fi

	grep -q "${CheckCondition16}" ${tmpfile}
        if [ $? = 0 ];then
                Distri="FC20"
        fi

	grep -q "${CheckCondition17}" ${tmpfile}
        if [ $? = 0 ];then
                Distri="CentOS6.5"
        fi

	grep -q "${CheckCondition18}" ${tmpfile}
        if [ $? = 0 ];then
                Distri="CentOS7.0"
        fi

	grep -q "${CheckCondition19}" ${tmpfile}
        if [ $? = 0 ];then
                Distri="CentOS6.6"
        fi

	grep -q "${CheckCondition20}" ${tmpfile}
        if [ $? = 0 ];then
                Distri="FC21"
        fi

	grep -q "${CheckCondition21}" ${tmpfile}
        if [ $? = 0 ];then
                Distri="FC22"
        fi

	grep -q "${CheckCondition22}" ${tmpfile}
        if [ $? = 0 ];then
                Distri="FC2X"
        fi

	grep -q "${CheckCondition23}" ${tmpfile}
        if [ $? = 0 ];then
                Distri="FC3X"
        fi
		
	rm ${tmpfile}
	return 0
}

RemindKernelHIDPatch(){
	echo ""
	echo "(W) No hid-multitouch module detected"
	echo "(W) Please follow the Programming Guide to patch hid-core source code in kernel."
	echo ""
	echo " [Y] Yes, I've patched kernel already.  [N] No, I haven't patched."
	read ans
	if [ ${ans} != "Y" -a ${ans} != "y" ];then
		echo "(I) Please patch kernel before installing driver. Thanks."
		echo ""
		exit 1
	fi
}

RemindKernelPatch(){
	echo ""
	echo "(W) You need to do kernel patch first."
	echo "(W) Please follow the Programming Guide to patch kernel."
	echo ""
	echo " [Y] Yes, I've patched kernel already.  [N] No, I haven't patched."
	read ans
	if [ ${ans} != "Y" -a ${ans} != "y" ];then
		echo "(I) Please patch kernel before installing driver. Thanks."
		echo ""
		exit 1
	fi
}

CheckXversion(){
	
	Xcommand="X -version"
	tmpfile="tmp.info"
	${Xcommand}>${tmpfile} 2>&1
	
	Xorg="X.Org X Server"
	Xversion=`grep "${Xorg}" ${tmpfile}` # ex: Xversion = X.Org X Server 1.4.0.90.3
	rm ${tmpfile}
	
	Xversion=${Xversion##${Xorg} } # 1.4.0.90.3
	Xmajor=${Xversion%%.*} # 1
	Xtmp=${Xversion#*.} # 4.0.90.3
	Xminor=${Xtmp%%.*}  # 4
	Xtmp=${Xtmp#*.} # 0.90.3
	Xrelease=${Xtmp%%.*} # 0
	echo "(I) X.Org X server ${Xmajor}.${Xminor}.${Xrelease}" # 1.4.0
	
	if [ $Xmajor -ge 1 -a $Xminor -ge 8 ] || [ $Xmajor -ge 1 -a $Xminor -ge 7 -a $Xrelease -ge 6 ];then
		echo "(I) X version is 1.7.6 upwards"
	else # kernel version is below 1.8.7
		echo "(W) X version is below 1.7.6."
		RemindKernelPatch
	fi
}

PatentConfirm(){
	echo ""
	echo "Declaration and Disclaimer
The programs, including but not limited to software and/or firmware (hereinafter referred to \"Programs\" or \"PROGRAMS\", are owned by eGalax_eMPIA Technology Inc. (hereinafter referred to EETI) and are compiled from EETI Source code. EETI hereby grants to licensee a personal, non-exclusive, non-transferable license to copy, use and create derivative works of Programs for the sole purpose in conjunction with an EETI Product, including but not limited to integrated circuit and/or controller. Any reproduction, copies, modification, translation, compilation, application, or representation of Programs except as specified above is prohibited without the express written permission by EETI.

Disclaimer: EETI MAKES NO WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, WITH REGARD TO PROGRAMS, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. EETI reserves the right to make changes without further notice to the Programs described herein. Licensee agrees that EETI does not assume any liability, damages or costs, including but not limited to attorney fees, arising out from Programs themselves or those arising out from the application or combination Programs into other products or circuit. The use or the inclusion of EETI's Programs implies that the Licensee assumes all risk of such use and in doing so indemnifies EETI against all charges, including but not limited to any claims to infringement of any third party's intellectual property right."
	
	echo ""
	if [ ${SilentMode} = "false" ]; then 
		echo "Do you agree with above patent declaration?"
		echo " [Y] Yes, I agree.  [N] No, I don't agree."
		read ans
		if [ ${ans} != "Y" -a ${ans} != "y" ];then
			exit 1
		fi
	fi
}

CheckXexist(){
	Xcommand="X -version"
	tmpfile="tmp.info"
	${Xcommand} 2>${trash} 1>${trash}
	if [ $? != 0 ];then
		Xexist="false"
		drvPkgFldrX="${drvPkgFldr}nonX"
		echo "(W) No X server detected."
	else
		drvPkgFldrX="${drvPkgFldr}withX"
		Xexist="true"
		echo "(W) X server detected."
	fi
}


AskInterface(){
	echo ""
	echo "(Q) Which interface controller do you use?"
    echo -n "(I) [1] RS232 [2] USB [3] PS2 : "
	while : ; do
		read interface
		case $interface in
			1)	interface="rs232"
				break;;
			2)	interface="usb"
				break;;
			3)	interface="ps2"
				break;;
			*)	echo "(I) Please choose [1] or [2] or [3]"
				echo -n "(A) ";;
		esac
	done
}

AskDevNums(){
	echo ""
	echo "(Q) How many controllers do you want to plug-in to system? [1-10]"
	echo -n "(I) Default [1]:"
	read nums
	echo "$nums"
	if [ -z $nums ];then
		echo "(I) Device Nums is set to 1"
	elif [ $nums -le 10 -a $nums -gt 1 ];then
		sed -i '/DeviceNums/s/1/'${nums}'/' $etcpath/$IniFile 
		echo "(I) Device Nums is set to ${nums}"
	else
		echo "(I) Device Nums is set to 1"
	fi
	
	if [ ${interface} != "rs232" ]; then
		sed -i '/ScanInterface/s/0/1/' $etcpath/$IniFile 
	fi

	if [ -e ${rclocalpathSUSE11} ]; then
		sed -i '/EventType/s/0/1/' $etcpath/$IniFile
	fi

}

AskTslib(){
	echo ""
	echo "(Q) Do you need to work with Tslib?"
	echo -n "(I) [y/N] :"
	read ans
	if [ -z $ans ];then
		echo "(I) No tslib support"
	elif [ ${ans} = "Y" -o ${ans} = "y" ];then
		sed -i '/BtnType/s/0/1/' $etcpath/$IniFile  #replace BtnType value 0 to 1 
		#sed -i '/EndOfDevice/i BtnType  	1' $etcpath/$IniFile #insert a line BtnType before EndOfDevice
	else
		echo "(I) No tslib support"
	fi
}

AskSuppotRatationMultiMonitor(){
	echo ""
	echo "(Q) Do you have requirement of monitor rotation or multi monitor?"
	echo -n "(I) [y/N] :"
	read ans
	if [ -z $ans ];then
		SupportRotationMultiMonitor="false"
	elif [ ${ans} = "Y" -o ${ans} = "y" ];then
		SupportRotationMultiMonitor="true"
	fi
}

AskSupportBeep(){
	echo ""
	echo "(Q) Do you need beep sound?"
	echo -n "(I) [y/N] :"
	read ans
	if [ -z $ans ];then
		SupportBeep="false"
	elif [ ${ans} = "Y" -o ${ans} = "y" ];then
		SupportBeep="true"
	fi
}

EnablePCSPKR(){
    if [ -w ${blacklistpath} ]; then
        grep -q "blacklist pcspkr" ${blacklistpath}
        if [ $? -eq 0 ]; then
            sed -i 's/^.*blacklist pcspkr/#blacklist pcspkr/' ${blacklistpath}
            echo "(I) Enable pcspkr from ${blacklistpath}."
        fi
    fi
}

RemovePCSPKR(){
    if [ -w ${blacklistpath} ]; then
        grep -q "#blacklist pcspkr" ${blacklistpath}
        if [ $? -eq 0 ]; then
            sed -i 's/^.*blacklist pcspkr/blacklist pcspkr/' ${blacklistpath}
            echo "(I) Restored pcspkr from ${blacklistpath}."
        fi
    fi
}

InstallUdevRule(){
	if [ -e ${udevpath} ];then 
		cp -f "Rule/${udevfile}" ${udevpath}
		chmod a+x ${udevpath}/${udevfile}
		echo "(I) Copy ${udevfile} to ${udevpath}."
	fi
}

RemoveUdevRule(){
	if [ -e ${udevpath}/${udevfile} ];then  
		rm ${udevpath}/${udevfile}
		echo "(I) Removed ${udevpath}/${udevfile}"
	fi
}

if [ $# = 0 ]; then
	SilentMode="false"
	clear
	ShowTitle
	CheckPermission
	CheckCpuType
	InitMember
	CheckXexist
	if [ $Xexist = "true" ];then
		GetDistribution
	fi
	AllotRClocalPath
	PatentConfirm
	AskInterface
	pause
	#CheckRClocalExist
	
	CheckUinput
	InstallDriverRoutine
	InstallUdevRule
	
	AskSuppotRatationMultiMonitor
	if [ $SupportRotationMultiMonitor = "true" ];then
		CheckLightDMExist
		if [ $lightdmexist = "false" ];then
			echo "(E) Please install lightdm module and re-install driver again."
			exit 1
		fi
		echo "(I) Please assign MonitorName in /etc/eGTouchL.ini. ex:\"eDP-1\"  ,you can check monitor name by command \"xrandr\"."
		echo "(I) Press [Enter] key to continue.........."
		read DISCARD
		
		AskSupportBeep
		if [ $SupportBeep = "true" ];then
			EnablePCSPKR
		fi
	else
		CheckRCExist
	fi
	
	if [ $interface = "usb" ];then
		CheckUSBType
		CheckUSBPIDnKernel
		CheckHIDRAW
		if [ $Xexist = "true" ];then
			CheckXversion
		else
			RemindKernelPatch
		fi
	elif [ $interface = "ps2" ];then
		SetPS2Config
	fi


	if [ -e ${systemctlpath} ]; then
		echo "(I) Found ${systemctlpath} path for systemd service"
	else
		ModifyRClocal
	fi

	AskDevNums
	if [ $Xexist = "true" ];then
		AttachUdevRule # Append udev rule onto X.org
		AddUtilityShortCut	# Add/Remove ShortCut
	else
		AskTslib
	fi

	if [ -e ${systemdpath}/${daemonService} ]; then
		systemctl start eGTouchD.service
		systemctl enable eGTouchD.service
	elif [ -e ${usrbinpath}/${driverEXE} ]; then
		${usrbinpath}/${driverEXE} -f
	fi
	
	if [ $SupportRotationMultiMonitor = "true" ];then
		sleep 1
		sed -i '/DetectRotation/s/0/1/' $etcpath/$IniFile
		
		if [ -e ${systemdpath} ];then
			#echo "(I) Put resume service in system"
			cp "Rule/${resumeService}" ${systemdpath} 
			chmod a+x ${systemdpath}/${resumeService}
			systemctl enable ${resumeService}
		fi
	fi

	echo ""
	echo "(I) Driver installation completed. Setup version $Script_Ver."
	echo "(I) Please reboot the system."
	
elif [ $# -ge 1 ]; then
	if [ $1 = "uninstall" ]; then
		SilentMode="false"
		clear
		ShowTitle
		CheckPermission
		CheckCpuType
		InitMember
		CheckXexist
		if [ $Xexist = "true" ];then
			GetDistribution
		fi
		AllotRClocalPath

        	echo "(I) Begin to remove ${drivername} driver."
		RemoveDriver
		RemoveUtilityShortCut # Add/Remove Utility ShortCut
		RemoveLightDMSetting
		RemoveRCSetting
		RemovePCSPKR
		RemoveUdevRule
		
		if [ -e ${systemdpath}/${resumeService} ];then
			#echo "(I) Remove resume service"
			systemctl disable ${resumeService}
			rm "${systemdpath}/${resumeService}"
		fi
        	echo ""
        	echo "(I) The ${drivername} driver has been removed successfully."
        	echo "(I) Please reboot the system."
	elif [ $1 = "-silent" ] || [ $1 = "silent" ]; then
		SilentMode="true"
		clear
		ShowTitle
		CheckPermission
		CheckCpuType
		InitMember
		CheckXexist
		if [ $Xexist = "true" ];then
			GetDistribution
		fi
		AllotRClocalPath
		PatentConfirm
			#AskInterface
		CheckUinput
		InstallDriverRoutine
		InstallUdevRule
			#AskSuppotRatationMultiMonitor
		CheckRCExist

		if [ $interface = "usb" ];then
			CheckUSBType
			CheckUSBPIDnKernel
			CheckHIDRAW
			if [ $Xexist = "true" ];then
				CheckXversion
			else
				RemindKernelPatch
			fi
		elif [ $interface = "ps2" ];then
			SetPS2Config
		fi
		
		if [ -e ${systemctlpath} ]; then
			echo "(I) Found ${systemctlpath} path for systemd service"
		else
			ModifyRClocal
		fi
				
			#AskDevNums

		if [ $Xexist = "true" ];then
			AttachUdevRule # Append udev rule onto X.org
			AddUtilityShortCut	# Add/Remove ShortCut
		else
			AskTslib
		fi
		# Setting Device Nums Here
		if [ $# -ge 2 ]; then
			if [ $2 = "dev" ]||[ $2 = "-dev" ]; then 
				nums=$3
				sed -i '/DeviceNums/s/1/'${nums}'/' $etcpath/$IniFile
			fi
		fi

		if [ ${interface} != "rs232" ]; then
			sed -i '/ScanInterface/s/0/1/' $etcpath/$IniFile 
		fi		
		
		if [ -e ${systemdpath}/${daemonService} ]; then
			systemctl start eGTouchD.service
			systemctl enable eGTouchD.service
		elif [ -e ${usrbinpath}/${driverEXE} ]; then
			${usrbinpath}/${driverEXE} -f
		fi
	
	echo ""
	echo "(I) Driver installation completed. Setup version $Script_Ver."
	echo "(I) Please reboot the system."
	
		
		# Start eGTouchD
		#/usr/bin/eGTouchD -f			
		
	else
		echo "(I) Usage:"
		echo "(I) sh $0:           install driver package"
		echo "(I) sh $0 uninstall: uninstall driver package"
	fi
else
	echo "(I) Usage:"
	echo "(I) sh $0:           install driver package"
	echo "(I) sh $0 uninstall: uninstall driver package"
fi

echo ""

