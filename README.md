# wifi-toolkit
Interactive toolkit for working with wpa-sec, Wigle.net and other tools

# Recon (recon.sh)

### Requirements:
* jq
* NetworkManager (for Linux only)
* nmap

#### On Termux without root (Android)
* Termux ([installed from F-Droid](https://f-droid.org/en/packages/com.termux/))
* Termux API ([installed from F-Droid](https://f-droid.org/en/packages/com.termux.api/))

After installing Termux API, go in the app properties, and allow all permissions. In Location, select "Always" instead of "Only when in use"

**These apps must be installed from F-Droid, not Google Play - [More info here](https://wiki.termux.com/wiki/Termux_Google_Play)**

### Usage
Simply run the `recon.sh` script with root permissions (not needed on Termux) - right now, it should work on Termux and on any Linux

The script will create a directory in your home directory named `nmap-scans` and will place all nmap scans in it. The nmap scans will be named like this: `ffffffffffff_YYYY-MM-DD.xml`, where *ffffffffffff* is the BSSID of the scanned network.

In Termux, you can also run the `termux-notif.sh` script to activate a notification in your taskbar that will show the info about current WiFi connection and a button to start the nmap scan (by running `recon.sh`) To close the notification, simply click the "Stop" button.

**NOTE:**
In Termux, you need to run the scripts with the `bash` command - eg. `bash recon.sh`

Also, the "Refresh" button in the notification sometimes doesn't work or takes very long to refresh. I'm not sure why is this happening, but I'm trying to fix it.