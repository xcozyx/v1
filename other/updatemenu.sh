#!/bin/bash

cd /usr/bin
GITHUB=raw.githubusercontent.com/xcozyx/v1/main
echo -e "[ INFO ] Mengunduh Update..."
wget -q -O menu "https://${GITHUB}/menu/menu.sh"
wget -q -O allxray "https://${GITHUB}/menu/allxray.sh"
wget -q -O del-xray "https://${GITHUB}/xray/del-xray.sh"
wget -q -O extend-xray "https://${GITHUB}/xray/extend-xray.sh"
wget -q -O create-xray "https://${GITHUB}/xray/create-xray.sh"
wget -q -O cek-xray "https://${GITHUB}/xray/cek-xray.sh"
wget -q -O route-xray "https://${GITHUB}/xray/route-xray.sh"
wget -q -O system_info.py "https://${GITHUB}/system_info.py"
wget -q -O traffic.py "https://${GITHUB}/traffic.py"
wget -q -O xp "https://${GITHUB}/other/xp.sh"
wget -q -O dns "https://${GITHUB}/other/dns.sh"
wget -q -O certxray "https://${GITHUB}/other/certxray.sh"
wget -q -O about "https://${GITHUB}/other/about.sh"
wget -q -O clear-log "https://${GITHUB}/other/clear-log.sh"
wget -q -O log-xray "https://${GITHUB}/other/log-xray.sh"
wget -q -O update-xray "https://${GITHUB}/other/update-xray.sh"
wget -q -O update-menu "https://${GITHUB}/other/updatemenu.sh"
wget -q -O bot-notif "https://${GITHUB}/other/bot-notif.sh"
echo -e "[ INFO ] Memberikan izin eksekusi pada skrip..."
chmod +x bot-notif update-menu del-xray extend-xray create-xray cek-xray log-xray menu allxray xp dns certxray about clear-log update-xray route-xray
echo -e "[ INFO ] Update Selesai."
sleep 3
cd
clear
menu