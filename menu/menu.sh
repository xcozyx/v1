#!/bin/bash
colornow=$(cat /etc/rmbl/theme/color.conf)
export NC="\e[0m"
export yl='\033[0;33m';
export RED="\033[0;31m"
export COLOR1="$(cat /etc/rmbl/theme/$colornow | grep -w "TEXT" | cut -d: -f2|sed 's/ //g')"
export COLBG1="$(cat /etc/rmbl/theme/$colornow | grep -w "BG" | cut -d: -f2|sed 's/ //g')"
WH='\033[1;37m'
DAY=$(date +%A)
DATE=$(date +%m/%d/%Y)
DATE2=$(date -R | cut -d " " -f -5)
MYIP=$(wget -qO- ifconfig.me/ip)
tram=$( free -h | awk 'NR==2 {print $2}' )
uram=$( free -h | awk 'NR==2 {print $3}' )
ISP=$(curl -s ipinfo.io/org | cut -d " " -f 2-10 )
CITY=$(curl -s ipinfo.io/city )
author=$(cat /etc/profil)

MODEL2=$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')
LOADCPU=$(printf '%-0.00001s' "$(top -bn1 | awk '/Cpu/ { cpu = "" 100 - $8 "%" }; END { print cpu }')")
CORE=$(printf '%-1s' "$(grep -c cpu[0-9] /proc/stat)")
cpu_usage1="$(ps aux | awk 'BEGIN {sum=0} {sum+=$3}; END {print sum}')"
cpu_usage="$((${cpu_usage1/\.*} / ${corediilik:-1}))"
cpu_usage+=" %"
vnstat_profile=$(vnstat | sed -n '3p' | awk '{print $1}' | grep -o '[^:]*')
vnstat -i ${vnstat_profile} >/etc/t1
bulan=$(date +%b)
tahun=$(date +%y)
ba=$(curl -s https://pastebin.com/raw/0gWiX6hE)
today=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $8}')
todayd=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $8}')
today_v=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $9}')
today_rx=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $2}')
today_rxv=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $3}')
today_tx=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $5}')
today_txv=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $6}')
if [ "$(grep -wc ${bulan} /etc/t1)" != '0' ]; then
bulan=$(date +%b)
month=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $9}')
month_v=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $10}')
month_rx=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $3}')
month_rxv=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $4}')
month_tx=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $6}')
month_txv=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $7}')
else
bulan2=$(date +%Y-%m)
month=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $8}')
month_v=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $9}')
month_rx=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $2}')
month_rxv=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $3}')
month_tx=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $5}')
month_txv=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $6}')
fi
if [ "$(grep -wc yesterday /etc/t1)" != '0' ]; then
yesterday=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $8}')
yesterday_v=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $9}')
yesterday_rx=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $2}')
yesterday_rxv=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $3}')
yesterday_tx=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $5}')
yesterday_txv=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $6}')
else
yesterday=NULL
yesterday_v=NULL
yesterday_rx=NULL
yesterday_rxv=NULL
yesterday_tx=NULL
yesterday_txv=NULL
fi
nginx=$( systemctl status nginx | grep Active | awk '{print $3}' | sed 's/(//g' | sed 's/)//g' )
if [[ $nginx == "running" ]]; then
status_nginx="${COLOR1}ON${NC}"
else
status_nginx="${RED}OFF${NC}"
systemctl start nginx
fi
if [[ -e /usr/bin/kyt ]]; then
nginx=$( systemctl status kyt | grep Active | awk '{print $3}' | sed 's/(//g' | sed 's/)//g' )
if [[ $nginx == "running" ]]; then
echo -ne
else
systemctl start kyt
fi
fi
rm -rf /etc/status
xray=$(systemctl status xray | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
if [[ $xray == "running" ]]; then
status_xray="${COLOR1}ON${NC}"
else
status_xray="${RED}OFF${NC}"
fi
# TOTAL CREATE ACC VMESS
vmess=$(grep -c -E "^#&@ " "/usr/local/etc/xray/config/04_inbounds.json")
uphours=`uptime -p | awk '{print $2,$3}' | cut -d , -f1`
upminutes=`uptime -p | awk '{print $4,$5}' | cut -d , -f1`
uptimecek=`uptime -p | awk '{print $6,$7}' | cut -d , -f1`
cekup=`uptime -p | grep -ow "day"`

show_menu() {
    clear
echo -e "$COLOR1┌───────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1 ${NC} ${COLBG1}               ${WH}• XCOZY PROJECT •              ${NC} $COLOR1 $NC"
echo -e "$COLOR1└───────────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌───────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1│$NC${WH} ❄️ OS            ${COLOR1}: ${WH}$MODEL2${NC}"
echo -e "$COLOR1│$NC${WH} ❄️ RAM           ${COLOR1}: ${WH}$tram / $uram MB${NC}"
echo -e "$COLOR1│$NC${WH} ❄️ DATE          ${COLOR1}: ${WH}$DATE2 WIB${NC}"
echo -e "$COLOR1│$NC${WH} ❄️ UPTIME        ${COLOR1}: ${WH}$uphours $upminutes $uptimecek"
#echo -e " $COLOR1│$NC${WH} ❄️ TIME          ${COLOR1}: ${WH}$TIMEZONE${NC}"
echo -e "$COLOR1│$NC${WH} ❄️ ISP           ${COLOR1}: ${WH}$ISP${NC}"
echo -e "$COLOR1│$NC${WH} ❄️ City          ${COLOR1}: ${WH}$CITY${NC}"
echo -e "$COLOR1│$NC${WH} ❄️ IP VPS        ${COLOR1}: ${WH}$MYIP${NC}"
#echo -e "$COLOR1│$NC${WH} ❄️ DOMAIN        ${COLOR1}: ${WH}$(cat /etc/xray/domain)"
#echo -e "$COLOR1│$NC${WH} ❄️ NSDomain      ${COLOR1}: ${WH}$(cat /etc/xray/dns)"
echo -e "$COLOR1└───────────────────────────────────────────────────┘${NC}"
#echo -e "$COLOR1┌─────────────────────────────────────────────────┐${NC}"
#echo -e "$COLOR1 $NC ${WH}[ NGINX    : ${status_ws} ${WH}]  ${WH}[ XRAY : ${status_xray} ${WH}]$NC"
#echo -e "$COLOR1 $NC ${WH}[ DROPBEAR : ${status_beruangjatuh} ${WH}]  ${WH}[ UDPC : ${status_udp} ${WH}]$NC"
#echo -e "$COLOR1└─────────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌───────────────────────────────────────────────────┐${NC}"
echo -e "$COLOR1 $NC ${WH}[ NGINX : ${status_nginx} ${WH}] ${WH}[ XRAY : ${status_xray} ${WH}]${WH}[ AKUN AKTIF : ${COLOR1}${vmess} ]$NC"
#echo -e "$COLOR1 $NC ${WH}[ DROPBEAR : ${status_beruangjatuh} ${WH}] ${WH}[ UDPC : ${status_udp} ${WH}]${WH} USAGE RAM : ${uram} $NC"
echo -e "$COLOR1└───────────────────────────────────────────────────┘${NC}"
#echo -e "$COLOR1┌───────────────────────────────────────────────────┐${NC}"
#printf "            \033[1;37m%-16s ${COLOR1}%-4s${NC} ${WH}%-5s\e[0m\n" " VMESS/WS    =" "$vmess" "ACCOUNT "
#printf "            \033[1;37m%-16s ${COLOR1}%-4s${NC} ${WH}%-5s\e[0m\n" " VLESS/WS    =" "$vless" "ACCOUNT "
#printf "            \033[1;37m%-16s ${COLOR1}%-4s${NC} ${WH}%-5s\e[0m\n" " TROJAN/GRPC =" "$trtls" "ACCOUNT "
#echo -e "$COLOR1└───────────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌───────────────────────────────────────────────────┐${NC}"
echo -e " $COLOR1 ${COLOR1}Traffic${NC}      ${COLOR1}Today       Yesterday       Month   ${NC}"
echo -e " $COLOR1 ${WH}Download${NC}   ${WH}$today_tx $today_txv     $yesterday_tx $yesterday_txv    $month_tx $month_txv   ${NC}"
echo -e " $COLOR1 ${WH}Upload${NC}     ${WH}$today_rx $today_rxv     $yesterday_rx $yesterday_rxv    $month_rx $month_rxv   ${NC}"
echo -e " $COLOR1 ${COLOR1}Total${NC}    ${COLOR1}  $todayd $today_v     $yesterday $yesterday_v    $month $month_v  ${NC} "
echo -e "$COLOR1└───────────────────────────────────────────────────┘${NC}"
echo -e "$COLOR1┌───────────────────────────────────────────────────┐${NC}"
echo -e "  ${WH}[${COLOR1}1${WH}]${NC} ${COLOR1}• ${WH}XRAY MENU   ${WH}[${COLOR1}${status_xray}${WH}]   ${WH}[${COLOR1}4${WH}]${NC} ${COLOR1}• ${WH}UPDATE CORE ${WH}[${COLOR1}Menu${WH}]  $COLOR1 $NC"   
echo -e "  ${WH}[${COLOR1}2${WH}]${NC} ${COLOR1}• ${WH}DOMAIN    ${WH}[${COLOR1}${status_xray}${WH}]   ${WH}[${COLOR1}5${WH}]${NC} ${COLOR1}• ${WH}INFO SCRIPT ${WH}[${COLOR1}Menu${WH}]  $COLOR1 $NC"  
echo -e "  ${WH}[${COLOR1}3${WH}]${NC} ${COLOR1}• ${WH}SPEEDTEST    ${WH}[${COLOR1}${status_xray}${WH}]   ${WH}[${COLOR1}6${WH}]${NC} ${COLOR1}• ${WH}UPDATE SCRIPT${WH}[${COLOR1}Menu${WH}]  $COLOR1 $NC"  
#echo -e "  ${WH}[${COLOR1}04${WH}]${NC} ${COLOR1}• ${WH}TROJAN   ${WH}[${COLOR1}${status_xray}${WH}]   ${WH}[${COLOR1}12${WH}]${NC} ${COLOR1}• ${WH}SYSTEM    ${WH}[${COLOR1}Menu${WH}]  $COLOR1 $NC"  
#echo -e "  ${WH}[${COLOR1}05${WH}]${NC} ${COLOR1}• ${WH}NOOBZ    ${WH}[${COLOR1}${stat_noobz}${WH}]   ${WH}[${COLOR1}13${WH}]${NC} ${COLOR1}• ${WH}BACKUP    ${WH}[${COLOR1}Menu${WH}]  $COLOR1 $NC"
#echo -e "  ${WH}[${COLOR1}06${WH}]${NC} ${COLOR1}• ${WH}TRJN-GO  ${WH}[${COLOR1}${status_xray}${WH}]   ${WH}[${COLOR1}14${WH}]${NC} ${COLOR1}• ${WH}RESTART   ${WH}[${COLOR1}Menu${WH}]  $COLOR1 $NC"
#echo -e "  ${WH}[${COLOR1}07${WH}]${NC} ${COLOR1}• ${WH}RUNNING  ${WH}[${COLOR1}${status_xray}${WH}]   ${WH}[${COLOR1}15${WH}]${NC} ${COLOR1}• ${WH}REBOOT    ${WH}[${COLOR1}Menu${WH}]  $COLOR1 $NC"
#echo -e "  ${WH}[${COLOR1}08${WH}]${NC} ${COLOR1}• ${WH}CEK Net  ${WH}[${COLOR1}${status_xray}${WH}]   ${WH}[${COLOR1}16${WH}]${NC} ${COLOR1}• ${WH}PASSWORD  ${WH}[${COLOR1}Menu${WH}]  $COLOR1 $NC"
echo -e "$COLOR1└───────────────────────────────────────────────────┘${NC}"
    python /usr/bin/system_info.py
    printf " [1] Xray Menu              [4] Update Core\n"
    printf " [2] Domain Setup           [5] Info Script\n"
    printf " [3] Speedtest              [6] Update Script\n"
    printf "+-------------------------------------------------------+"
    echo -e ""
}

# Fungsi untuk menangani input menu
handle_menu() {
    read -p "[ root ] t.me/November2k~# " opt
    printf "+-------------------------------------------------------+"
    echo -e ""
    case $opt in
        1) clear ; allxray ;;
        2) clear ; dns ;;
        3) clear ; speedtest ; echo " " ; read -n 1 -s -r -p "Press any key to back on menu" ; show_menu ;;
        4) clear ; update-xray ;;
        5) clear ; about ;;
        6) clear ; update-menu ;;
        *) echo -e "Invalid input" ; sleep 1 ; show_menu ;;
    esac
}

# Tampilkan menu dan tangani input pengguna
while true; do
    show_menu
    handle_menu
done
