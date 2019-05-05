#!/bin/sh

# automated script for easy installing zapret on systemd based system
# all required tools must be already present or system must use apt as package manager
# if its not apt based system then manually install ipset, curl, lsb-core

[ $(id -u) -ne "0" ] && {
	echo root is required
	which sudo >/dev/null && exec sudo $0
	which su >/dev/null && exec su -c $0
	echo su or sudo not found
	exit 2
}

SCRIPT=$(readlink -f $0)
EXEDIR=$(dirname $SCRIPT)
ZAPRET_BASE=/opt/zapret
LSB_INSTALL=/usr/lib/lsb/install_initd
LSB_REMOVE=/usr/lib/lsb/remove_initd
INIT_SCRIPT_SRC=$EXEDIR/init.d/debian/zapret
INIT_SCRIPT=/etc/init.d/zapret
GET_IPLIST=$EXEDIR/ipset/get_antizapret.sh
GET_IPLIST_PREFIX=$EXEDIR/ipset/get_


exitp()
{
	echo
	echo press enter to continue
	read A
	exit $1
}


echo \* checking system ...

SYSTEMCTL=$(which systemctl)
[ ! -x "$SYSTEMCTL" ] && {
	echo not systemd based system
	exitp 5
}


echo \* checking location ...

[ "$EXEDIR" != "$ZAPRET_BASE" ] && {
	echo easy install is supported only from default location : $ZAPRET_BASE
	echo currenlty its run from $EXEDIR
	echo -n "do you want the installer to copy it for you (Y/N) ? "
	read A
	if [ "$A" = "Y" ] || [ "$A" = "y" ]; then
		if [ -d "$ZAPRET_BASE" ]; then
			echo installer found existing $ZAPRET_BASE
			echo -n "do you want to delete all files there and copy this version (Y/N) ? "
			read A
			if [ "$A" = "Y" ] || [ "$A" = "y" ]; then
				rm -r "$ZAPRET_BASE"
			else
				echo refused to overwrite $ZAPRET_BASE. exiting
				exitp 3
			fi
		fi
		cp -R $EXEDIR $ZAPRET_BASE
		echo relaunching itself from $ZAPRET_BASE
		exec $ZAPRET_BASE/$(basename $0)
	else
		echo copying aborted. exiting
		exitp 3
	fi
}
echo running from $EXEDIR


echo \* checking prerequisites ...

if [ ! -x "$LSB_INSTALL" ] || [ ! -x "$LSB_REMOVE" ] || ! which ipset >/dev/null || ! which curl >/dev/null ; then
	echo \* installing prerequisites ...

	APTGET=$(which apt-get)
	[ ! -x "$APTGET" ] && {
		echo not apt based system
		exitp 5
	}
	"$APTGET" update
	"$APTGET" install -y --no-install-recommends ipset curl lsb-core dnsutils || {
		echo could not install prerequisites
		exitp 6
	}
	[ ! -x "$LSB_INSTALL" ] || [ ! -x "$LSB_REMOVE" ] && {
		echo lsb install scripts not found
		exitp 7
	}
else
	echo everything is present
fi

echo \* installing binaries ...

"$EXEDIR/install_bin.sh"


echo \* installing init script ...

"$SYSTEMCTL" stop zapret 2>/dev/null

script_mode=Y
[ -f "$INIT_SCRIPT" ] &&
{
	cmp -s $INIT_SCRIPT $INIT_SCRIPT_SRC ||
	{
		echo $INIT_SCRIPT already exists and differs from $INIT_SCRIPT_SRC
		echo Y = overwrite with new version 
		echo N = exit
		echo L = leave current version and continue
		read script_mode
		case "${script_mode}" in
			Y|y|L|l)
				;;
			*)
				echo aborted
				exitp 3
				;;
		esac
	}
}

if [ "$script_mode" = "Y" ] || [ "$script_mode" = "y" ]; then
	echo -n "copying : "
	cp -vf $INIT_SCRIPT_SRC $INIT_SCRIPT
fi


echo \* registering init script ...

"$LSB_REMOVE" $INIT_SCRIPT
"$LSB_INSTALL" $INIT_SCRIPT || {
	echo could not register $INIT_SCRIPT with LSB
	exitp 20
}


echo \* downloading blocked ip list ...

"$GET_IPLIST" || {
	echo could not download ip list
	exitp 25
}


echo \* adding crontab entry ...

CRONTMP=/tmp/cron.tmp
crontab -l >$CRONTMP
if grep -q "$GET_IPLIST_PREFIX" $CRONTMP; then
	echo some entries already exist in crontab. check if this is corrent :
	grep "$GET_IPLIST_PREFIX" $CRONTMP
else
	echo "0 12 * * */2 $GET_IPLIST" >>$CRONTMP
	crontab $CRONTMP
fi

rm -f $CRONTMP


echo \* starting zapret service ...

systemctl start zapret || {
	echo could not start zapret service
	exitp 30
}

exitp 0
