#!/bin/bash

# Set basic variables
DATE=$(date --iso-8601)
REC_DIR=~/nmap-scans/

# Create scan dir

test -d $REC_DIR || mkdir -p $REC_DIR

# Declare functions

nmap_android_termux ()
{
	TERMUX_WIFI_INFO=$(termux-wifi-connectioninfo)
	SSID="$(echo "$TERMUX_WIFI_INFO" | jq '.ssid' -r)"
	MAC=$(echo "$TERMUX_WIFI_INFO" | jq '.bssid' -r)
	SAFE_MAC="$(echo "$MAC" | tr -d :)"
	LOCAL_IP=$(echo "$TERMUX_WIFI_INFO" | jq '.ip' -r)
	IP=$(ip route | tail -n1 | cut -d " " -f 1)

	echo "ESSID: $SSID"
	echo "BSSID: $MAC"
	echo "Safe MAC: $SAFE_MAC"
	echo "Network: $IP"
	echo "Local IP: $LOCAL_IP"

	nmap -T4 -sV -v -F --open --version-light -oX "$1/${SAFE_MAC}_$2.xml" --exclude "$LOCAL_IP" "$IP"
}

nmap_android ()
{
	echo "Not yet implemented"
	exit
}

nmap_linux ()
{
	if [[ $EUID -ne 0 ]]; then
		echo "You need to run this as root." 
		exit 1
	fi

	NMCLI_CONTENT="$(nmcli -t -e no -f active,ssid,bssid dev wifi | grep "yes")"
	#SSID="$(echo "$NMCLI_CONTENT" | cut -d ":" -f 2)"
	MAC="$(echo "$NMCLI_CONTENT" | cut -d ":" -f 3-)"
	SAFE_MAC="$(echo "$MAC" | tr -d :)"
	IP=$(ip route | tail -n1 | cut -d " " -f 1)
	LOCAL_IP=$(hostname -I | awk '{print $1}')

	echo "Current network info"
	#echo "SSID:	$SSID"
	echo "MAC:	$MAC"

	echo "Starting nmap scan..."

	nmap -T4 -Sv -v -F -O --open --version-light -oX "$1/${SAFE_MAC}_$2.xml" --exclude "$LOCAL_IP" "$IP"

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
}

# Start

# Determine environment (Termux)

if uname -a | grep -i Android; then
	#echo "We are on Android"
	if echo $PREFIX | grep -i termux; then
		#echo "We are in Termux"
		nmap_android_termux $REC_DIR $DATE
	else
		#echo "We are probably not in Termux"
		nmap_android $REC_DIR $DATE
	fi
else
	#echo "We are not on Android"
	#TODO: Also determine if running in WSL
	nmap_linux $REC_DIR $DATE
fi
