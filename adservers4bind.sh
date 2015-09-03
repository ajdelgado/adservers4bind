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
SITES=( "http://winhelp2002.mvps.org/hosts.txt" "http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts;showintro=0" "https://localhost/blacklist/domains.txt")
#SITES=( "http://localhost/hosts.txt" )
CDATE=`date +%Y%m%d%H%M%S`
for SITE in ${SITES[*]}
do
	TMPFILE=`mktemp /tmp/tmp.sitecontent.XXXXXXX`
	wget -q -O "$TMPFILE" "$SITE"
	dos2unix -q "$TMPFILE"
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
ADBLOCKSITES=( "http://mirror1.malwaredomains.com/files/domains.txt" )
for SITE in ${ADBLOCKSITES[*]}
do
	TMPFILE=`mktemp /tmp/tmp.sitecontent.XXXXXXX`
	wget -q -O "$TMPFILE" "$SITE"
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
rm "$BINDCFGPATH/adservers.conf"
cat "$BINDCFGPATH/adservers.conf.$CDATE" | tr "[:upper:]" "[:lower:]"| sort | uniq > "$BINDCFGPATH/adservers.conf"
echo "\$TTL 24h
@       IN SOA localhost.localdomain. localhost.localdomain. (
                  2003052800  86400  300  604800  3600 )
@       IN      NS   localhost.localdomain.
@       IN      A    127.0.0.1
*       IN      A    127.0.0.1" > "$BINDCFGPATH/dummy-block.conf"
service bind9 restart &> /dev/null

