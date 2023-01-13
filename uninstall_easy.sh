#!/bin/sh

# automated script for easy uninstalling zapret

EXEDIR="$(dirname "$0")"
EXEDIR="$(cd "$EXEDIR"; pwd)"
IPSET_DIR="$EXEDIR/ipset"
ZAPRET_CONFIG="$EXEDIR/config"
ZAPRET_BASE="$EXEDIR"

. "$ZAPRET_CONFIG"
. "$ZAPRET_BASE/common/base.sh"
. "$ZAPRET_BASE/common/elevate.sh"
. "$ZAPRET_BASE/common/fwtype.sh"
. "$ZAPRET_BASE/common/dialog.sh"
. "$ZAPRET_BASE/common/ipt.sh"
. "$ZAPRET_BASE/common/nft.sh"
. "$ZAPRET_BASE/common/pf.sh"
. "$ZAPRET_BASE/common/installer.sh"

remove_systemd()
{
	clear_ipset
	service_stop_systemd
	service_remove_systemd
	timer_remove_systemd
	nft_del_table
	crontab_del
}

remove_openrc()
{
	clear_ipset
	service_remove_openrc
	nft_del_table
	crontab_del
}

remove_linux()
{
	INIT_SCRIPT_SRC="$EXEDIR/init.d/sysv/zapret"

	clear_ipset

	echo \* executing sysv init stop
	"$INIT_SCRIPT_SRC" stop
	
	nft_del_table
	crontab_del

	echo
	echo '!!! WARNING. YOUR UNINSTALL IS INCOMPLETE !!!'
	echo 'you must manually remove zapret auto start from your system'
}

remove_openwrt()
{
	OPENWRT_FW_INCLUDE=/etc/firewall.zapret

	clear_ipset
	service_remove_sysv
	remove_openwrt_firewall
	remove_openwrt_iface_hook
	nft_del_table
	restart_openwrt_firewall
	crontab_del
}

remove_macos()
{
	remove_macos_firewall
	service_remove_macos
	crontab_del
}

remove_keenetic()
{
  KEENETIC_NETFILTER_HOOK_DST=/opt/etc/ndm/netfilter.d/zapret.sh

  clear_ipset
  remove_keenetic_netfilter_hook
  service_remove_keenetic
  nft_del_table
  crontab_del
}


fix_sbin_path
check_system
require_root

[ "$SYSTEM" = "macos" ] && . "$EXEDIR/init.d/macos/functions"

case $SYSTEM in
	systemd)
		remove_systemd
		;;
	openrc)
		remove_openrc
		;;
	linux)
		remove_linux
		;;
	openwrt)
		remove_openwrt
		;;
	macos)
		remove_macos
		;;
	keenetic)
		remove_keenetic
		;;
esac


exitp 0
