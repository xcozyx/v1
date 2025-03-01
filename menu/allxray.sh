#!/bin/bash

show_allxray_menu() {
    clear
    echo -e "————————————————————————————"
    echo -e "---- [ All Xray Menu ] ----"
    echo -e "————————————————————————————"
    echo -e " [1] Create Xray"
    echo -e " [2] Extend Xray"
    echo -e " [3] Delete Xray"
    echo -e " [4] User Login"
    echo -e " [5] User List"
    echo -e " [6] BOT Notif"
    echo -e " [7] Warp Setting"
    echo -e " [8] User Traffic"
    echo -e " [0] Back To Menu"
    echo -e "————————————————————————————"
    echo -e ""
}

# Fungsi untuk menangani input menu
handle_allxray_menu() {
    read -p "[ root ] t.me/November2k~# "  opt
    echo -e ""
    case $opt in
        1) clear ; create-xray ;;
        2) clear ; extend-xray ;;
        3) clear ; del-xray ;;
        4) clear ; cek-xray ;;
        5) clear ; log-xray ;;
        6) clear ; bot-notif ;;
        7) clear ; route-xray ;;
        8) clear ; python /usr/bin/traffic.py ; echo " " ; read -n 1 -s -r -p "Press any key to back on menu" ; show_allxray_menu ;;
        0) clear ; menu ;;
        *) echo -e "Invalid input" ; sleep 1 ; show_allxray_menu ;;
    esac
}

# Tampilkan menu dan tangani input pengguna
while true; do
    show_allxray_menu
    handle_allxray_menu
done
