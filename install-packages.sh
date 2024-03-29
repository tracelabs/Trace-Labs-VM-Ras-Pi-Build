#!/bin/bash


# move bin files over and make executable
chmod +x /opt/bin/*
mv /opt/bin/* /usr/bin/
rm -rf /opt/bin

packages="git
golang
python3
python3-pip
python3-dev
python3-pandas
build-essential
curl
build-essential
libsqlite3-dev
libseccomp-dev
libsodium-dev
publicsuffix
cargo
pkg-config
rubygems 
libtool
libssl-doc
libc6-dev
libseccomp2
libsqlite3-0
sqlite3-doc
ruby-dev
libpq-dev
nodejs
npm
spiderfoot
sherlock
maltego
python3-shodan
theharvester
webhttrack
outguess
stegosuite
openvpn
metagoofil
exifprobe
ruby-bundler
recon-ng
cherrytree
instaloader
photon
sublist3r
osrframework
drawing
finalrecon
chromium
"

apt install -y $packages



pip3 install --upgrade virtualenv
pip3 install --upgrade tweepy 
pip3 install --upgrade youtube-dl
pip3 install --upgrade requests
pip3 install --upgrade fake_useragent
pip3 install --upgrade dnsdumpster
pip3 install --upgrade simplejson
pip3 install --upgrade cfscrape
pip3 install --upgrade python-docx
pip3 install --upgrade urllib3
pip3 install --upgrade bs4
pip3 install --upgrade lxml
pip3 install --upgrade ipdb
pip3 install --upgrade click
pip3 install --upgrade numpy
pip3 install --upgrade tqdm
pip3 install --upgrade googletransx
pip3 install --upgrade schedule
pip3 install --upgrade aiohttp
pip3 install --upgrade aiohttp_socks
pip3 install --upgrade cchardet
pip3 install --upgrade elasticsearch
pip3 install --upgrade geopy
pip3 install --upgrade h8mail
pip3 install --upgrade instaloader


git clone --recursive https://github.com/twintproject/twint.git /usr/share/Twint
cd /usr/share/Twint
python3 setup.py install

git clone --recursive https://github.com/hatlord/Spiderpig.git /usr/share/Spiderpig
cd /usr/share/Spiderpig
bundle install
#chmod +x /usr/bin/spiderpig

git clone --recursive https://github.com/securing/DumpsterDiver.git /usr/share/DumpsterDiver
cd /usr/share/DumpsterDiver
pip3 install -r requirements.txt
#dumpsterdiver writes error log to home folder
chmod 757 /usr/share/DumpsterDiver
#chmod +x /usr/bin/dumpsterdiver

git clone --recursive https://github.com/m4ll0k/Infoga.git /usr/share/Infoga
cd /usr/share/Infoga
python3 setup.py install
#chmod +x /usr/bin/infoga

git clone --recursive https://github.com/Lulz3xploit/LittleBrother /usr/share/LittleBrother
cd /usr/share/LittleBrother
pip3 install -r requirements.txt
#chmod +x /usr/bin/littlebrother


git clone --recursive https://github.com/bhavsec/reconspider /usr/share/reconspider
cd /usr/share/reconspider
python3 setup.py install
#chmod +x /usr/bin/reconspider


git clone --recursive https://github.com/WebBreacher/WhatsMyName.git /usr/share/WhatsMyName
cd /usr/share/WhatsMyName
pip3 install -r requirements.txt
#chmod +x /usr/bin/whatsmyname

git clone --recursive https://github.com/jocephus/WikiLeaker.git /usr/share/WikiLeaker
cd /usr/share/WikiLeaker 
pip3 install -r requirements.txt
#chmod +x /usr/bin/wikileaker

npm i -g tiktok-scraper

git clone --recursive https://github.com/megadose/OnionSearch.git /usr/share/OnionSearch
cd /usr/share/OnionSearch
python3 setup.py install
chmod +x /usr/share/updater/updater.sh
chmod +x /home/osint/Desktop/Updater.desktop

git clone https://github.com/megadose/toutatis.git /usr/share/toutatis
cd /usr/share/toutatis
python3 setup.py install
