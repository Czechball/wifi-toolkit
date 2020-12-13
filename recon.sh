#!/bin/bash
DATE=$(date '+%F_%H-%M-%S')
NMCLI_CONTENT="$(nmcli -t -e no -f active,ssid,bssid dev wifi | grep "yes")"
SSID="$(echo "$NMCLI_CONTENT" | cut -d ":" -f 2)"
MAC="$(echo "$NMCLI_CONTENT" | cut -d ":" -f 3-)"
SAFE_MAC="$(echo "$MAC" | tr -d :)"
IP=$(ip route | tail -n1 | cut -d " " -f 1)
REC_DIR="recon-$DATE-$SSID-$SAFE_MAC"

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
else
	echo Internet connectivity: No
fi
echo "Recon finished, writing to recon-log.csv ..."
echo "$DATE,$MAC,$IP,$EXTERNAL_IP" >> "$HOME"/Documents/recon-log.csv
echo "done"
