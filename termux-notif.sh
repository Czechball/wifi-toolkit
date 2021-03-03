#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" || exit 1; } >/dev/null 2>&1 ; pwd -P )"
TERMUX_WIFI_INFO=$(termux-wifi-connectioninfo)
SSID="$(echo "$TERMUX_WIFI_INFO" | jq '.ssid' -r)"
MAC=$(echo "$TERMUX_WIFI_INFO" | jq '.bssid' -r)

termux-notification --alert-once --ongoing -i 1 -c "SSID: $SSID - MAC: $MAC" -t "LMG Nmap" --button1 "Scan" --button1-action "bash $SCRIPTPATH/recon.sh" --button2 "Refresh" --button2-action "bash $SCRIPTPATH/$0" --button3 "Stop" --button3-action "termux-notification-remove 1"
