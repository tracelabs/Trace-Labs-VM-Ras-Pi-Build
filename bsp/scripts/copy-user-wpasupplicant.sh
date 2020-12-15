#!/bin/bash -e

if [ -f /boot/wpa_supplicant.conf ]; then
  get_ssid=$(grep ssid /boot/wpa_supplicant.conf | tr -d '"')
  export $get_ssid
  get_psk=$(grep psk /boot/wpa_supplicant.conf | tr -d '#,"' | head -1)
  export $get_psk
  wifi_dev="wlan0"
  if [ ! -z "$ssid" ] && [ ! -z "$psk" ] && [ ! "${#psk}" -lt "8" ]; then
    if [ -x "$(command -v nmcli)" ]; then
      nmcli con add con-name "$ssid" type wifi ifname "$wifi_dev" \
        ssid "$ssid" -- wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$psk" \
        ipv4.method auto
    else
      install -m600 /boot/wpa_supplicant.conf /etc/wpa_supplicant
    fi
  fi
  rm -f /boot/wpa_supplicant.conf
fi
