#!/bin/bash

# Set basic variables
DATE=$(date --iso-8601)
INTERFACE="$1"
SCRIPTPATH="$( cd "$(dirname "$0")" || { echo -e "\e[91mERROR\e[0m: Script path cannot be found" ; exit 1; } >/dev/null 2>&1 ; pwd -P )"
REC_DIR="$SCRIPTPATH"
RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

# Create scan dir

test -d "$REC_DIR" || mkdir -p "$REC_DIR"

# Declare functions

nmap_android_termux ()
{
	TERMUX_WIFI_INFO=$(termux-wifi-connectioninfo)
	SSID="$(echo "$TERMUX_WIFI_INFO" | jq '.ssid' -r)"
	MAC=$(echo "$TERMUX_WIFI_INFO" | jq '.bssid' -r)
	SAFE_MAC="$(echo "$MAC" | tr -d :)"
	IP=$(echo "$TERMUX_WIFI_INFO" | jq '.ip' -r)
	LOCAL_IP=$(ip route | tail -n1 | cut -d " " -f 1)

	echo "Current network info:"
	echo -e "ESSID:	${GREEN}$SSID${ENDCOLOR}"
	echo -e "BSSID:	${GREEN}$MAC${ENDCOLOR}"
	echo -e "Network:	${GREEN}$IP${ENDCOLOR}"
	echo -e "Local IP:	${GREEN}$LOCAL_IP${ENDCOLOR}"

	nmap -T4 -sV -v -F --open --version-light -oX "$1/${SAFE_MAC}_$2.xml" --exclude "$LOCAL_IP" "$IP"
}

nmap_android ()
{
	echo -e "${RED}Not yet implemented${ENDCOLOR}"
	exit 1
}

nmap_linux ()
{
	if [[ $EUID -ne 0 ]]; then
		echo -e "${RED}You need to run this as root.${ENDCOLOR}" 
		exit 1
	fi

	SSID="$(iw dev "$INTERFACE" link | awk -F: '/SSID/ {print $NF}' | awk '{ sub(/ /,""); print }')"
	#MAC="$(iw dev "$INTERFACE" info | grep addr | cut -d " " -f 2)" uh this is wrong
	MAC="$(iw dev "$INTERFACE" link | head -n 1 | cut -d " " -f 3)"
	SAFE_MAC="$(echo "$MAC" | tr -d :)"
	IP=$(ip a | grep "$INTERFACE" | grep inet | cut -d " " -f 6)
	LOCAL_IP=${IP%/*}

	echo "Current network info:"
	echo -e "SSID:		${GREEN}$SSID${ENDCOLOR}"
	echo -e "MAC:		${GREEN}$MAC${ENDCOLOR}"
	echo -e "Local IP:	${GREEN}$LOCAL_IP${ENDCOLOR}"
	echo -e "IP:		${GREEN}$IP${ENDCOLOR}"
	echo -n "Internet connectivity: "

	if ping -I "$INTERFACE" -q -c5 -w30 8.8.8.8 > /dev/null; then
		echo -e "${GREEN}Yes${ENDCOLOR}"
		EXTERNAL_IP=$(curl --interface "$INTERFACE" -s ip.me)
		echo -e "External IP:	${GREEN}$EXTERNAL_IP${ENDCOLOR}"
		ONLINE=true
	else
		echo -e "${RED}No${ENDCOLOR}"
		ONLINE=false
	fi

	printf '%s,%s,%s,%s,%s\n' "$MAC" "$IP" "$LOCAL_IP" "$ONLINE" "$EXTERNAL_IP" >> "$SAFE_MAC"_log.csv

	nmap -e "$INTERFACE" -T4 -sV -v -F -O --open --version-light -oX "$1/${SAFE_MAC}_$2.xml" --exclude "$LOCAL_IP" "$IP"
}

# Start

# Determine environment (Termux)

if uname -a | grep -i Android; then
	#echo "We are on Android"
	if echo "$PREFIX" | grep -i termux; then
		nmap_android_termux "$REC_DIR" "$DATE"
	else
		if [ -z "$INTERFACE" ]; then
		echo "Error, wireless interface not set. Usage: $0 <interface>"
		exit 1
		fi
		nmap_android "$REC_DIR" "$DATE"
	fi
else
	#TODO: Also determine if running in WSL
	if [ -z "$INTERFACE" ]; then
		echo "Error, wireless interface not set. Usage: $0 <interface>"
		exit 1
	fi
	nmap_linux "$REC_DIR" "$DATE"
fi
