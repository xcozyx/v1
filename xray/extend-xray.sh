#!/bin/bash

clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#&@ " "/usr/local/etc/xray/config/04_inbounds.json")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
echo -e "————————————————————————"
echo -e "Extend All Xray Account              "
echo -e "————————————————————————"
echo -e "  You have no existing clients!"
echo -e "————————————————————————"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
allxray
fi
clear
echo -e "————————————————————————"
echo -e "Extend All Xray Account              "
echo -e "————————————————————————"
echo -e " User  Expired  "
echo -e "————————————————————————"
grep -E "^#&@ " "/usr/local/etc/xray/config/04_inbounds.json" | cut -d ' ' -f 2-3 | column -t | sort | uniq
echo ""
echo -e "tap enter to go back"
echo -e "————————————————————————"
read -rp "Input Username : " user
if [ -z $user ]; then
allxray
else
read -p "Expired (days): " masaaktif
exp=$(grep -wE "^#&@ $user" "/usr/local/etc/xray/config/04_inbounds.json" | cut -d ' ' -f 3 | sort | uniq)
now=$(date +%Y-%m-%d)
d1=$(date -d "$exp" +%s)
d2=$(date -d "$now" +%s)
exp2=$(( (d1 - d2) / 86400 ))
exp3=$(($exp2 + $masaaktif))
exp4=`date -d "$exp3 days" +"%Y-%m-%d"`
sed -i "/#&@ $user/c\#&@ $user $exp4" /usr/local/etc/xray/config/04_inbounds.json
systemctl restart xray
clear
echo -e "————————————————————————"
echo -e "All Xray Account Success Extended         "
echo -e "————————————————————————"
echo -e " Client Name : $user"
echo -e " Expired On  : $exp4"
echo -e "————————————————————————"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
clear
allxray
fi
