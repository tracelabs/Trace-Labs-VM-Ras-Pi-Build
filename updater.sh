#!/bin/bash


# this script will pull the most recent repo for updating
# the repo includes a script that updates the system and tools
# as well as plugs in the most recent firefox bookmarks
cd /home/osint

if [ -d "/home/osint/Trace-Labs-VM-Ras-Pi-Updater" ]; then        
	
		cd /home/osint/Trace-Labs-VM-Ras-Pi-Updater
        	git pull https://github.com/humandecoded/Trace-Labs-VM-Ras-Pi-Updater.git
	else
		git clone https://github.com/humandecoded/Trace-Labs-VM-Ras-Pi-Updater.git
		cd /home/osint/Trace-Labs-VM-Ras-Pi-Updater
	fi
 chmod +x /home/osint/Trace-Labs-VM-Ras-Pi-Updater/update-system.sh
 sudo /home/osint/Trace-Labs-VM-Ras-Pi-Updater/update-system.sh
 #sudo cp distribution.ini /usr/share/firefox-esr/distribution/
 sudo rm -rf /home/osint/Trace-Labs-VM-Ras-Pi-Updater