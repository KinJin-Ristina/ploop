#!/bin/sh

export PATH="/usr/bin:/usr/sbin:/bin:/sbin"
CRYPTSETUP=/usr/sbin/cryptsetup

loadkey()
{
	local id=$(keyctl request2 user vdisk:$KEYID '' @u)
	[ -z "$id" ] && exit 1
	KEY=`keyctl print $id | sed 's/^:hex://'`
}

init()
{
	loadkey
	echo -n "$KEY" | $CRYPTSETUP luksFormat $DEVICE -
	if [ $? -ne 0 ]; then
		echo "Cannot format $DEVICE"
		exit 1
	fi
}

open()
{
	loadkey
	echo -n "$KEY" | $CRYPTSETUP --allow-discards luksOpen $DEVICE $DEVICE_NAME
	if [ $? -ne 0 ]; then
		echo "Cannot open $DEVICE $DEVICE_NAME"
		exit 1
	fi
}

close()
{
	$CRYPTSETUP luksClose $DEVICE_NAME
	if [ $? -ne 0 ]; then
		echo "Cannot close $DEVICE_NAME"
		exit 1
	fi
}

resize()
{
	
	$CRYPTSETUP resize $DEVICE_NAME
	if [ $? -ne 0 ]; then
		echo "Cannot resize $DEVICE_NAME"
		exit 1
	fi
}

changekey()
{
	loadkey
	CUR_KEY=$KEY
	# load new key
	KEYID=$DEVICE_NAME
	loadkey
	echo -n "${CUR_KEY}
${KEY}" | $CRYPTSETUP luksChangeKey $DEVICE -
	if [ $? -ne 0 ]; then
		echo "Cannot change key $KEYID"
		exit 1
	fi
}

case "$1" in
init)
	init
	;;
open)
	open
	;;
resize)
	resize
	;;
close)
	close
	;;
changekey)
	changekey
	;;
*)
	exit 1
esac
