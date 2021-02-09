#!/bin/bash

#this is a test comment
# this script will pull the most recent repo for updating
# the repo includes a script that updates the system and tools
# as well as plugs in the most recent firefox bookmarks
cd /home/osint

#if [ -d "/home/osint/Trace-Labs-VM-Ras-Pi-Updater" ]; then        
	
#		cd /home/osint/Trace-Labs-VM-Ras-Pi-Updater
 #       	git pull https://github.com/tracelabs/Trace-Labs-VM-Ras-Pi-Updater.git
#	else
#		git clone https://github.com/tracelabs/Trace-Labs-VM-Ras-Pi-Updater.git
#		cd /home/osint/Trace-Labs-VM-Ras-Pi-Updater
#	fi
 
 wget -O update-system.sh https://raw.githubusercontent.com/tracelabs/Trace-Labs-VM-Ras-Pi-Updater/main/update-system.sh
 chmod +x /home/osint/update-system.sh
 sudo /home/osint/update-system.sh
 #sudo cp distribution.ini /usr/share/firefox-esr/distribution/
 #sudo mv "osint bookmarks.html" ~/Desktop
 wget -O osint-bookmarks.html https://raw.githubusercontent.com/tracelabs/Trace-Labs-VM-Ras-Pi-Updater/main/osint%20bookmarks.html 
 sudo rm -rf /home/osint/update-system.sh