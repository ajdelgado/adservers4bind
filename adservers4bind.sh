#!/bin/bash
#
# adservers4bind.sh
#
# Description: Download a list of hosts files with servers that
# provide ads to be blocked using the BIND9 service in this machine.
# based on http://www.deer-run.com/~hal/sysadmin/dns-advert.html
# You need to include in your BIND configuration:
# include "/etc/bind/adservers.conf";
#
BINDCFGPATH="/etc/bind/"
CDATE=`date +%Y%m%d%H%M%S`
DOS2UNIX=`whereis dos2unix | awk '{print($2)}'`
WGET=`whereis wget | awk '{print($2)}'`
if [[ ! -x $DOS2UNIX ]]; then
	echo "I couldn't find dos2unix, please install it."
	echo "In Debian/Ubuntu distributions: sudo apt-get install dos2unix"
	exit 1
fi
if [[ ! -x $WGET ]]; then
	echo "I couldn't find wget, please install it."
	echo "In Debian/Ubuntu distributions: sudo apt-get install wget"
	exit 2
fi
#List of domains separated by spaces, with domain in second columns in DOS file mode (usually for hosts file in Windows machine)
SITES=( "http://winhelp2002.mvps.org/hosts.txt" "http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts;showintro=0" "https://localhost/blacklist/domains.txt")
for SITE in ${SITES[*]}
do
	TMPFILE=`mktemp /tmp/tmp.sitecontent.XXXXXXX`
	$WGET -q -O "$TMPFILE" "$SITE"
	$DOS2UNIX -q "$TMPFILE"
	cat "$TMPFILE" | awk 'BEGIN {FS="#"} {print($1)}' | grep -v "\"" | while read SRVLINE
	do
		if [[ "$SRVLINE" != "" ]]; then
			ADSRVNAME=`echo "$SRVLINE" | awk '{print($2)}'`
			#echo "Adding server $ADSRVNAME from '$SRVLINE'"
			if [[ "$ADSRVNAME" != "" ]] && [[ "$ADSRVNAME" != "localhost" ]]; then
				echo "   zone \"$ADSRVNAME\" { type master; file \"$BINDCFGPATH/dummy-block.conf\"; };" >> "$BINDCFGPATH/adservers.conf.$CDATE"
			fi
		fi
	done
done
#List of domains separated by spaces, with domain in second columns in Unix file mode (usually for list for adblock browser plugins)
ADBLOCKSITES=( "http://mirror1.malwaredomains.com/files/domains.txt" )
for SITE in ${ADBLOCKSITES[*]}
do
	TMPFILE=`mktemp /tmp/tmp.sitecontent.XXXXXXX`
	$WGET -q -O "$TMPFILE" "$SITE"
	cat "$TMPFILE" | awk '{BEGIN {FS="#"} {print($1)}' | awk '{print($1)}' | while read SRVLINE
	do
                if [[ "$SRVLINE" != "" ]]; then
                        ADSRVNAME=`echo "$SRVLINE" | awk '{print($2)}'`
                        #echo "Adding server $ADSRVNAME from '$SRVLINE'"
                        if [[ "$ADSRVNAME" != "" ]] && [[ "$ADSRVNAME" != "localhost" ]]; then
                                echo "   zone \"$ADSRVNAME\" { type master; file \"$BINDCFGPATH/dummy-block.conf\"; };" >> "$BINDCFGPATH/adservers.conf.$CDATE"
                        fi
                fi
	done
done
#Deleting previous configuration file
rm "$BINDCFGPATH/adservers.conf"
#Copying new configuration file with date to the configuration file in Bind's configuration
cat "$BINDCFGPATH/adservers.conf.$CDATE" | tr "[:upper:]" "[:lower:]"| sort | uniq > "$BINDCFGPATH/adservers.conf"
echo "\$TTL 24h
@       IN SOA localhost.localdomain. localhost.localdomain. (
                  2003052800  86400  300  604800  3600 )
@       IN      NS   localhost.localdomain.
@       IN      A    127.0.0.1
*       IN      A    127.0.0.1" > "$BINDCFGPATH/dummy-block.conf"
service bind9 restart &> /dev/null
exit $?
