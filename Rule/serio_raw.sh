#!/bin/sh -e
# /etc/init.d/serio_raw: set up serio_raw kernel driver for PS2 aux port.
### BEGIN INIT INFO
# Provides:          serio_raw
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     S
# Default-Stop:
### END INIT INFO

# Example
# echo -n "serio_raw" > /sys/bus/serio/devices/serioX/drvctl


exit 0
