#!/bin/bash
clear

echo -e "[ INFO ] Start "
sleep 0.5
systemctl stop nginx
domain=$(cat /var/lib/dnsvps.conf | cut -d'=' -f2)
Cek=$(lsof -i:80 | cut -d' ' -f1 | awk 'NR==2 {print $1}')
if [[ ! -z "$Cek" ]]; then
sleep 1
echo -e "[ WARNING ] Detected port 80 used by $Cek "
systemctl stop $Cek
sleep 2
echo -e "[ INFO ] Processing to stop $Cek "
sleep 1
fi
echo -e "[ INFO ] Starting renew cert... "
sleep 2
export CF_Email="xcozystore@gmail.com"
export CF_Key="828af7595609da87cc0503e2233f5ebb23b97"
bash .acme.sh/acme.sh --issue --dns dns_cf -d $domain -d *.$domain --listen-v6 --server letsencrypt --keylength ec-256 --fullchain-file /usr/local/etc/xray/fullchain.cer --key-file /usr/local/etc/xray/private.key --reloadcmd "systemctl restart nginx" --force
chmod 745 /usr/local/etc/xray/private.key
echo -e "[ INFO ] Renew cert done... "
sleep 2
echo -e "[ INFO ] Starting service $Cek "
sleep 2
echo "$domain" > /usr/local/etc/xray/dns/domain
systemctl restart $Cek
systemctl restart nginx
echo -e "[ INFO ] All finished... "
sleep 0.5
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
