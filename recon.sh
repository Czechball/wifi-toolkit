#!/bin/bash

# Determine environment (Termux)

if uname -a | grep -i Android; then
	echo "We are on Android"
	if echo $PREFIX | grep -i termux; then
		echo "We are in Termux"
	else
		echo "We are probably not in Termux"
	fi
fi

exit

if [[ $EUID -ne 0 ]]; then
   echo "You need to run this as root." 
   exit 1
fi

DATE=$(date '+%F_%H-%M-%S')
NMCLI_CONTENT="$(nmcli -t -e no -f active,ssid,bssid dev wifi | grep "yes")"
SSID="$(echo "$NMCLI_CONTENT" | cut -d ":" -f 2)"
MAC="$(echo "$NMCLI_CONTENT" | cut -d ":" -f 3-)"
SAFE_MAC="$(echo "$MAC" | tr -d :)"
IP=$(ip route | tail -n1 | cut -d " " -f 1)
REC_DIR="scans/scan-$DATE-$SSID-$SAFE_MAC"

echo "Current network info"
echo "SSID:	$SSID"
echo "MAC:	$MAC"

echo "Creating work directory $REC_DIR..."

mkdir -p "$REC_DIR"

echo "Starting nmap scan..."

nmap -T4 -v -F -O --open -oX "$REC_DIR/nmap.xml" "$IP"

echo "Checking internet connectivity..."

if ping -q -c5 -w30 8.8.8.8; then
	echo Internet connectivity: Yes
	EXTERNAL_IP=$(curl ip.me)
	echo "External IP: $EXTERNAL_IP"
	ONLINE="yes"
else
	echo Internet connectivity: No
	ONLINE="no"
fi
echo "Recon finished, writing to recon-log.csv ..."
echo "$DATE,$MAC,$IP,$EXTERNAL_IP,$ONLINE" > "$REC_DIR"/net-info.csv
echo "$DATE,$MAC,$IP,$EXTERNAL_IP,$ONLINE" >> ./scan_log.csv
echo "done"
