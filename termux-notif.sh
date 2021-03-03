#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" || { echo -e "\e[91mERROR\e[0m: Script path cannot be found" ; exit 1; } >/dev/null 2>&1 ; pwd -P )"
TERMUX_WIFI_INFO=$(termux-wifi-connectioninfo)
SSID="$(echo "$TERMUX_WIFI_INFO" | jq '.ssid' -r)"
MAC=$(echo "$TERMUX_WIFI_INFO" | jq '.bssid' -r)
SAFE_MAC="$(echo "$MAC" | tr -d :)"
LOCAL_IP=$(echo "$TERMUX_WIFI_INFO" | jq '.ip' -r)
IP=$(ip route | tail -n1 | cut -d " " -f 1)

termux-notification --alert-once --ongoing -i 1 -c "SSID: $SSID - MAC: $MAC" -t "LMG Nmap" --button1 "Scan" --button1-action "bash $SCRIPTPATH/recon.sh" --button2 "Refresh" --button2-action "bash $SCRIPTPATH/$0" --button3 "Stop" --button3-action "termux-notification-remove 1"
