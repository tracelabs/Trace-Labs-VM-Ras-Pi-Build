#!/bin/bash


# this script will pull the most recent repo for updating
# the repo includes a script that updates the system and tools
# as well as plugs in the most recent firefox bookmarks
cd /home/osint

if [ -d "/home/osint/Trace-Labs-VM-Ras-Pi-Updater" ]; then        
	
		cd /home/osint/Trace-Labs-VM-Ras-Pi-Updater
        	sudo git pull https://github.com/humandecoded/Trace-Labs-VM-Ras-Pi-Updater.git --rebase
	else
		sudo git clone https://github.com/humandecoded/Trace-Labs-VM-Ras-Pi-Updater.git
		cd Trace-Labs-VM-Ras-Pi-Updater
	fi
 chmod +x updater.sh
 sudo ./updater.sh
 sudo cp distribution.ini /usr/share/firefox-esr/distribution/   