# wifi-toolkit
Interactive toolkit for working with wpa-sec, Wigle.net and other tools

## Requirements:
* jq
* NetworkManager (for Linux only)

### On Termux without root (Android)
* Termux ([installed from F-Droid](https://f-droid.org/en/packages/com.termux/))
* Termux API ([installed from F-Droid](https://f-droid.org/en/packages/com.termux.api/))

**These apps must be installed from F-Droid, not Google Play - [More info here](https://wiki.termux.com/wiki/Termux_Google_Play)**

## Usage
Simply run the `recon.sh` script with root permissions (not needed on Termux) - right now, it should work on Termux and on any Linux

In Termux, you can also run the `termux-notif.sh` script to activate a notification in your taskbar that will show the info about current WiFi connection and a button to start the nmap scan (by running `recon.sh`)

**NOTE:**
In Termux, you need to run the scripts with the `bash` command - eg. `bash recon.sh`