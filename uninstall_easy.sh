#!/bin/sh

# automated script for easy uninstalling zapret on systemd based system

[ $(id -u) -ne "0" ] && {
	echo root is required
   which sudo >/dev/null && exec sudo $0
   which su >/dev/null && exec su -c $0
	echo su or sudo not found
	exit 2
}

SCRIPT=$(readlink -f $0)
EXEDIR=$(dirname $SCRIPT)
LSB_INSTALL=/usr/lib/lsb/install_initd
LSB_REMOVE=/usr/lib/lsb/remove_initd
INIT_SCRIPT_SRC=$EXEDIR/init.d/debian/zapret
INIT_SCRIPT=/etc/init.d/zapret
GET_IPLIST_PREFIX=$EXEDIR/ipset/get_

echo \* checking system ...

SYSTEMCTL=$(which systemctl)
[ ! -x "$SYSTEMCTL" ] && {
	echo not systemd based system
	exit 5
}

echo \* stopping service and unregistering init script with LSB ...

"$SYSTEMCTL" stop zapret
[ -f "$INIT_SCRIPT" ] && "$LSB_REMOVE" $INIT_SCRIPT

echo \* removing init script ...

script_mode=Y
[ -f "$INIT_SCRIPT" ] &&
{
	cmp -s $INIT_SCRIPT $INIT_SCRIPT_SRC ||
	{
		echo $INIT_SCRIPT already exists and differs from $INIT_SCRIPT_SRC
		echo Y = remove it
		echo L = leave it
		read script_mode
	}
	if [ "$script_mode" = "Y" ] || [ "$script_mode" = "y" ]; then
		rm -vf $INIT_SCRIPT
	fi
}

echo \* removing crontab entry ...

CRONTMP=/tmp/cron.tmp
crontab -l >$CRONTMP
if grep -q "$GET_IPLIST_PREFIX" $CRONTMP; then
	echo removing following entries from crontab :
	grep "$GET_IPLIST_PREFIX" $CRONTMP
	grep -v "$GET_IPLIST_PREFIX" $CRONTMP >$CRONTMP.2
	crontab $CRONTMP.2
	rm -f $CRONTMP.2
fi
rm -f $CRONTMP

exit 0