#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo -e "${RED}You need to run this as root.${ENDCOLOR}" 
	exit 1
fi

RED=$(tput setaf 3)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
NORMAL=$(tput sgr0)

SCRIPTPATH="$( cd "$(dirname "$0")" || { echo -e "\e[91mERROR\e[0m: Script path cannot be found" ; exit 1; } >/dev/null 2>&1 ; pwd -P )"
CONFIGFILE="$SCRIPTPATH"/config.txt
DBFILENAME="wpa420db.json"
DBFILE="$SCRIPTPATH"/"$DBFILENAME"
INTERFACE="$1"
WPA_CONFIG=$(mktemp)

if [ -z "$INTERFACE" ]; then
	echo "Error, wireless interface not set. Usage: $0 <interface>"
	exit 1
fi

source "$CONFIGFILE" || { echo -e "\e[91mERROR\e[0m: $CONFIGFILE doesn't exist in script path" ; exit 1; }

update_db ()
{
	echo -e "Updating database..."
	curl -H "Authorization: $WPA420_TOKEN" "$WPA420_BACKEND"/api/mobapp/getCollection -o "$DBFILE" || { echo -e "\e[91mERROR\e[0m: Database file couldn't be downloaded."; return 1; }
}

scan_loop ()
{
	echo -e "Initiating network scan..."
	SCAN_RESULT=$(wpa_cli scan -i "$INTERFACE")
	while [[ $SCAN_RESULT == "FAIL-BUSY" ]]; do
		echo -e "wpa_cli returned FAIL-BUSY, waiting for 5 seconds..."
		sleep 5
		SCAN_RESULT=$(wpa_cli scan -i "$INTERFACE")
	done
}

get_nearby ()
{
	mapfile -t FOUNDS < <(wpa_cli scan_results -i "$INTERFACE" | tail -n +2)
}

compare_nearby ()
{
	JQ_BEGIN='jq "[.[] |'
	JQ_MIDDLE1=' select(.MAC==\"'
	#JQ_MIDDLE2='\"),'
	JQ_MIDDLE2='\") + {\"signal\": \"'
	JQ_MIDDLE3='\", \"frequency\": \"'
	JQ_MIDDLE4='\"},'
	JQ_END="]\" $DBFILE"

	OUTPUT_MACS=""
	OUTPUT_FREQS=""
	OUTPUT_SIGNALS=""

	for NEARBY in "${FOUNDS[@]}"; do
			NEARBY_MAC=$(echo "$NEARBY" | cut -f "1")
			NEARBY_FREQ=$(echo "$NEARBY" | cut -f "2")
			NEARBY_SIGNAL=$(echo "$NEARBY" | cut -f "3")
			UPPER_MAC=${NEARBY_MAC^^*}
			OUTPUT_MACS+=( "$UPPER_MAC" )
			OUTPUT_FREQS+=( "$NEARBY_FREQ" )
			OUTPUT_SIGNALS+=( "$NEARBY_SIGNAL" )
	done

	C=1
	JQ_CMD+=$(printf '%s' "$JQ_BEGIN")
	for MAC in "${OUTPUT_MACS[@]}"; do
		if [[ $C == "${#OUTPUT_MACS[@]}" ]]; then
			#JQ_MIDDLE2='\")'
			JQ_MIDDLE4='\"}'
		fi
		D=$((C - 1))
		JQ_CMD+=$(printf '%s%s%s%s%s%s%s' "$JQ_MIDDLE1" "$MAC" "$JQ_MIDDLE2" "${OUTPUT_SIGNALS[$D]}" "$JQ_MIDDLE3" "${OUTPUT_FREQS[$D]}" "$JQ_MIDDLE4")
		C=$((C + 1))
	done
	JQ_CMD+=$(printf '%s\n' "$JQ_END")

	FOUND_JSON=$(eval "$JQ_CMD")

	#mapfile -t NEARBY_CSV < <(jq -cr '.[] | [ .MAC, .password, .WPS, .signal, .frequency, .SSID ] | @csv' <<< "$FOUND_JSON")

	mapfile -t NEARBY_CSV < <(jq -cr '.[] | [ .MAC, .password, .WPS, .signal, .frequency, .SSID ] | @csv' <<< "$FOUND_JSON")

}

selection ()
{
	if [[ "$NEARBY_CSV" == "" ]]; then
		echo "No nearby networks found in DB"
		exit 1
	fi
	echo "Nearby networks in DB:"
	C=1
	printf '%-5s %-30s %-19s %-16s %-6s %-11s %-15s\n' "[#]" "ESSID" "BSSID" "PSK" "SIGNAL" "FREQUENCY" "WPS"


	for NEARBY_LINE in "${NEARBY_CSV[@]}";
	do
		mapfile -t -d "," NEARBY_ARRAY < <(echo $NEARBY_LINE | tr -d "\n")
		# Positions: 0=BSSID, 1=PSK, 2=WPS, 3=DB, 4=FREQ, 5=SSID
		if [[ "${NEARBY_ARRAY[4]:1:-1}" -gt 2495 ]]; then
			FREQ_HIGHLIGHT=${BLUE}
		else
			FREQ_HIGHLIGHT=""
		fi
		if [[ "${NEARBY_ARRAY[3]:1:-1}" -gt -75 ]]; then
			DB_HIGHLIGHT=${GREEN}
		else
			DB_HIGHLIGHT=""
		fi
		printf '%-5s %-30s %-19s %-16s'${DB_HIGHLIGHT}' %-6s'${NORMAL}${FREQ_HIGHLIGHT}' %-11s'"${NORMAL}${GREEN}"' %-15s'"${NORMAL}"'\n' "[$C]" "${NEARBY_ARRAY[5]:1:-1}" "${NEARBY_ARRAY[0]:1:-1}" "${NEARBY_ARRAY[1]:1:-1}" "${NEARBY_ARRAY[3]:1:-1}" "${NEARBY_ARRAY[4]:1:-1}" "${NEARBY_ARRAY[2]:1:-1}"
		C=$(( C + 1 ))
	done
	read -p "Select a network [1 - $(( C - 1 ))] " -r
	if [[ $REPLY == "" ]]; then
		JQ_CMD=""
		OUTPUT_MACS=""
		OUTPUT_FREQS=""
		OUTPUT_SIGNALS=""
		scan_loop
		get_nearby
		compare_nearby
		selection
	fi
	mapfile -t -d "," NEARBY_SELECTION < <(echo ${NEARBY_CSV[$(( REPLY - 1 ))]})
	SELECTION_ESSID="${NEARBY_SELECTION[5]:1:-2}"
	SELECTION_BSSID="${NEARBY_SELECTION[0]:1:-1}"
	SELECTION_PSK="${NEARBY_SELECTION[1]:1:-1}"
	SELECTION_DB="${NEARBY_SELECTION[3]:1:-1}"
	SELECTION_FREQ="${NEARBY_SELECTION[4]:1:-1}"
	SELECTION_WPS="${NEARBY_SELECTION[2]:1:-1}"
	printf 'Selected network details:\nESSID: %s\nBSSID: %s\nPSK: %s\nWPS Pin: %s' "$SELECTION_ESSID" "$SELECTION_BSSID" "$SELECTION_PSK" "$SELECTION_WPS"
	echo
}

connection()
{
	if (which NetworkManager > /dev/null); then
		echo "NetworkManager found"
		if (nmcli d | grep "$INTERFACE" | grep unmanaged > /dev/null); then
			printf 'Interface %s is unmanaged, using wpa_supplicant instead\n' "$INTERFACE"
		else
			echo "Connecting using NetworkManager"
			nmcli -a d wifi connect "$SELECTION_BSSID" password "$SELECTION_PSK" ifname "$INTERFACE"
		fi
	else
		if (which wpa_supplicant); then
			echo "NetworkManager not found, using wpa_supplicant"
			wpa_passphrase "$SELECTION_ESSID" "$SELECTION_PSK" > "$WPA_CONFIG"
			wpa_supplicant -Dnl80211 -i "$INTERFACE" -c "$WPA_CONFIG"
		fi
	fi
}

if test -f "$DBFILE"; then
perl -l -e 'print "Database was last modified ", -M $ARGV[0], " days ago"' "$DBFILE"
read -p "Do you want to update it? (Y/n) " -n 1 -r
echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		update_db
	else
		:
	fi
else
update_db
fi
scan_loop
get_nearby
compare_nearby
selection
connection
