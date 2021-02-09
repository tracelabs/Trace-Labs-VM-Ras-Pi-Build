#!/bin/bash


# this script will pull the most recent repo for updating
# the repo includes a script that updates the system and tools
# as well as plugs in the most recent firefox bookmarks
cd /home/osint

wget -O updater-current.sh https://raw.githubusercontent.com/tracelabs/trace-labs-vm-ras-pi-build/humandecoded/updater-current.sh

sudo /home/osint/updater-current.sh

sudo rm -f updater-current.sh

wget -O bookmarks.html https://raw.githubusercontent.com/tracelabs/trace-labs-vm-ras-pi-build/humandecoded/bookmarks.html
